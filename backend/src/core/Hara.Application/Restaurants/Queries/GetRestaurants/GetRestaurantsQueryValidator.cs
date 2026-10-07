using FluentValidation;

namespace Hara.Application.Restaurants.Queries.GetRestaurants;

public class GetRestaurantsQueryValidator : AbstractValidator<GetRestaurantsQuery>
{
    public const int MaxPageSize = 100;

    public GetRestaurantsQueryValidator()
    {
        RuleFor(q => q.Search).MaximumLength(100);
        RuleFor(q => q.PageSize).InclusiveBetween(1, MaxPageSize).When(q => q.PageSize.HasValue);
        RuleFor(q => q.Page).GreaterThanOrEqualTo(1).When(q => q.Page.HasValue);
        RuleFor(q => q.PageSize)
            .NotNull().WithMessage("'Page Size' is required when 'Page' is given.")
            .When(q => q.Page.HasValue);
    }
}
