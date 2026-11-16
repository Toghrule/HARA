using System.Text.RegularExpressions;
using FluentValidation;
using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Application.Reservations;
using Hara.Application.Statistics;
using Hara.Domain.Discounts;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;
using ValidationException = Hara.Application.Common.Exceptions.ValidationException;

namespace Hara.Application.Discounts;

/// <summary>The device number the app makes: letters, digits and dashes, long enough not to be guessed.</summary>
internal static class DeviceIds
{
    public static readonly Regex Pattern = new("^[A-Za-z0-9-]{8,64}$", RegexOptions.Compiled);
}

/// <summary>
/// Public command: the customer taps "get the discount" at a restaurant that gives one. They get a code valid for 6 hours. A device
/// gets one code per restaurant per day: asking again the same day returns that same code, in whatever state it is now (still
/// valid, used, or run out; a run-out code is not replaced until the next day).
/// </summary>
public sealed record GetDiscountCodeCommand(Guid RestaurantId, string DeviceId) : IRequest<DiscountCodeDto>;

public class GetDiscountCodeCommandValidator : AbstractValidator<GetDiscountCodeCommand>
{
    public GetDiscountCodeCommandValidator()
    {
        RuleFor(c => c.RestaurantId).NotEmpty();
        RuleFor(c => c.DeviceId).NotEmpty().Matches(DeviceIds.Pattern).WithMessage("The device number is not valid.");
    }
}

public class GetDiscountCodeCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetDiscountCodeCommand, DiscountCodeDto>
{
    private const int MaxCodeAttempts = 5;

    public async Task<DiscountCodeDto> Handle(GetDiscountCodeCommand request, CancellationToken cancellationToken)
    {
        var restaurant = await unitOfWork.Repository<Restaurant>().GetByIdAsync(request.RestaurantId, cancellationToken);
        if (restaurant is null || !restaurant.IsActive)
        {
            throw new NotFoundException(nameof(Restaurant), request.RestaurantId);
        }

        if (restaurant.DiscountPercent <= 0)
        {
            throw new ValidationException("RestaurantId", "This restaurant does not give a discount.");
        }

        var codes = unitOfWork.Repository<DiscountCode>();
        var now = DateTimeOffset.UtcNow;
        var today = BakuTime.DayOf(now);

        var existing = await codes.Query().FirstOrDefaultAsync(
            c => c.RestaurantId == restaurant.Id && c.DeviceId == request.DeviceId && c.LocalDay == today, cancellationToken);
        if (existing is not null)
        {
            return DiscountCodeDto.From(existing, restaurant.Name, now);
        }

        for (var attempt = 0; attempt < MaxCodeAttempts; attempt++)
        {
            var code = ReservationCodeGenerator.Generate();
            if (await codes.Query().AnyAsync(c => c.Code == code, cancellationToken))
            {
                continue;
            }

            var created = new DiscountCode
            {
                RestaurantId = restaurant.Id,
                Code = code,
                DeviceId = request.DeviceId,
                DiscountPercent = restaurant.DiscountPercent,
                LocalDay = today,
                ExpiresAt = now.AddHours(DiscountCode.ValidHours),
            };

            await codes.AddAsync(created, cancellationToken);
            try
            {
                await unitOfWork.SaveChangesAsync(cancellationToken);
            }
            catch (DbUpdateException)
            {
                // The same device asked twice at once: the other request made the day's code, so hand that one out.
                var winner = await codes.Query().FirstOrDefaultAsync(
                    c => c.RestaurantId == restaurant.Id && c.DeviceId == request.DeviceId && c.LocalDay == today, cancellationToken);
                if (winner is not null)
                {
                    return DiscountCodeDto.From(winner, restaurant.Name, now);
                }

                throw;
            }

            return DiscountCodeDto.From(created, restaurant.Name, now);
        }

        throw new ValidationException("code", "Could not make a code. Please try again.");
    }
}

/// <summary>Public query: where a code stands (still valid, used by the restaurant, run out). The code is the proof of ownership.</summary>
public sealed record GetDiscountCodeStatusQuery(string Code) : IRequest<DiscountCodeDto>;

public class GetDiscountCodeStatusQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetDiscountCodeStatusQuery, DiscountCodeDto>
{
    public async Task<DiscountCodeDto> Handle(GetDiscountCodeStatusQuery request, CancellationToken cancellationToken)
    {
        var code = request.Code.Trim().ToUpperInvariant();
        var found = await unitOfWork.Repository<DiscountCode>().Query().Include(c => c.Restaurant).FirstOrDefaultAsync(c => c.Code == code, cancellationToken)
            ?? throw new NotFoundException(nameof(DiscountCode), code);

        return DiscountCodeDto.From(found, found.Restaurant!.Name, DateTimeOffset.UtcNow);
    }
}

/// <summary>
/// Public command: the app tells HARA what a customer did with a restaurant (opened its page, opened the way to it in maps), for the
/// numbers the admin shows. Nothing is returned and a failure is never the customer's problem.
/// </summary>
public sealed record RecordRestaurantEventCommand(Guid RestaurantId, string Type, string DeviceId) : IRequest<Unit>;

public class RecordRestaurantEventCommandValidator : AbstractValidator<RecordRestaurantEventCommand>
{
    public RecordRestaurantEventCommandValidator()
    {
        RuleFor(c => c.RestaurantId).NotEmpty();
        RuleFor(c => c.Type).Must(type => RestaurantEvent.Types.Contains(type)).WithMessage("Unknown event.");
        RuleFor(c => c.DeviceId).NotEmpty().Matches(DeviceIds.Pattern).WithMessage("The device number is not valid.");
    }
}

public class RecordRestaurantEventCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<RecordRestaurantEventCommand, Unit>
{
    public async Task<Unit> Handle(RecordRestaurantEventCommand request, CancellationToken cancellationToken)
    {
        var restaurant = await unitOfWork.Repository<Restaurant>().GetByIdAsync(request.RestaurantId, cancellationToken);
        if (restaurant is null || !restaurant.IsActive)
        {
            throw new NotFoundException(nameof(Restaurant), request.RestaurantId);
        }

        await unitOfWork.Repository<RestaurantEvent>().AddAsync(
            new RestaurantEvent { RestaurantId = restaurant.Id, Type = request.Type, DeviceId = request.DeviceId, CreatedAt = DateTimeOffset.UtcNow },
            cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return Unit.Value;
    }
}
