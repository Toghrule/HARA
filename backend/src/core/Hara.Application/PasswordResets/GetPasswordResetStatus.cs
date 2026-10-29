using FluentValidation;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Members;
using MediatR;

namespace Hara.Application.PasswordResets;

/// <summary>The asking phone checks how its request is going.</summary>
public sealed record GetPasswordResetStatusQuery(Guid RequestId, string Secret) : IRequest<PasswordResetStatusDto>;

/// <param name="Status">Where the request stands.</param>
/// <param name="ExpiresAt">While approved: until when the new password can be set.</param>
public sealed record PasswordResetStatusDto(PasswordResetStatus Status, DateTimeOffset? ExpiresAt);

public class GetPasswordResetStatusQueryValidator : AbstractValidator<GetPasswordResetStatusQuery>
{
    public GetPasswordResetStatusQueryValidator()
    {
        RuleFor(q => q.RequestId).NotEmpty();
        RuleFor(q => q.Secret).NotEmpty().MaximumLength(100);
    }
}

public class GetPasswordResetStatusQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetPasswordResetStatusQuery, PasswordResetStatusDto>
{
    public async Task<PasswordResetStatusDto> Handle(GetPasswordResetStatusQuery request, CancellationToken cancellationToken)
    {
        var stored = await unitOfWork.Repository<PasswordResetRequest>().GetByIdAsync(request.RequestId, cancellationToken);

        // An unknown request or a wrong secret looks like a request still waiting, so nobody can probe for requests.
        if (stored is null || !PasswordResetSecret.Matches(request.Secret, stored.SecretHash))
        {
            return new PasswordResetStatusDto(PasswordResetStatus.Pending, null);
        }

        var status = stored.EffectiveStatus(DateTimeOffset.UtcNow);

        return new PasswordResetStatusDto(status, status == PasswordResetStatus.Approved ? stored.ExpiresAt : null);
    }
}
