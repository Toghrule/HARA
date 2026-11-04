using FluentValidation.Results;
using Hara.Application.Auth.Commands.Login;
using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Application.EmailConfirmation;
using Hara.Application.Legal;
using Hara.Domain.Members;
using Hara.Domain.Restaurants;
using MediatR;
using ValidationException = Hara.Application.Common.Exceptions.ValidationException;

namespace Hara.Application.Auth.Commands.RegisterOwner;

public class RegisterOwnerCommandHandler(IIdentityService identityService, IUnitOfWork unitOfWork, EmailVerificationService verification)
    : IRequestHandler<RegisterOwnerCommand, LoginResult>
{
    public async Task<LoginResult> Handle(RegisterOwnerCommand request, CancellationToken cancellationToken)
    {
        var email = request.Email.Trim();

        // An address whose earlier sign-up never confirmed it is free again.
        await verification.ClearUnconfirmedAccountAsync(email, cancellationToken);

        var registration = await identityService.RegisterAsync(email, request.Password, Roles.Owner, cancellationToken);
        if (!registration.Succeeded)
        {
            throw new ValidationException(registration.Errors.SelectMany(error => error.Value.Select(message => new ValidationFailure(error.Key, message))));
        }

        try
        {
            await unitOfWork.Repository<RestaurantSubmission>().AddAsync(
                new RestaurantSubmission
                {
                    RestaurantName = request.RestaurantName.Trim(),
                    Address = request.Address.Trim(),
                    PhoneNumber = Clean(request.RestaurantPhoneNumber),
                    Description = Clean(request.Description),
                    SubmitterName = request.FullName.Trim(),
                    SubmitterEmail = email,
                    SubmitterPhoneNumber = Clean(request.PhoneNumber),
                    OwnerUserId = registration.UserId,
                },
                cancellationToken);
            await RecordAcceptancesAsync(registration.UserId!.Value, cancellationToken);
            await unitOfWork.SaveChangesAsync(cancellationToken);
        }
        catch
        {
            // Don't leave an account behind that has no registration for the admin to review.
            await identityService.DeleteUserAsync(registration.UserId!.Value, cancellationToken);
            throw;
        }

        // The account exists but can do nothing until the emailed code is typed in; if no email can be sent there is nothing
        // to confirm with, so the sign-up is undone.
        try
        {
            await verification.IssueAsync(registration.UserId!.Value, email, request.Language, cancellationToken);
        }
        catch
        {
            await verification.RemoveUnconfirmedAccountAsync(registration.UserId!.Value, cancellationToken);
            throw;
        }

        var session = await identityService.AuthenticateAsync(email, request.Password, cancellationToken);
        if (!session.Succeeded)
        {
            throw new AuthenticationFailedException();
        }

        return new LoginResult(session.Token!, session.ExpiresAtUtc!.Value, session.RefreshToken, session.Roles);
    }

    /// <summary>Saves, with the registration, that the new owner accepted the current texts.</summary>
    private async Task RecordAcceptancesAsync(Guid userId, CancellationToken cancellationToken)
    {
        var now = DateTimeOffset.UtcNow;
        foreach (var document in LegalAcceptance.RequiredFor([Roles.Owner]))
        {
            await unitOfWork.Repository<TermsAcceptance>().AddAsync(LegalAcceptance.Record(userId, document, now), cancellationToken);
        }
    }

    private static string? Clean(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
