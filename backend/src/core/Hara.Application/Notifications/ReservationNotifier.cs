using Hara.Application.Common.Interfaces;
using Hara.Domain.Devices;
using Hara.Domain.Members;
using Hara.Domain.Reservations;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Hara.Application.Notifications;

/// <summary>
/// Tells people about reservation requests by push notification: the restaurant's people when a request
/// comes in, the customer when the restaurant answers. Phones also poll while the app is open, so a
/// notification is a convenience: any failure here is logged and swallowed, never shown to the caller.
/// </summary>
public class ReservationNotifier(IUnitOfWork unitOfWork, IPushSender sender, ILogger<ReservationNotifier> logger)
{
    private static readonly TimeSpan SendTimeout = TimeSpan.FromSeconds(8);

    /// <summary>A customer sent a request: tell everyone approved at the restaurant.</summary>
    public async Task NewRequestAsync(Reservation reservation)
    {
        await TrySendAsync(async cancellationToken =>
        {
            var userIds = await unitOfWork.Repository<RestaurantMember>().Query()
                .Where(m => m.RestaurantId == reservation.RestaurantId && m.Status == MemberStatus.Approved)
                .Select(m => m.UserId)
                .ToListAsync(cancellationToken);

            var tokens = await unitOfWork.Repository<DeviceToken>().Query()
                .Where(t => t.UserId != null && userIds.Contains(t.UserId.Value))
                .ToListAsync(cancellationToken);

            var data = new Dictionary<string, string> { ["type"] = "newRequest", ["code"] = reservation.Code };
            var messages = tokens
                .Select(t => PushTexts.NewRequest(t.Language, t.Token, reservation.PhoneNumber, data))
                .ToList();

            return (messages, tokens);
        });
    }

    /// <summary>The restaurant accepted or declined: tell the customer who sent it.</summary>
    public async Task AnsweredAsync(Reservation reservation, string restaurantName, bool accepted)
    {
        await TrySendAsync(async cancellationToken =>
        {
            var tokens = await unitOfWork.Repository<DeviceToken>().Query()
                .Where(t => t.ReservationId == reservation.Id)
                .ToListAsync(cancellationToken);

            var data = new Dictionary<string, string> { ["type"] = accepted ? "accepted" : "declined", ["code"] = reservation.Code };
            var messages = tokens
                .Select(t => PushTexts.Answer(t.Language, t.Token, accepted, restaurantName, data))
                .ToList();

            return (messages, tokens);
        });
    }

    private async Task TrySendAsync(Func<CancellationToken, Task<(List<PushMessage> Messages, List<DeviceToken> Tokens)>> prepare)
    {
        try
        {
            using var timeout = new CancellationTokenSource(SendTimeout);
            var (messages, tokens) = await prepare(timeout.Token);

            if (messages.Count == 0)
            {
                return;
            }

            var invalid = await sender.SendAsync(messages, timeout.Token);
            var repository = unitOfWork.Repository<DeviceToken>();

            foreach (var token in tokens.Where(t => invalid.Contains(t.Token)))
            {
                repository.Remove(token);
            }

            if (invalid.Count > 0)
            {
                await unitOfWork.SaveChangesAsync(timeout.Token);
            }
        }
        catch (Exception exception)
        {
            logger.LogWarning(exception, "Could not send a push notification.");
        }
    }
}
