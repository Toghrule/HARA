using Hara.Application.EmailConfirmation;
using MediatR;

namespace Hara.Api.Services;

/// <summary>
/// Once an hour deletes the accounts that signed up but never typed in the emailed code within a day, so made-up addresses and
/// the registrations they made do not pile up. The interval can be changed with <c>Cleanup:UnconfirmedAccountsEverySeconds</c>.
/// </summary>
public sealed class UnconfirmedAccountsCleanup(IServiceScopeFactory scopes, IConfiguration configuration, ILogger<UnconfirmedAccountsCleanup> logger)
    : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var seconds = configuration.GetValue("Cleanup:UnconfirmedAccountsEverySeconds", 3600);
        using var timer = new PeriodicTimer(TimeSpan.FromSeconds(Math.Max(seconds, 1)));

        do
        {
            try
            {
                using var scope = scopes.CreateScope();
                var removed = await scope.ServiceProvider.GetRequiredService<ISender>().Send(new PurgeUnconfirmedAccountsCommand(), stoppingToken);
                if (removed > 0)
                {
                    logger.LogInformation("Deleted {Count} account(s) whose email was not confirmed within a day.", removed);
                }
            }
            catch (Exception exception) when (exception is not OperationCanceledException)
            {
                logger.LogError(exception, "Deleting unconfirmed accounts failed; it will be tried again.");
            }
        }
        while (await timer.WaitForNextTickAsync(stoppingToken));
    }
}
