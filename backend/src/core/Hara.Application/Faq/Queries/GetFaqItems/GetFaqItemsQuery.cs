using MediatR;

namespace Hara.Application.Faq.Queries.GetFaqItems;

/// <summary>
/// Lists FAQ entries ordered by <c>SortOrder</c>. The public endpoint always passes
/// <paramref name="OnlyActive"/> = <c>true</c>; the admin endpoint passes <c>false</c>
/// to see everything, including deactivated entries.
/// </summary>
public sealed record GetFaqItemsQuery(bool OnlyActive) : IRequest<IReadOnlyList<FaqItemDto>>;
