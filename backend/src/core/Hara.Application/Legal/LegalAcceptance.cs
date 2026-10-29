using Hara.Application.Auth;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Members;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Legal;

/// <summary>
/// Which legal texts a restaurant account has accepted, and which it still has to. An owner accepts the terms of use and the
/// restaurant agreement; a waiter only the terms of use. A text counts as accepted only at its current version.
/// </summary>
public class LegalAcceptance(IUnitOfWork unitOfWork, IIdentityService identityService)
{
    /// <summary>The texts this role has to accept.</summary>
    public static IReadOnlyList<LegalDocument> RequiredFor(IEnumerable<string> roles)
    {
        var roleList = roles.ToList();
        if (roleList.Contains(Roles.Owner))
        {
            return [LegalDocument.UserTerms, LegalDocument.VenueAgreement];
        }

        return roleList.Contains(Roles.Staff) ? [LegalDocument.UserTerms] : [];
    }

    /// <summary>The texts this account has not yet accepted at their current version.</summary>
    public async Task<IReadOnlyList<LegalDocument>> PendingAsync(Guid userId, CancellationToken cancellationToken)
    {
        var required = RequiredFor(await identityService.GetRolesAsync(userId, cancellationToken));
        if (required.Count == 0)
        {
            return [];
        }

        var accepted = await unitOfWork.Repository<TermsAcceptance>().Query()
            .Where(a => a.UserId == userId)
            .Select(a => new { a.Document, a.Version })
            .ToListAsync(cancellationToken);

        return required
            .Where(document => !accepted.Any(a => a.Document == document && a.Version >= LegalVersions.Current(document)))
            .ToList();
    }

    /// <summary>A row recording that <paramref name="userId"/> accepted the current version of <paramref name="document"/> now. Not saved yet.</summary>
    public static TermsAcceptance Record(Guid userId, LegalDocument document, DateTimeOffset now) => new()
    {
        UserId = userId,
        Document = document,
        Version = LegalVersions.Current(document),
        AcceptedAt = now
    };

    /// <summary>The names the apps use for the texts: "terms" and "venueAgreement".</summary>
    public static string NameOf(LegalDocument document) => document switch
    {
        LegalDocument.UserTerms => "terms",
        LegalDocument.VenueAgreement => "venueAgreement",
        _ => throw new ArgumentOutOfRangeException(nameof(document))
    };
}
