using FluentValidation;
using Hara.Application.Common.Interfaces;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.EmailConfirmation;

/// <summary>The signed-in owner or waiter types the six-digit code that was emailed to them.</summary>
public sealed record VerifyEmailCommand(string Code) : IRequest<Unit>;

/// <summary>The signed-in owner or waiter asks for the code again (a new one is made; the old one stops working).</summary>
/// <param name="Language">The language of the email: az, ru or en.</param>
public sealed record ResendEmailCodeCommand(string? Language = null) : IRequest<Unit>;

/// <summary>Deletes accounts whose email was not confirmed within a day, together with what they registered.</summary>
public sealed record PurgeUnconfirmedAccountsCommand : IRequest<int>;

public class VerifyEmailCommandValidator : AbstractValidator<VerifyEmailCommand>
{
    public VerifyEmailCommandValidator()
    {
        RuleFor(c => c.Code).NotEmpty().Matches(@"^\d{6}$").WithMessage("The code is six digits.");
    }
}

public class VerifyEmailCommandHandler(EmailVerificationService verification, ICurrentUserService currentUser) : IRequestHandler<VerifyEmailCommand, Unit>
{
    public async Task<Unit> Handle(VerifyEmailCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUser.UserId ?? throw new Common.Exceptions.ForbiddenException();
        await verification.VerifyAsync(userId, request.Code, cancellationToken);

        return Unit.Value;
    }
}

public class ResendEmailCodeCommandHandler(EmailVerificationService verification, ICurrentUserService currentUser) : IRequestHandler<ResendEmailCodeCommand, Unit>
{
    public async Task<Unit> Handle(ResendEmailCodeCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUser.UserId ?? throw new Common.Exceptions.ForbiddenException();

        // Already confirmed: nothing to send.
        if (await verification.PendingEmailAsync(userId, cancellationToken) is { } email)
        {
            await verification.IssueAsync(userId, email, request.Language, cancellationToken);
        }

        return Unit.Value;
    }
}

public class PurgeUnconfirmedAccountsCommandHandler(IUnitOfWork unitOfWork, EmailVerificationService verification)
    : IRequestHandler<PurgeUnconfirmedAccountsCommand, int>
{
    public async Task<int> Handle(PurgeUnconfirmedAccountsCommand request, CancellationToken cancellationToken)
    {
        var cutoff = DateTimeOffset.UtcNow.AddHours(-Domain.Members.EmailVerification.KeepUnconfirmedHours);
        var userIds = await unitOfWork.Repository<Domain.Members.EmailVerification>().Query()
            .Where(v => v.CreatedAt < cutoff)
            .Select(v => v.UserId)
            .ToListAsync(cancellationToken);

        foreach (var userId in userIds)
        {
            await verification.RemoveUnconfirmedAccountAsync(userId, cancellationToken);
        }

        return userIds.Count;
    }
}
