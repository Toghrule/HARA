using MediatR;

namespace Hara.Application.Faq.Commands.UpdateFaqItem;

/// <summary>Admin command to update every editable field of an existing <see cref="Domain.Faq.FaqItem"/>, including its visibility.</summary>
/// <param name="Id">Unique identifier of the FAQ entry to update.</param>
/// <param name="Question">The question text.</param>
/// <param name="Answer">The answer text.</param>
/// <param name="SortOrder">Display position among other FAQ entries; lower values appear first.</param>
/// <param name="IsActive">Whether the entry is currently shown in the mobile app.</param>
public sealed record UpdateFaqItemCommand(
    Guid Id,
    string Question,
    string Answer,
    int SortOrder,
    bool IsActive) : IRequest<FaqItemDto>;
