using MediatR;

namespace Hara.Application.Advertisements.Commands.CreateAdvertisement;

/// <summary>Admin command to create a new <see cref="Domain.Advertisements.Advertisement"/>. New ads are created active.</summary>
/// <param name="Title">Optional headline shown over/under the image.</param>
/// <param name="ImageUrl">Relative URL of the ad's image, from a prior upload.</param>
/// <param name="LinkUrl">Optional destination for a tap on the ad.</param>
/// <param name="SortOrder">Position within the carousel; lower values appear first.</param>
public sealed record CreateAdvertisementCommand(
    string? Title,
    string ImageUrl,
    string? LinkUrl,
    int SortOrder) : IRequest<AdvertisementDto>;
