using Hara.Api.RateLimiting;
using Hara.Application.Discounts;
using MediatR;

namespace Hara.Api.Endpoints;

public sealed record DiscountDeviceBody(string DeviceId);

public sealed record EventBody(string Type, string DeviceId);

/// <summary>
/// The customer's side of the discount code: get the code of a restaurant that gives a discount, see where it stands, and the
/// anonymous taps (a restaurant's page, the way to it in maps) that the admin counts. Nothing here needs an account.
/// </summary>
public static class DiscountEndpoints
{
    public static IEndpointRouteBuilder MapDiscountEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapPost("/api/restaurants/{id:guid}/discount-code", async (Guid id, DiscountDeviceBody body, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetDiscountCodeCommand(id, body.DeviceId), cancellationToken)))
            .WithTags("Discounts")
            .WithName("GetDiscountCode")
            .AllowAnonymous()
            .RequireRateLimiting(RateLimitPolicies.DiscountCodes);

        app.MapGet("/api/discount-codes/{code}", async (string code, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetDiscountCodeStatusQuery(code), cancellationToken)))
            .WithTags("Discounts")
            .WithName("GetDiscountCodeStatus")
            .AllowAnonymous()
            .RequireRateLimiting(RateLimitPolicies.ReservationStatusChecks);

        app.MapPost("/api/restaurants/{id:guid}/events", async (Guid id, EventBody body, ISender sender, CancellationToken cancellationToken) =>
            {
                await sender.Send(new RecordRestaurantEventCommand(id, body.Type, body.DeviceId), cancellationToken);
                return Results.NoContent();
            })
            .WithTags("Discounts")
            .WithName("RecordRestaurantEvent")
            .AllowAnonymous()
            .RequireRateLimiting(RateLimitPolicies.RestaurantEvents);

        // The admin's numbers: how many customers HARA brought and how often restaurants are looked at.
        var admin = app.MapGroup("/api/admin/visits").WithTags("Admin.Visits").RequireAuthorization("Admin");

        admin.MapGet("/", async (ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetVisitsQuery(), cancellationToken)))
            .WithName("AdminGetVisits");

        admin.MapGet("/monthly", async (int? year, int? month, ISender sender, CancellationToken cancellationToken) =>
            {
                var now = DateTimeOffset.UtcNow.ToOffset(TimeSpan.FromHours(4));
                var y = year ?? now.Year;
                var m = month ?? now.Month;
                if (y is < 2020 or > 2100 || m is < 1 or > 12)
                {
                    return Results.BadRequest(new { title = "Invalid month." });
                }

                return Results.Ok(await sender.Send(new GetMonthlyVisitsQuery(y, m), cancellationToken));
            })
            .WithName("AdminGetMonthlyVisits");

        return app;
    }
}
