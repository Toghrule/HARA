using FluentValidation.Results;
using Hara.Application.Auth.Commands.Login;
using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Application.EmailConfirmation;
using Hara.Application.Legal;
using Hara.Domain.Members;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;
using ValidationException = Hara.Application.Common.Exceptions.ValidationException;

namespace Hara.Application.Auth.Commands.RegisterStaff;

public class RegisterStaffCommandHandler(IIdentityService identityService, IUnitOfWork unitOfWork, EmailVerificationService verification)
    : IRequestHandler<RegisterStaffCommand, LoginResult>
{
    /// <summary>How many waiters can be waiting for one owner's approval at once, so nobody can bury an owner in requests.</summary>
    private const int MaxPendingPerRestaurant = 20;

    public async Task<LoginResult> Handle(RegisterStaffCommand request, CancellationToken cancellationToken)
    {
        var restaurant = await unitOfWork.Repository<Restaurant>().GetByIdAsync(request.RestaurantId, cancellationToken);
        if (restaurant is null || !restaurant.IsActive)
        {
            throw new NotFoundException(nameof(Restaurant), request.RestaurantId);
        }

        var members = unitOfWork.Repository<RestaurantMember>();
        // Only waiters who confirmed their email count: made-up addresses must not fill the owner's waiting list.
        var unconfirmed = unitOfWork.Repository<EmailVerification>().Query().Select(v => v.UserId);
        var pending = await members.Query()
            .CountAsync(m => m.RestaurantId == restaurant.Id && m.Status == MemberStatus.Pending && !unconfirmed.Contains(m.UserId), cancellationToken);
        if (pending >= MaxPendingPerRestaurant)
        {
            throw new ValidationException("restaurantId", "This restaurant already has many requests waiting. Please try again later.");
        }

        var email = request.Email.Trim();

        // An address whose earlier sign-up never confirmed it is free again.
        await verification.ClearUnconfirmedAccountAsync(email, cancellationToken);

        var registration = await identityService.RegisterAsync(email, request.Password, Roles.Staff, cancellationToken);
        if (!registration.Succeeded)
        {
            throw new ValidationException(registration.Errors.SelectMany(error => error.Value.Select(message => new ValidationFailure(error.Key, message))));
        }

        try
        {
            await members.AddAsync(
                new RestaurantMember
                {
                    UserId = registration.UserId!.Value,
                    RestaurantId = restaurant.Id,
                    Role = MemberRole.Staff,
                    Status = MemberStatus.Pending,
                    FullName = request.FullName.Trim(),
                    Email = email,
                    PhoneNumber = string.IsNullOrWhiteSpace(request.PhoneNumber) ? null : request.PhoneNumber.Trim(),
                },
                cancellationToken);
            await unitOfWork.Repository<TermsAcceptance>().AddAsync(
                LegalAcceptance.Record(registration.UserId!.Value, LegalDocument.UserTerms, DateTimeOffset.UtcNow),
                cancellationToken);
            await unitOfWork.SaveChangesAsync(cancellationToken);
        }
        catch
        {
            await identityService.DeleteUserAsync(registration.UserId!.Value, cancellationToken);
            throw;
        }

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
}
