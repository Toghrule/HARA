using FluentValidation;

namespace Hara.Application.Venue.Queries.GetVenueReservation;

public class GetVenueReservationQueryValidator : AbstractValidator<GetVenueReservationQuery>
{
    public GetVenueReservationQueryValidator()
    {
        RuleFor(c => c.Code).NotEmpty().MaximumLength(16);
    }
}
