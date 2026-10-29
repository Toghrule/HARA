using FluentValidation;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Members;
using MediatR;

namespace Hara.Application.PasswordResets;

/// <summary>The owner's phone sets the new password, once HARA has approved the request.</summary>
public sealed record CompletePasswordResetCommand(Guid RequestId, string Secret, string NewPassword) : IRequest<Unit>;

public class CompletePasswordResetCommandValidator : AbstractValidator<CompletePasswordResetCommand>
{
    public CompletePasswordResetCommandValidator()
    {
        RuleFor(c => c.RequestId).NotEmpty();
        RuleFor(c => c.Secret).NotEmpty().MaximumLength(100);
        RuleFor(c => c.NewPassword).NotEmpty().MaximumLength(100);
    }
}

public class CompletePasswordResetCommandHandler(IIdentityService identityService, IUnitOfWork unitOfWork)
    : IRequestHandler<CompletePasswordResetCommand, Unit>
{
    public async Task<Unit> Handle(CompletePasswordResetCommand request, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<PasswordResetRequest>();
        var stored = await repository.GetByIdAsync(request.RequestId, cancellationToken);
        var now = DateTimeOffset.UtcNow;

        // Not found, wrong secret, not approved, used up or out of time: all the same answer.
        if (stored is null
            || !PasswordResetSecret.Matches(request.Secret, stored.SecretHash)
            || stored.EffectiveStatus(now) != PasswordResetStatus.Approved)
        {
            throw new Common.Exceptions.ValidationException("request", "This reset request is not valid any more. Please ask again.");
        }

        var result = await identityService.SetPasswordAsync(stored.UserId, request.NewPassword, cancellationToken);
        if (!result.Succeeded)
        {
            // A password that is too weak leaves the request approved, so the owner can try another within the hour.
            throw new Common.Exceptions.ValidationException(result.Errors.Select(error => new FluentValidation.Results.ValidationFailure(error.Key, error.Value[0])));
        }

        stored.Status = PasswordResetStatus.Completed;
        stored.CompletedAt = now;
        repository.Update(stored);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return Unit.Value;
    }
}
