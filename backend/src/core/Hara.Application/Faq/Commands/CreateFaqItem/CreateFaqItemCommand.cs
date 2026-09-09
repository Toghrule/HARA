using MediatR;

namespace Hara.Application.Faq.Commands.CreateFaqItem;

/// <summary>Admin command to create a new <see cref="Domain.Faq.FaqItem"/>. New items are active by default.</summary>
/// <param name="Question">The question text.</param>
/// <param name="Answer">The answer text.</param>
/// <param name="SortOrder">Display position among other FAQ entries; lower values appear first.</param>
public sealed record CreateFaqItemCommand(
    string Question,
    string Answer,
    int SortOrder) : IRequest<FaqItemDto>;
