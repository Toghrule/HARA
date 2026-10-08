using Hara.Application.Common;

namespace Hara.Application.Faq;

/// <summary>Read model for a <see cref="Hara.Domain.Faq.FaqItem"/>, returned by every Faq query/command.</summary>
/// <param name="Id">Unique identifier.</param>
/// <param name="Question">The question text (Azerbaijani — or the requested language, after <see cref="Localize"/>).</param>
/// <param name="Answer">The answer text (Azerbaijani — or the requested language, after <see cref="Localize"/>).</param>
/// <param name="SortOrder">Display position among other FAQ entries; lower values appear first.</param>
/// <param name="IsActive">Whether the entry is currently shown in the mobile app.</param>
/// <param name="CreatedAt">When the FAQ entry was created.</param>
/// <param name="LastModifiedAt">When the FAQ entry was last updated, if ever.</param>
/// <param name="QuestionRu">Russian translation of the question, if filled in.</param>
/// <param name="QuestionEn">English translation of the question, if filled in.</param>
/// <param name="AnswerRu">Russian translation of the answer, if filled in.</param>
/// <param name="AnswerEn">English translation of the answer, if filled in.</param>
public sealed record FaqItemDto(
    Guid Id,
    string Question,
    string Answer,
    int SortOrder,
    bool IsActive,
    DateTimeOffset CreatedAt,
    DateTimeOffset? LastModifiedAt,
    string? QuestionRu = null,
    string? QuestionEn = null,
    string? AnswerRu = null,
    string? AnswerEn = null)
{
    public static FaqItemDto FromEntity(Domain.Faq.FaqItem faqItem) => new(
        faqItem.Id,
        faqItem.Question,
        faqItem.Answer,
        faqItem.SortOrder,
        faqItem.IsActive,
        faqItem.CreatedAt,
        faqItem.LastModifiedAt,
        faqItem.QuestionRu,
        faqItem.QuestionEn,
        faqItem.AnswerRu,
        faqItem.AnswerEn);

    /// <summary>Returns a copy whose question and answer are in <paramref name="language"/> (each falling back to Azerbaijani).</summary>
    public FaqItemDto Localize(string? language) => this with
    {
        Question = Localization.Pick(language, Question, QuestionRu, QuestionEn) ?? string.Empty,
        Answer = Localization.Pick(language, Answer, AnswerRu, AnswerEn) ?? string.Empty,
    };
}
