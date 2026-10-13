using FluentValidation;
using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Application.Notifications;
using Hara.Application.Venue;
using Hara.Domain.Devices;
using Hara.Domain.Reservations;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Devices;

/// <summary>The signed-in restaurant person's phone asks to be told about new requests.</summary>
public sealed record RegisterVenueDeviceCommand(string Token, string? Language) : IRequest<Unit>;

/// <summary>The signed-in person's phone no longer wants those notifications (they signed out).</summary>
public sealed record UnregisterVenueDeviceCommand(string Token) : IRequest<Unit>;

/// <summary>A customer's phone asks to be told the restaurant's answer to the request with this code.</summary>
public sealed record RegisterReservationDeviceCommand(string Code, string Token, string? Language) : IRequest<Unit>;

public class RegisterVenueDeviceCommandValidator : AbstractValidator<RegisterVenueDeviceCommand>
{
    public RegisterVenueDeviceCommandValidator()
    {
        RuleFor(c => c.Token).NotEmpty().MaximumLength(4096);
        RuleFor(c => c.Language).MaximumLength(10);
    }
}

public class UnregisterVenueDeviceCommandValidator : AbstractValidator<UnregisterVenueDeviceCommand>
{
    public UnregisterVenueDeviceCommandValidator()
    {
        RuleFor(c => c.Token).NotEmpty().MaximumLength(4096);
    }
}

public class RegisterReservationDeviceCommandValidator : AbstractValidator<RegisterReservationDeviceCommand>
{
    public RegisterReservationDeviceCommandValidator()
    {
        RuleFor(c => c.Code).NotEmpty().MaximumLength(16);
        RuleFor(c => c.Token).NotEmpty().MaximumLength(4096);
        RuleFor(c => c.Language).MaximumLength(10);
    }
}

public class RegisterVenueDeviceCommandHandler(VenueAccess access, IUnitOfWork unitOfWork, ICurrentUserService currentUser)
    : IRequestHandler<RegisterVenueDeviceCommand, Unit>
{
    public async Task<Unit> Handle(RegisterVenueDeviceCommand request, CancellationToken cancellationToken)
    {
        await access.RequireApprovedMemberAsync(cancellationToken);
        var userId = currentUser.UserId!.Value;
        var repository = unitOfWork.Repository<DeviceToken>();

        var rows = await repository.Query()
            .Where(t => t.Token == request.Token && t.UserId != null)
            .ToListAsync(cancellationToken);

        // A phone belongs to whoever signed in last; the person before must stop getting this phone's notifications.
        foreach (var other in rows.Where(t => t.UserId != userId))
        {
            repository.Remove(other);
        }

        var mine = rows.FirstOrDefault(t => t.UserId == userId);
        if (mine is null)
        {
            await repository.AddAsync(new DeviceToken { Token = request.Token, UserId = userId, Language = PushTexts.Normalize(request.Language) }, cancellationToken);
        }
        else
        {
            mine.Language = PushTexts.Normalize(request.Language);
            repository.Update(mine);
        }

        await unitOfWork.SaveChangesAsync(cancellationToken);

        return Unit.Value;
    }
}

public class UnregisterVenueDeviceCommandHandler(IUnitOfWork unitOfWork, ICurrentUserService currentUser)
    : IRequestHandler<UnregisterVenueDeviceCommand, Unit>
{
    public async Task<Unit> Handle(UnregisterVenueDeviceCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUser.UserId;
        var repository = unitOfWork.Repository<DeviceToken>();

        var rows = await repository.Query()
            .Where(t => t.Token == request.Token && t.UserId == userId)
            .ToListAsync(cancellationToken);

        foreach (var row in rows)
        {
            repository.Remove(row);
        }

        await unitOfWork.SaveChangesAsync(cancellationToken);

        return Unit.Value;
    }
}

public class RegisterReservationDeviceCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<RegisterReservationDeviceCommand, Unit>
{
    /// <summary>Customer tokens are only useful while their request is going; older rows are cleared out.</summary>
    private static readonly TimeSpan KeepAfterEnd = TimeSpan.FromDays(1);

    public async Task<Unit> Handle(RegisterReservationDeviceCommand request, CancellationToken cancellationToken)
    {
        var code = request.Code.Trim().ToUpperInvariant();
        var now = DateTimeOffset.UtcNow;
        var reservation = await unitOfWork.Repository<Reservation>().Query()
            .FirstOrDefaultAsync(r => r.Code == code, cancellationToken)
            ?? throw new NotFoundException(nameof(Reservation), code);

        var repository = unitOfWork.Repository<DeviceToken>();

        // Housekeeping on the way through: forget tokens of requests that ended long ago.
        var cutoff = now - KeepAfterEnd;
        var stale = await repository.Query()
            .Where(t => t.ReservationId != null && t.Reservation!.ExpiresAt < cutoff)
            .ToListAsync(cancellationToken);
        foreach (var row in stale)
        {
            repository.Remove(row);
        }

        // Only a request that is still going has an answer to wait for.
        if (reservation.IsInProgress(now))
        {
            var existing = await repository.Query()
                .FirstOrDefaultAsync(t => t.Token == request.Token && t.ReservationId == reservation.Id, cancellationToken);

            if (existing is null)
            {
                await repository.AddAsync(
                    new DeviceToken { Token = request.Token, ReservationId = reservation.Id, Language = PushTexts.Normalize(request.Language) },
                    cancellationToken);
            }
            else
            {
                existing.Language = PushTexts.Normalize(request.Language);
                repository.Update(existing);
            }
        }

        await unitOfWork.SaveChangesAsync(cancellationToken);

        return Unit.Value;
    }
}
