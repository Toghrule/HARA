using MediatR;

namespace Hara.Application.Faq.Commands.DeleteFaqItem;

/// <summary>Admin command to permanently delete a <see cref="Domain.Faq.FaqItem"/>. Prefer deactivating (see <c>UpdateFaqItemCommand.IsActive</c>) unless it should truly disappear.</summary>
public sealed record DeleteFaqItemCommand(Guid Id) : IRequest;
