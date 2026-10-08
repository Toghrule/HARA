using FluentValidation.Results;
using Hara.Application.Auth.Commands.Login;
using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Restaurants;
using MediatR;
using ValidationException = Hara.Application.Common.Exceptions.ValidationException;

namespace Hara.Application.Auth.Commands.RegisterOwner;

public class RegisterOwnerCommandHandler(IIdentityService identityService, IUnitOfWork unitOfWork)
    : IRequestHandler<RegisterOwnerCommand, LoginResult>
{
    public async Task<LoginResult> Handle(RegisterOwnerCommand request, CancellationToken cancellationToken)
    {
        var email = request.Email.Trim();

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
            await unitOfWork.SaveChangesAsync(cancellationToken);
        }
        catch
        {
            // Don't leave an account behind that has no registration for the admin to review.
            await identityService.DeleteUserAsync(registration.UserId!.Value, cancellationToken);
            throw;
        }

        var session = await identityService.AuthenticateAsync(email, request.Password, cancellationToken);
        if (!session.Succeeded)
        {
            throw new AuthenticationFailedException();
        }

        return new LoginResult(session.Token!, session.ExpiresAtUtc!.Value, session.RefreshToken, session.Roles);
    }

    private static string? Clean(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
