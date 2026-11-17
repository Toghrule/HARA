using Hara.Api.RateLimiting;
using Hara.Application.Customers;
using Hara.Application.Reviews;
using MediatR;

namespace Hara.Api.Endpoints;

public sealed record GoogleSignInBody(string IdToken);

public sealed record ReviewBody(int Stars, string? Text);

/// <summary>
/// The customer's side of accounts and reviews: sign in with Google, see and delete one's account, read a restaurant's reviews (open to
/// everyone), write, change or take back one's own review (needs the Customer sign-in), and the admin's way to read and remove reviews.
/// </summary>
public static class CustomerEndpoints
{
    public static IEndpointRouteBuilder MapCustomerEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapPost("/api/auth/google", async (GoogleSignInBody body, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new SignInWithGoogleCommand(body.IdToken), cancellationToken)))
            .WithTags("Customer")
            .WithName("SignInWithGoogle")
            .AllowAnonymous()
            .RequireRateLimiting(RateLimitPolicies.Login);

        var customer = app.MapGroup("/api/customer").WithTags("Customer").RequireAuthorization("Customer");

        customer.MapGet("/me", async (ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetCustomerQuery(), cancellationToken)))
            .WithName("GetCustomer");

        customer.MapDelete("/", async (ISender sender, CancellationToken cancellationToken) =>
            {
                await sender.Send(new DeleteCustomerAccountCommand(), cancellationToken);
                return Results.NoContent();
            })
            .WithName("DeleteCustomerAccount");

        app.MapGet("/api/restaurants/{id:guid}/reviews", async (Guid id, int? page, int? pageSize, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetReviewsQuery(id, page ?? 1, pageSize ?? 20), cancellationToken)))
            .WithTags("Reviews")
            .WithName("GetReviews")
            .AllowAnonymous();

        customer.MapGet("/reviews/{restaurantId:guid}", async (Guid restaurantId, ISender sender, CancellationToken cancellationToken) =>
            {
                var mine = await sender.Send(new GetMyReviewQuery(restaurantId), cancellationToken);
                return mine is null ? Results.NoContent() : Results.Ok(mine);
            })
            .WithName("GetMyReview");

        customer.MapPut("/reviews/{restaurantId:guid}", async (Guid restaurantId, ReviewBody body, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new SaveMyReviewCommand(restaurantId, body.Stars, body.Text), cancellationToken)))
            .WithName("SaveMyReview")
            .RequireRateLimiting(RateLimitPolicies.Reviews);

        customer.MapDelete("/reviews/{restaurantId:guid}", async (Guid restaurantId, ISender sender, CancellationToken cancellationToken) =>
            {
                await sender.Send(new DeleteMyReviewCommand(restaurantId), cancellationToken);
                return Results.NoContent();
            })
            .WithName("DeleteMyReview");

        var admin = app.MapGroup("/api/admin/reviews").WithTags("Admin.Reviews").RequireAuthorization("Admin");

        admin.MapGet("/", async (int? page, int? pageSize, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetAdminReviewsQuery(page ?? 1, pageSize ?? 50), cancellationToken)))
            .WithName("AdminGetReviews");

        admin.MapDelete("/{id:guid}", async (Guid id, ISender sender, CancellationToken cancellationToken) =>
            {
                await sender.Send(new DeleteReviewAsAdminCommand(id), cancellationToken);
                return Results.NoContent();
            })
            .WithName("AdminDeleteReview");

        return app;
    }
}
