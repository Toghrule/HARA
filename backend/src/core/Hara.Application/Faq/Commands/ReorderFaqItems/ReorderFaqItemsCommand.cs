using MediatR;

namespace Hara.Application.Faq.Commands.ReorderFaqItems;

/// <summary>
/// Admin command to reorder FAQ entries. The admin panel sends the full list of
/// FAQ item ids in their new display order; each entry's <c>SortOrder</c> is set
/// to its index within <paramref name="OrderedIds"/>.
/// </summary>
/// <param name="OrderedIds">All FAQ item ids, in their new display order.</param>
public sealed record ReorderFaqItemsCommand(IReadOnlyList<Guid> OrderedIds) : IRequest;
