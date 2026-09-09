using Hara.Application.Restaurants.Commands.CreateRestaurant;
using Hara.Application.Restaurants.Commands.DeleteRestaurant;
using Hara.Application.Restaurants.Commands.UpdateRestaurant;
using Hara.Application.Restaurants.Queries.GetRestaurantById;
using Hara.Application.Restaurants.Queries.GetRestaurants;
using MediatR;

namespace Hara.Api.Endpoints;

public static class RestaurantsEndpoints
{
    public static IEndpointRouteBuilder MapRestaurantsEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/api/restaurants", async (ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetRestaurantsQuery(OnlyActive: true), cancellationToken)))
            .WithTags("Restaurants")
            .WithName("GetActiveRestaurants")
            .AllowAnonymous();

        app.MapGet("/api/restaurants/{id:guid}", async (Guid id, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetRestaurantByIdQuery(id, OnlyActive: true), cancellationToken)))
            .WithTags("Restaurants")
            .WithName("GetActiveRestaurantById")
            .AllowAnonymous();

        var admin = app.MapGroup("/api/admin/restaurants")
            .WithTags("Admin.Restaurants")
            .RequireAuthorization("Admin");

        admin.MapGet("/", async (ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetRestaurantsQuery(OnlyActive: false), cancellationToken)))
            .WithName("AdminGetRestaurants");

        admin.MapGet("/{id:guid}", async (Guid id, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetRestaurantByIdQuery(id, OnlyActive: false), cancellationToken)))
            .WithName("AdminGetRestaurantById");

        admin.MapPost("/", async (CreateRestaurantCommand command, ISender sender, CancellationToken cancellationToken) =>
            {
                var result = await sender.Send(command, cancellationToken);
                return Results.CreatedAtRoute("AdminGetRestaurantById", new { id = result.Id }, result);
            })
            .WithName("AdminCreateRestaurant");

        admin.MapPut("/{id:guid}", async (Guid id, UpdateRestaurantBody body, ISender sender, CancellationToken cancellationToken) =>
            {
                var command = new UpdateRestaurantCommand(id, body.Name, body.Description, body.Address, body.PhoneNumber, body.ImageUrl, body.IsActive);
                return Results.Ok(await sender.Send(command, cancellationToken));
            })
            .WithName("AdminUpdateRestaurant");

        admin.MapDelete("/{id:guid}", async (Guid id, ISender sender, CancellationToken cancellationToken) =>
            {
                await sender.Send(new DeleteRestaurantCommand(id), cancellationToken);
                return Results.NoContent();
            })
            .WithName("AdminDeleteRestaurant");

        return app;
    }

    private sealed record UpdateRestaurantBody(string Name, string? Description, string Address, string? PhoneNumber, string? ImageUrl, bool IsActive);
}
