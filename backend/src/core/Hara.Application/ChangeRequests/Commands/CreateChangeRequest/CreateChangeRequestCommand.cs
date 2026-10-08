using MediatR;

namespace Hara.Application.ChangeRequests.Commands.CreateChangeRequest;

/// <summary>
/// The restaurant's owner asks the admin to change what the app shows about their restaurant. Leave a field
/// out to keep it as is; send an empty string to remove an optional text. At least one field is required.
/// </summary>
public sealed record CreateChangeRequestCommand(
    string? Name,
    string? Address,
    string? PhoneNumber,
    string? Description,
    string? DescriptionRu,
    string? DescriptionEn,
    int? DiscountPercent,
    string? OwnerNote) : IRequest<ChangeRequestDto>;
