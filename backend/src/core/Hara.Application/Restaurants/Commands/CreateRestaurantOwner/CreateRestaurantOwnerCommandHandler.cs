using FluentValidation.Results;
using Hara.Application.Auth;
using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Members;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;
using ValidationException = Hara.Application.Common.Exceptions.ValidationException;

namespace Hara.Application.Restaurants.Commands.CreateRestaurantOwner;

public class CreateRestaurantOwnerCommandHandler(IIdentityService identityService, IUnitOfWork unitOfWork) : IRequestHandler<CreateRestaurantOwnerCommand, Unit>
{
    public async Task<Unit> Handle(CreateRestaurantOwnerCommand request, CancellationToken cancellationToken)
    {
        var restaurant = await unitOfWork.Repository<Restaurant>().GetByIdAsync(request.RestaurantId, cancellationToken)
            ?? throw new NotFoundException(nameof(Restaurant), request.RestaurantId);

        var hasOwner = await unitOfWork.Repository<RestaurantMember>().Query()
            .AnyAsync(m => m.RestaurantId == restaurant.Id && m.Role == MemberRole.Owner, cancellationToken);
        if (hasOwner)
        {
            throw new ValidationException("restaurantId", "This restaurant already has an owner.");
        }

        var email = request.Email.Trim();
        var registration = await identityService.RegisterAsync(email, request.Password, Roles.Owner, cancellationToken);
        if (!registration.Succeeded)
        {
            throw new ValidationException(registration.Errors.SelectMany(error => error.Value.Select(message => new ValidationFailure(error.Key, message))));
        }

        try
        {
            await unitOfWork.Repository<RestaurantMember>().AddAsync(
                new RestaurantMember
                {
                    UserId = registration.UserId!.Value,
                    RestaurantId = restaurant.Id,
                    Role = MemberRole.Owner,
                    Status = MemberStatus.Approved,
                    FullName = request.FullName.Trim(),
                    Email = email,
                    PhoneNumber = string.IsNullOrWhiteSpace(request.PhoneNumber) ? null : request.PhoneNumber.Trim(),
                },
                cancellationToken);
            await unitOfWork.SaveChangesAsync(cancellationToken);
        }
        catch
        {
            // Don't leave an account behind that belongs to no restaurant.
            await identityService.DeleteUserAsync(registration.UserId!.Value, cancellationToken);
            throw;
        }

        return Unit.Value;
    }
}
