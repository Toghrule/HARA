using FluentValidation;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Members;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.PasswordResets;

/// <summary>The owners' password reset requests, newest first, for the admin to decide.</summary>
/// <param name="Status">Only requests in this (effective) state; all of them when <c>null</c>.</param>
public sealed record GetPasswordResetRequestsQuery(PasswordResetStatus? Status) : IRequest<IReadOnlyList<PasswordResetRequestDto>>;

/// <summary>The admin approves or declines a waiting request, after checking by phone that it is the owner.</summary>
public sealed record DecidePasswordResetCommand(Guid Id, bool Approve) : IRequest<PasswordResetRequestDto>;

/// <summary>A request as the admin sees it: who is asking, so they can be called and recognised.</summary>
public sealed record PasswordResetRequestDto(
    Guid Id,
    string Email,
    string? OwnerName,
    string? PhoneNumber,
    string? RestaurantName,
    DateTimeOffset CreatedAt,
    PasswordResetStatus Status,
    DateTimeOffset? DecidedAt,
    DateTimeOffset? ExpiresAt);

public class DecidePasswordResetCommandValidator : AbstractValidator<DecidePasswordResetCommand>
{
    public DecidePasswordResetCommandValidator()
    {
        RuleFor(c => c.Id).NotEmpty();
    }
}

internal static class PasswordResetDtos
{
    /// <summary>Adds who each owner is (name, phone, restaurant) from their membership, or from their registration if the restaurant is not created yet.</summary>
    public static async Task<List<PasswordResetRequestDto>> BuildAsync(
        IUnitOfWork unitOfWork,
        IReadOnlyList<PasswordResetRequest> requests,
        DateTimeOffset now,
        CancellationToken cancellationToken)
    {
        var userIds = requests.Select(r => r.UserId).Distinct().ToList();

        var members = await unitOfWork.Repository<RestaurantMember>().Query()
            .Include(m => m.Restaurant)
            .Where(m => userIds.Contains(m.UserId))
            .ToListAsync(cancellationToken);
        var registrations = await unitOfWork.Repository<RestaurantSubmission>().Query()
            .Where(s => s.OwnerUserId != null && userIds.Contains(s.OwnerUserId.Value))
            .ToListAsync(cancellationToken);

        return requests.Select(request =>
        {
            var member = members.FirstOrDefault(m => m.UserId == request.UserId);
            var registration = registrations.Where(s => s.OwnerUserId == request.UserId).OrderByDescending(s => s.CreatedAt).FirstOrDefault();

            return new PasswordResetRequestDto(
                request.Id,
                request.Email,
                member?.FullName ?? registration?.SubmitterName,
                member?.PhoneNumber ?? registration?.SubmitterPhoneNumber,
                member?.Restaurant?.Name ?? registration?.RestaurantName,
                request.CreatedAt,
                request.EffectiveStatus(now),
                request.DecidedAt,
                request.ExpiresAt);
        }).ToList();
    }
}

public class GetPasswordResetRequestsQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetPasswordResetRequestsQuery, IReadOnlyList<PasswordResetRequestDto>>
{
    private const int MaxResults = 200;

    public async Task<IReadOnlyList<PasswordResetRequestDto>> Handle(GetPasswordResetRequestsQuery request, CancellationToken cancellationToken)
    {
        var now = DateTimeOffset.UtcNow;
        var query = unitOfWork.Repository<PasswordResetRequest>().Query();

        // "Expired" is not stored: an approved request whose time ran out.
        query = request.Status switch
        {
            PasswordResetStatus.Approved => query.Where(r => r.Status == PasswordResetStatus.Approved && r.ExpiresAt > now),
            PasswordResetStatus.Expired => query.Where(r => r.Status == PasswordResetStatus.Approved && r.ExpiresAt <= now),
            { } status => query.Where(r => r.Status == status),
            _ => query
        };

        var requests = await query.OrderByDescending(r => r.CreatedAt).Take(MaxResults).ToListAsync(cancellationToken);

        return await PasswordResetDtos.BuildAsync(unitOfWork, requests, now, cancellationToken);
    }
}

public class DecidePasswordResetCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<DecidePasswordResetCommand, PasswordResetRequestDto>
{
    public async Task<PasswordResetRequestDto> Handle(DecidePasswordResetCommand request, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<PasswordResetRequest>();
        var stored = await repository.GetByIdAsync(request.Id, cancellationToken)
            ?? throw new Common.Exceptions.NotFoundException(nameof(PasswordResetRequest), request.Id);

        if (stored.Status != PasswordResetStatus.Pending)
        {
            throw new Common.Exceptions.ValidationException("status", "This request has already been decided.");
        }

        var now = DateTimeOffset.UtcNow;
        stored.Status = request.Approve ? PasswordResetStatus.Approved : PasswordResetStatus.Rejected;
        stored.DecidedAt = now;
        stored.ExpiresAt = request.Approve ? now.AddMinutes(PasswordResetRequest.ApprovedForMinutes) : null;

        repository.Update(stored);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return (await PasswordResetDtos.BuildAsync(unitOfWork, [stored], now, cancellationToken)).Single();
    }
}
