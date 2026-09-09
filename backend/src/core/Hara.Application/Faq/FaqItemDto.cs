namespace Hara.Application.Faq;

/// <summary>Read model for a <see cref="Hara.Domain.Faq.FaqItem"/>, returned by every Faq query/command.</summary>
/// <param name="Id">Unique identifier.</param>
/// <param name="Question">The question text.</param>
/// <param name="Answer">The answer text.</param>
/// <param name="SortOrder">Display position among other FAQ entries; lower values appear first.</param>
/// <param name="IsActive">Whether the entry is currently shown in the mobile app.</param>
/// <param name="CreatedAt">When the FAQ entry was created.</param>
/// <param name="LastModifiedAt">When the FAQ entry was last updated, if ever.</param>
public sealed record FaqItemDto(
    Guid Id,
    string Question,
    string Answer,
    int SortOrder,
    bool IsActive,
    DateTimeOffset CreatedAt,
    DateTimeOffset? LastModifiedAt)
{
    public static FaqItemDto FromEntity(Domain.Faq.FaqItem faqItem) => new(
        faqItem.Id,
        faqItem.Question,
        faqItem.Answer,
        faqItem.SortOrder,
        faqItem.IsActive,
        faqItem.CreatedAt,
        faqItem.LastModifiedAt);
}
