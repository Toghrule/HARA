using MediatR;

namespace Hara.Application.Advertisements.Commands.ReorderAdvertisements;

/// <summary>
/// Admin command to reorder the ad carousel. The admin panel sends the full
/// list of ad ids in their new display order; each id's index in
/// <paramref name="OrderedIds"/> becomes its new <c>SortOrder</c>.
/// </summary>
/// <param name="OrderedIds">Every affected ad's id, in the desired display order.</param>
public sealed record ReorderAdvertisementCommand(IReadOnlyList<Guid> OrderedIds) : IRequest;
