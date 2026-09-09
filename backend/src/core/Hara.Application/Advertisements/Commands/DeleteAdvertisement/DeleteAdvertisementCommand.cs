using MediatR;

namespace Hara.Application.Advertisements.Commands.DeleteAdvertisement;

/// <summary>Admin command to permanently delete an <see cref="Domain.Advertisements.Advertisement"/>. Prefer deactivating (see <c>UpdateAdvertisementCommand.IsActive</c>) unless it should truly disappear.</summary>
public sealed record DeleteAdvertisementCommand(Guid Id) : IRequest;
