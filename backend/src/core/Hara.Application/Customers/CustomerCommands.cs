using FluentValidation;
using Hara.Application.Auth;
using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Application.Reviews;
using Hara.Domain.Customers;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Customers;

/// <summary>A customer's session: HARA's own tokens (not Google's) and what the app shows about them.</summary>
public sealed record CustomerSessionDto(string Token, DateTimeOffset ExpiresAtUtc, string? RefreshToken, IReadOnlyList<string> Roles, string? Name, string? PhotoUrl);

/// <summary>What the app shows about the signed-in customer.</summary>
public sealed record CustomerDto(string? Name, string? Email, string? PhotoUrl);

/// <summary>The customer signs in with Google: the app sends the token Google gave it; HARA checks it and answers with HARA's own session. The first time, an account is made.</summary>
public sealed record SignInWithGoogleCommand(string IdToken) : IRequest<CustomerSessionDto>;

public class SignInWithGoogleCommandValidator : AbstractValidator<SignInWithGoogleCommand>
{
    public SignInWithGoogleCommandValidator()
    {
        RuleFor(c => c.IdToken).NotEmpty().MaximumLength(8000);
    }
}

public class SignInWithGoogleCommandHandler(IGoogleTokenVerifier verifier, IIdentityService identityService, IUnitOfWork unitOfWork) : IRequestHandler<SignInWithGoogleCommand, CustomerSessionDto>
{
    public async Task<CustomerSessionDto> Handle(SignInWithGoogleCommand request, CancellationToken cancellationToken)
    {
        var identity = await verifier.VerifyAsync(request.IdToken, cancellationToken) ?? throw new AuthenticationFailedException();
        var profiles = unitOfWork.Repository<CustomerProfile>();

        var profile = await profiles.Query().FirstOrDefaultAsync(p => p.FirebaseUid == identity.Uid, cancellationToken);
        if (profile is null)
        {
            // The account's sign-in name is made up: the person's own email is never used to sign in, so it cannot clash with an owner's.
            var registration = await identityService.RegisterExternalAsync($"google-{identity.Uid}@customers.hara.invalid", Roles.Customer, cancellationToken);
            if (!registration.Succeeded)
            {
                throw new AuthenticationFailedException();
            }

            profile = new CustomerProfile { Id = registration.UserId!.Value, FirebaseUid = identity.Uid };
            await profiles.AddAsync(profile, cancellationToken);
        }
        else
        {
            profiles.Update(profile);
        }

        profile.DisplayName = identity.Name;
        profile.Email = identity.Email;
        profile.PhotoUrl = identity.PictureUrl;

        try
        {
            await unitOfWork.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            // Two sign-ins of a new person at once: the other one made the account; use it.
            profile = await profiles.Query().FirstOrDefaultAsync(p => p.FirebaseUid == identity.Uid, cancellationToken) ?? throw new AuthenticationFailedException();
        }

        var session = await identityService.IssueSessionAsync(profile.Id, cancellationToken);
        if (!session.Succeeded)
        {
            throw new AuthenticationFailedException();
        }

        return new CustomerSessionDto(session.Token!, session.ExpiresAtUtc!.Value, session.RefreshToken, session.Roles ?? [Roles.Customer], profile.PublicName, profile.PhotoUrl);
    }
}

/// <summary>The signed-in customer.</summary>
public sealed record GetCustomerQuery : IRequest<CustomerDto>;

public class GetCustomerQueryHandler(IUnitOfWork unitOfWork, ICurrentUserService currentUser) : IRequestHandler<GetCustomerQuery, CustomerDto>
{
    public async Task<CustomerDto> Handle(GetCustomerQuery request, CancellationToken cancellationToken)
    {
        var userId = currentUser.UserId ?? throw new ForbiddenException();
        var profile = await unitOfWork.Repository<CustomerProfile>().Query().FirstOrDefaultAsync(p => p.Id == userId, cancellationToken)
            ?? throw new ForbiddenException();

        return new CustomerDto(profile.PublicName, profile.Email, profile.PhotoUrl);
    }
}

/// <summary>The customer deletes their account: the profile and every review go, and the restaurants' averages are worked out again.</summary>
public sealed record DeleteCustomerAccountCommand : IRequest<Unit>;

public class DeleteCustomerAccountCommandHandler(IIdentityService identityService, IUnitOfWork unitOfWork, ICurrentUserService currentUser) : IRequestHandler<DeleteCustomerAccountCommand, Unit>
{
    public async Task<Unit> Handle(DeleteCustomerAccountCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUser.UserId ?? throw new ForbiddenException();
        if (!await unitOfWork.Repository<CustomerProfile>().Query().AnyAsync(p => p.Id == userId, cancellationToken))
        {
            throw new ForbiddenException("This account can't be deleted here.");
        }

        var restaurantIds = await unitOfWork.Repository<Review>().Query().Where(r => r.CustomerId == userId).Select(r => r.RestaurantId).Distinct().ToListAsync(cancellationToken);

        // The account goes, and with it the profile and the reviews (they hang from it).
        await identityService.DeleteUserAsync(userId, cancellationToken);

        foreach (var restaurantId in restaurantIds)
        {
            await RatingTotals.RecomputeAsync(unitOfWork, restaurantId, cancellationToken);
        }

        await unitOfWork.SaveChangesAsync(cancellationToken);

        return Unit.Value;
    }
}
