using MediatR;

namespace Hara.Application.Advertisements.Queries.GetAdvertisements;

/// <summary>
/// Lists ads in carousel order. The public endpoint always passes
/// <paramref name="OnlyActive"/> = <c>true</c>; the admin endpoint passes
/// <c>false</c> to see everything, including deactivated ads.
/// </summary>
public sealed record GetAdvertisementsQuery(bool OnlyActive) : IRequest<IReadOnlyList<AdvertisementDto>>;
