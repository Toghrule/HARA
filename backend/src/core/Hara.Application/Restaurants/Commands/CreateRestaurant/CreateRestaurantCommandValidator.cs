using FluentValidation;

namespace Hara.Application.Restaurants.Commands.CreateRestaurant;

public class CreateRestaurantCommandValidator : AbstractValidator<CreateRestaurantCommand>
{
    /// <summary>The most photos one restaurant can have.</summary>
    public const int MaxGalleryPhotos = 10;

    public CreateRestaurantCommandValidator()
    {
        RuleFor(c => c.Name).NotEmpty().MaximumLength(200);
        RuleFor(c => c.Address).NotEmpty().MaximumLength(400);
        RuleFor(c => c.Latitude).InclusiveBetween(-90, 90);
        RuleFor(c => c.Longitude).InclusiveBetween(-180, 180);
        RuleFor(c => c.PhoneNumber).MaximumLength(50);
        RuleFor(c => c.Description).MaximumLength(4000);
        RuleFor(c => c.DescriptionRu).MaximumLength(4000);
        RuleFor(c => c.DescriptionEn).MaximumLength(4000);
        RuleFor(c => c.ImageUrl).MaximumLength(1000);
        RuleFor(c => c.DiscountPercent).InclusiveBetween(0, 100);
        RuleFor(c => c.Cuisines)
            .Must(cuisines => cuisines!.Distinct().Count() <= Domain.Restaurants.Cuisines.MaxPerRestaurant)
            .WithMessage($"At most {Domain.Restaurants.Cuisines.MaxPerRestaurant} cuisines.")
            .Must(cuisines => cuisines!.All(Domain.Restaurants.Cuisines.IsKnown))
            .WithMessage("Unknown cuisine.")
            .When(c => c.Cuisines is not null);
        RuleFor(c => c.GalleryUrls)
            .Must(urls => urls!.Count <= MaxGalleryPhotos)
            .WithMessage($"At most {MaxGalleryPhotos} photos.")
            .Must(urls => urls!.All(url => !string.IsNullOrWhiteSpace(url) && url.Length <= 1000))
            .WithMessage("A photo address is empty or too long.")
            .When(c => c.GalleryUrls is not null);
    }
}
