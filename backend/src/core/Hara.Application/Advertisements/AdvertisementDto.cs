namespace Hara.Application.Advertisements;

/// <summary>Read model for a <see cref="Hara.Domain.Advertisements.Advertisement"/>, returned by every Advertisements query/command.</summary>
/// <param name="Id">Unique identifier.</param>
/// <param name="Title">Optional headline shown over/under the image.</param>
/// <param name="ImageUrl">Relative URL of the ad's image, as returned by the upload endpoint.</param>
/// <param name="LinkUrl">Where tapping the ad should take the user, if anywhere.</param>
/// <param name="SortOrder">Position within the carousel; lower values appear first.</param>
/// <param name="IsActive">Whether the ad is currently shown in the mobile app carousel.</param>
/// <param name="CreatedAt">When the ad was created.</param>
/// <param name="LastModifiedAt">When the ad was last updated, if ever.</param>
public sealed record AdvertisementDto(
    Guid Id,
    string? Title,
    string ImageUrl,
    string? LinkUrl,
    int SortOrder,
    bool IsActive,
    DateTimeOffset CreatedAt,
    DateTimeOffset? LastModifiedAt)
{
    public static AdvertisementDto FromEntity(Domain.Advertisements.Advertisement advertisement) => new(
        advertisement.Id,
        advertisement.Title,
        advertisement.ImageUrl,
        advertisement.LinkUrl,
        advertisement.SortOrder,
        advertisement.IsActive,
        advertisement.CreatedAt,
        advertisement.LastModifiedAt);
}
