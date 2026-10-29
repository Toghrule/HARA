using FluentValidation;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Members;
using MediatR;

namespace Hara.Application.Legal;

/// <summary>
/// An owner or waiter who signed up before the texts existed, or when a text has changed, accepts the current versions.
/// Each version sent has to be the current one for a text that is still pending; the person cannot accept an old text.
/// </summary>
/// <param name="TermsVersion">The version of the terms of use being accepted.</param>
/// <param name="VenueAgreementVersion">The version of the restaurant agreement being accepted (owners).</param>
public sealed record AcceptTermsCommand(int TermsVersion = 0, int VenueAgreementVersion = 0) : IRequest<Unit>;

public class AcceptTermsCommandValidator : AbstractValidator<AcceptTermsCommand>
{
    public AcceptTermsCommandValidator()
    {
        RuleFor(c => c.TermsVersion).GreaterThanOrEqualTo(0);
        RuleFor(c => c.VenueAgreementVersion).GreaterThanOrEqualTo(0);
    }
}

public class AcceptTermsCommandHandler(LegalAcceptance legal, IUnitOfWork unitOfWork, ICurrentUserService currentUser)
    : IRequestHandler<AcceptTermsCommand, Unit>
{
    public async Task<Unit> Handle(AcceptTermsCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUser.UserId ?? throw new Common.Exceptions.ForbiddenException();
        var pending = await legal.PendingAsync(userId, cancellationToken);
        var now = DateTimeOffset.UtcNow;

        foreach (var document in pending)
        {
            var sent = document == LegalDocument.UserTerms ? request.TermsVersion : request.VenueAgreementVersion;
            if (sent != LegalVersions.Current(document))
            {
                throw new Common.Exceptions.ValidationException(
                    document == LegalDocument.UserTerms ? "termsVersion" : "venueAgreementVersion",
                    "Please accept the current version of this text.");
            }
        }

        foreach (var document in pending)
        {
            await unitOfWork.Repository<TermsAcceptance>().AddAsync(LegalAcceptance.Record(userId, document, now), cancellationToken);
        }

        await unitOfWork.SaveChangesAsync(cancellationToken);

        return Unit.Value;
    }
}
