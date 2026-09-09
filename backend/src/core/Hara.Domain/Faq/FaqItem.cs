using Hara.Domain.Common;

namespace Hara.Domain.Faq;

/// <summary>A single question/answer pair shown on the mobile app's FAQ screen.</summary>
public class FaqItem : BaseAuditableEntity
{
    /// <summary>The question text.</summary>
    public string Question { get; set; } = string.Empty;

    /// <summary>The answer text.</summary>
    public string Answer { get; set; } = string.Empty;

    /// <summary>Display position among other FAQ entries; lower values appear first.</summary>
    public int SortOrder { get; set; }

    /// <summary>Whether the entry is currently shown in the mobile app.</summary>
    public bool IsActive { get; set; } = true;
}
