using MediatR;

namespace Hara.Application.Advertisements.Commands.UpdateAdvertisement;

/// <summary>Admin command to update every editable field of an existing <see cref="Domain.Advertisements.Advertisement"/>, including its visibility.</summary>
public sealed record UpdateAdvertisementCommand(
    Guid Id,
    string? Title,
    string ImageUrl,
    string? LinkUrl,
    int SortOrder,
    bool IsActive) : IRequest<AdvertisementDto>;
