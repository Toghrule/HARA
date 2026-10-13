using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Auth.Commands.DeleteAccount;

public class DeleteAccountCommandHandler(IIdentityService identityService, IUnitOfWork unitOfWork, ICurrentUserService currentUser)
    : IRequestHandler<DeleteAccountCommand>
{
    public async Task Handle(DeleteAccountCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUser.UserId ?? throw new ForbiddenException();

        // Admin accounts run the platform; they are not removed from the app.
        var roles = await identityService.GetRolesAsync(userId, cancellationToken);
        if (roles.Contains(Roles.Admin) || !(roles.Contains(Roles.Owner) || roles.Contains(Roles.Staff)))
        {
            throw new ForbiddenException("This account can't be deleted here.");
        }

        switch (await identityService.CheckPasswordAsync(userId, request.Password, cancellationToken))
        {
            case PasswordCheck.Wrong:
                throw new ValidationException("password", "Wrong password.");
            case PasswordCheck.LockedOut:
                throw new ValidationException("password", "Too many wrong attempts. Please try again later.");
            case PasswordCheck.NoSuchAccount:
                throw new ForbiddenException();
        }

        await RemovePersonalDataFromRegistrationsAsync(userId, cancellationToken);

        // Deleting the account also removes the person's membership (name, email, phone) and their sessions;
        // the restaurant, its reservations and any change requests stay, with the person's link cleared.
        await identityService.DeleteUserAsync(userId, cancellationToken);
    }

    /// <summary>
    /// An owner's registration holds their name, email and phone. One that never became a restaurant is
    /// deleted; one that did is kept (the restaurant came from it) but with the person's details removed.
    /// </summary>
    private async Task RemovePersonalDataFromRegistrationsAsync(Guid userId, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<RestaurantSubmission>();
        var registrations = await repository.Query().Where(s => s.OwnerUserId == userId).ToListAsync(cancellationToken);

        foreach (var registration in registrations)
        {
            if (registration.RestaurantId is null)
            {
                repository.Remove(registration);
                continue;
            }

            registration.SubmitterName = "(deleted)";
            registration.SubmitterEmail = null;
            registration.SubmitterPhoneNumber = null;
            registration.OwnerUserId = null;
            repository.Update(registration);
        }

        await unitOfWork.SaveChangesAsync(cancellationToken);
    }
}
