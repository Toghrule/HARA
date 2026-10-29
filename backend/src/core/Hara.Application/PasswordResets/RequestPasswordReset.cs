using FluentValidation;
using Hara.Application.Auth;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Members;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.PasswordResets;

/// <summary>An owner who forgot their password asks HARA to allow a new one.</summary>
public sealed record RequestPasswordResetCommand(string Email) : IRequest<PasswordResetTicketDto>;

/// <summary>What the asking phone keeps to follow the request and to finish it: which request, and the secret only this phone has.</summary>
public sealed record PasswordResetTicketDto(Guid RequestId, string Secret);

public class RequestPasswordResetCommandValidator : AbstractValidator<RequestPasswordResetCommand>
{
    public RequestPasswordResetCommandValidator()
    {
        RuleFor(c => c.Email).NotEmpty().EmailAddress().MaximumLength(320);
    }
}

public class RequestPasswordResetCommandHandler(IIdentityService identityService, IUnitOfWork unitOfWork)
    : IRequestHandler<RequestPasswordResetCommand, PasswordResetTicketDto>
{
    public async Task<PasswordResetTicketDto> Handle(RequestPasswordResetCommand request, CancellationToken cancellationToken)
    {
        var email = request.Email.Trim();
        var (secret, hash) = PasswordResetSecret.Create();
        var requestId = Guid.NewGuid();

        var userId = await identityService.FindUserIdByEmailAsync(email, cancellationToken);
        var isOwner = userId is not null && (await identityService.GetRolesAsync(userId.Value, cancellationToken)).Contains(Roles.Owner);

        // The answer is the same whether or not the email belongs to an owner, so this cannot be used to find out who has an
        // account. Only an owner's request is stored, and it is the only kind HARA ever sees.
        if (isOwner)
        {
            var repository = unitOfWork.Repository<PasswordResetRequest>();

            // A new request replaces any earlier one still open (waiting, or approved but unused).
            var open = await repository.Query()
                .Where(r => r.UserId == userId && (r.Status == PasswordResetStatus.Pending || r.Status == PasswordResetStatus.Approved))
                .ToListAsync(cancellationToken);
            foreach (var earlier in open)
            {
                repository.Remove(earlier);
            }

            var created = new PasswordResetRequest { UserId = userId!.Value, Email = email, SecretHash = hash };
            await repository.AddAsync(created, cancellationToken);
            await unitOfWork.SaveChangesAsync(cancellationToken);
            requestId = created.Id;
        }

        return new PasswordResetTicketDto(requestId, secret);
    }
}
