using System.Security.Cryptography;
using System.Text;
using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Members;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.EmailConfirmation;

/// <summary>
/// Proves that a new owner or waiter really owns the email they signed up with: a six-digit code goes to that address and has
/// to be typed back. Until then the account can do nothing for a restaurant, and it is deleted after a day.
/// </summary>
public class EmailVerificationService(IUnitOfWork unitOfWork, IEmailSender emailSender, IIdentityService identityService)
{
    /// <summary>Whether this account still has to confirm its email.</summary>
    public async Task<bool> IsPendingAsync(Guid userId, CancellationToken cancellationToken) =>
        await unitOfWork.Repository<Domain.Members.EmailVerification>().Query().AnyAsync(v => v.UserId == userId, cancellationToken);

    /// <summary>The address waiting to be confirmed, or <c>null</c> if there is none.</summary>
    public async Task<string?> PendingEmailAsync(Guid userId, CancellationToken cancellationToken) =>
        await unitOfWork.Repository<Domain.Members.EmailVerification>().Query()
            .Where(v => v.UserId == userId)
            .Select(v => v.Email)
            .FirstOrDefaultAsync(cancellationToken);

    /// <summary>
    /// Makes a new code for the account and emails it. The first call for an account starts its row; later ones are "send
    /// again" and wait out <see cref="Domain.Members.EmailVerification.ResendCooldownSeconds"/> and the hourly limit.
    /// Throws a <see cref="ValidationException"/> when it is too soon, or when the email could not be sent.
    /// </summary>
    public async Task IssueAsync(Guid userId, string email, string? language, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<Domain.Members.EmailVerification>();
        var row = await repository.Query().FirstOrDefaultAsync(v => v.UserId == userId, cancellationToken);
        var now = DateTimeOffset.UtcNow;
        var isNew = row is null;

        if (row is not null)
        {
            if (now - row.LastSentAt < TimeSpan.FromSeconds(Domain.Members.EmailVerification.ResendCooldownSeconds))
            {
                throw new ValidationException("code", "Wait a moment before asking for another code.");
            }

            if (now - row.SendWindowStartedAt >= TimeSpan.FromHours(1))
            {
                row.SendWindowStartedAt = now;
                row.SendsInWindow = 0;
            }

            if (row.SendsInWindow >= Domain.Members.EmailVerification.MaxSendsPerHour)
            {
                throw new ValidationException("code", "Too many codes were asked for. Please try again in a while.");
            }
        }

        var code = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
        var salt = Convert.ToHexString(RandomNumberGenerator.GetBytes(16));

        row ??= new Domain.Members.EmailVerification { UserId = userId, SendWindowStartedAt = now };
        row.Email = email;
        row.Salt = salt;
        row.CodeHash = Hash(salt, code);
        row.CodeExpiresAt = now.AddMinutes(Domain.Members.EmailVerification.CodeMinutes);
        row.FailedAttempts = 0;
        row.LastSentAt = now;
        row.SendsInWindow++;

        if (isNew)
        {
            await repository.AddAsync(row, cancellationToken);
        }
        else
        {
            repository.Update(row);
        }

        await unitOfWork.SaveChangesAsync(cancellationToken);

        var (subject, body) = EmailVerificationTexts.For(language, code, Domain.Members.EmailVerification.CodeMinutes);
        try
        {
            await emailSender.SendAsync(new EmailMessage(email, subject, body), cancellationToken);
        }
        catch (EmailDeliveryException)
        {
            throw new ValidationException("email", "We couldn't send the confirmation email. Check the address and try again.");
        }
    }

    /// <summary>
    /// Checks the code the person typed. Right: the email counts as confirmed from now on. Wrong, expired, or too many wrong
    /// guesses: a <see cref="ValidationException"/> that says which (after five wrong guesses a new code has to be asked for).
    /// </summary>
    public async Task VerifyAsync(Guid userId, string code, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<Domain.Members.EmailVerification>();
        var row = await repository.Query().FirstOrDefaultAsync(v => v.UserId == userId, cancellationToken);

        // Nothing waiting: already confirmed, so confirming again is fine.
        if (row is null)
        {
            return;
        }

        if (row.CodeExpiresAt <= DateTimeOffset.UtcNow)
        {
            throw new ValidationException("code", "This code has expired. Ask for a new one.");
        }

        if (row.FailedAttempts >= Domain.Members.EmailVerification.MaxFailedAttempts)
        {
            throw new ValidationException("code", "Too many wrong tries. Ask for a new code.");
        }

        if (!CryptographicOperations.FixedTimeEquals(Encoding.UTF8.GetBytes(Hash(row.Salt, code)), Encoding.UTF8.GetBytes(row.CodeHash)))
        {
            row.FailedAttempts++;
            repository.Update(row);
            await unitOfWork.SaveChangesAsync(cancellationToken);

            throw new ValidationException("code", "That code is not right.");
        }

        repository.Remove(row);
        await unitOfWork.SaveChangesAsync(cancellationToken);
    }

    /// <summary>
    /// Someone signs up with an email that belongs to an account which never confirmed it: that account is removed so the address is
    /// free again (a person who mistyped, or lost the code, can start over; whoever typed it first cannot confirm it anyway).
    /// Does nothing for an address that is free or that belongs to a confirmed account.
    /// </summary>
    public async Task ClearUnconfirmedAccountAsync(string email, CancellationToken cancellationToken)
    {
        var userId = await identityService.FindUserIdByEmailAsync(email, cancellationToken);
        if (userId is not null && await IsPendingAsync(userId.Value, cancellationToken))
        {
            await RemoveUnconfirmedAccountAsync(userId.Value, cancellationToken);
        }
    }

    /// <summary>Removes an account that never confirmed its email, and the registration it made (an owner's restaurant request).</summary>
    public async Task RemoveUnconfirmedAccountAsync(Guid userId, CancellationToken cancellationToken)
    {
        // An unconfirmed owner's request never became a restaurant (the admin cannot create one from it), so it goes entirely.
        var submissions = unitOfWork.Repository<Domain.Restaurants.RestaurantSubmission>();
        var requests = await submissions.Query().Where(s => s.OwnerUserId == userId && s.RestaurantId == null).ToListAsync(cancellationToken);
        foreach (var request in requests)
        {
            submissions.Remove(request);
        }

        await unitOfWork.SaveChangesAsync(cancellationToken);

        // The waiter membership, device tokens and the confirmation row go with the account (cascade).
        await identityService.DeleteUserAsync(userId, cancellationToken);
    }

    private static string Hash(string salt, string code) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(salt + code)));
}
