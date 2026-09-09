using Hara.Domain.Common;

namespace Hara.Domain.CompanyInfo;

/// <summary>
/// A single "Contact Us" entry shown in the mobile app. There can be more
/// than one of each <see cref="ContactType"/> (e.g. a support phone number
/// and a sales phone number), which is why this is a list rather than fixed
/// fields on a settings object.
/// </summary>
public class ContactInfo : BaseAuditableEntity
{
    /// <summary>Whether <see cref="Value"/> is a phone number or an email address.</summary>
    public ContactType Type { get; set; }

    /// <summary>The phone number or email address itself.</summary>
    public string Value { get; set; } = string.Empty;

    /// <summary>Optional short label shown next to the value, e.g. "Support" or "Reservations".</summary>
    public string? Label { get; set; }

    /// <summary>Display position among other contact entries; lower values appear first.</summary>
    public int SortOrder { get; set; }

    /// <summary>Whether the entry is currently shown in the mobile app.</summary>
    public bool IsActive { get; set; } = true;
}
