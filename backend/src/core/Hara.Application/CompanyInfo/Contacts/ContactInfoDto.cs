using Hara.Domain.CompanyInfo;

namespace Hara.Application.CompanyInfo.Contacts;

/// <summary>Read model for a <see cref="ContactInfo"/> entry.</summary>
public sealed record ContactInfoDto(
    Guid Id,
    ContactType Type,
    string Value,
    string? Label,
    int SortOrder,
    bool IsActive)
{
    public static ContactInfoDto FromEntity(ContactInfo contact) => new(
        contact.Id,
        contact.Type,
        contact.Value,
        contact.Label,
        contact.SortOrder,
        contact.IsActive);
}
