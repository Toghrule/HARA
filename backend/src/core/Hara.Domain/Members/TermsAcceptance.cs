using Hara.Domain.Common;

namespace Hara.Domain.Members;

/// <summary>A legal text that restaurant owners and waiters have to accept.</summary>
public enum LegalDocument
{
    /// <summary>The terms of use of the app. Owners and waiters.</summary>
    UserTerms = 0,

    /// <summary>What a restaurant promises when it joins (honouring the discount, answering requests, handling customers' phone numbers). Owners.</summary>
    VenueAgreement = 1
}

/// <summary>
/// The current version of each legal text. When a text changes, raise its number here and in the app
/// (<c>mobile/lib/features/legal/legal_documents.dart</c>): everyone who accepted an older version is asked to accept again
/// the next time they sign in.
/// </summary>
public static class LegalVersions
{
    public const int UserTerms = 1;
    public const int VenueAgreement = 1;

    public static int Current(LegalDocument document) => document switch
    {
        LegalDocument.UserTerms => UserTerms,
        LegalDocument.VenueAgreement => VenueAgreement,
        _ => throw new ArgumentOutOfRangeException(nameof(document))
    };
}

/// <summary>
/// One person accepting one version of one legal text. Rows are only added, never changed, so there is a record of who
/// accepted what and when. They go away with the account.
/// </summary>
public class TermsAcceptance : BaseAuditableEntity
{
    public Guid UserId { get; set; }

    public LegalDocument Document { get; set; }

    /// <summary>The version of the text that was accepted.</summary>
    public int Version { get; set; }

    /// <summary>When it was accepted.</summary>
    public DateTimeOffset AcceptedAt { get; set; }
}
