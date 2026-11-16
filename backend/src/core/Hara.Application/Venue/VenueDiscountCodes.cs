using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Application.Discounts;
using Hara.Domain.Discounts;
using Hara.Domain.Reservations;
using MediatR;
using Microsoft.EntityFrameworkCore;
using ValidationException = Hara.Application.Common.Exceptions.ValidationException;

namespace Hara.Application.Venue;

/// <summary>A discount code as the restaurant sees it when checking it. Same shape as a reservation (no phone number: there is none), so the app shows both alike.</summary>
internal static class VenueDiscountCodeMapper
{
    public static VenueReservationDto ToDto(DiscountCode code, DateTimeOffset now) => new(
        code.Id,
        code.Code,
        string.Empty,
        DiscountCode.ValidHours * 60,
        code.CreatedAt,
        code.ExpiresAt,
        DiscountCodeDto.StatusOf(code, now),
        code.RedeemedAt,
        code.DiscountPercent);
}

/// <summary>Restaurant side: looks up a discount code of THIS restaurant (a code of another one is "not found").</summary>
public sealed record GetVenueDiscountCodeQuery(string Code) : IRequest<VenueReservationDto>;

public class GetVenueDiscountCodeQueryHandler(VenueAccess access, IUnitOfWork unitOfWork) : IRequestHandler<GetVenueDiscountCodeQuery, VenueReservationDto>
{
    public async Task<VenueReservationDto> Handle(GetVenueDiscountCodeQuery request, CancellationToken cancellationToken)
    {
        var member = await access.RequireApprovedMemberAsync(cancellationToken);
        var code = request.Code.Trim().ToUpperInvariant();

        var found = await unitOfWork.Repository<DiscountCode>().Query()
            .FirstOrDefaultAsync(c => c.Code == code && c.RestaurantId == member.RestaurantId, cancellationToken)
            ?? throw new NotFoundException(nameof(DiscountCode), code);

        return VenueDiscountCodeMapper.ToDto(found, DateTimeOffset.UtcNow);
    }
}

/// <summary>Restaurant side: confirms a code. That gives the customer the discount and counts the customer HARA brought. A code can be confirmed once, within its 6 hours.</summary>
public sealed record RedeemVenueDiscountCodeCommand(string Code) : IRequest<VenueReservationDto>;

public class RedeemVenueDiscountCodeCommandHandler(VenueAccess access, IUnitOfWork unitOfWork, ICurrentUserService currentUser)
    : IRequestHandler<RedeemVenueDiscountCodeCommand, VenueReservationDto>
{
    public async Task<VenueReservationDto> Handle(RedeemVenueDiscountCodeCommand request, CancellationToken cancellationToken)
    {
        var member = await access.RequireApprovedMemberAsync(cancellationToken);
        var code = request.Code.Trim().ToUpperInvariant();
        var repository = unitOfWork.Repository<DiscountCode>();

        var found = await repository.Query().FirstOrDefaultAsync(c => c.Code == code && c.RestaurantId == member.RestaurantId, cancellationToken)
            ?? throw new NotFoundException(nameof(DiscountCode), code);

        var now = DateTimeOffset.UtcNow;
        if (found.RedeemedAt is not null)
        {
            throw new ValidationException("code", "This code has already been used.");
        }

        if (found.ExpiresAt <= now)
        {
            throw new ValidationException("code", "This code has expired.");
        }

        found.RedeemedAt = now;
        found.RedeemedByUserId = currentUser.UserId;
        repository.Update(found);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return VenueDiscountCodeMapper.ToDto(found, now);
    }
}
