using Hara.Application.Advertisements.Commands.CreateAdvertisement;
using Hara.Application.Advertisements.Commands.DeleteAdvertisement;
using Hara.Application.Advertisements.Commands.ReorderAdvertisements;
using Hara.Application.Advertisements.Commands.UpdateAdvertisement;
using Hara.Application.Advertisements.Queries.GetAdvertisements;
using MediatR;

namespace Hara.Api.Endpoints;

public static class AdvertisementsEndpoints
{
    public static IEndpointRouteBuilder MapAdvertisementsEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/api/advertisements", async (ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetAdvertisementsQuery(OnlyActive: true), cancellationToken)))
            .WithTags("Advertisements")
            .WithName("GetActiveAdvertisements")
            .AllowAnonymous();

        var admin = app.MapGroup("/api/admin/advertisements")
            .WithTags("Admin.Advertisements")
            .RequireAuthorization("Admin");

        admin.MapGet("/", async (ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetAdvertisementsQuery(OnlyActive: false), cancellationToken)))
            .WithName("AdminGetAdvertisements");

        admin.MapPost("/", async (CreateAdvertisementCommand command, ISender sender, CancellationToken cancellationToken) =>
            {
                var result = await sender.Send(command, cancellationToken);
                return Results.Created((string?)null, result);
            })
            .WithName("AdminCreateAdvertisement");

        admin.MapPut("/{id:guid}", async (Guid id, UpdateAdvertisementBody body, ISender sender, CancellationToken cancellationToken) =>
            {
                var command = new UpdateAdvertisementCommand(id, body.Title, body.ImageUrl, body.LinkUrl, body.SortOrder, body.IsActive);
                return Results.Ok(await sender.Send(command, cancellationToken));
            })
            .WithName("AdminUpdateAdvertisement");

        admin.MapDelete("/{id:guid}", async (Guid id, ISender sender, CancellationToken cancellationToken) =>
            {
                await sender.Send(new DeleteAdvertisementCommand(id), cancellationToken);
                return Results.NoContent();
            })
            .WithName("AdminDeleteAdvertisement");

        admin.MapPatch("/reorder", async (ReorderAdvertisementCommand command, ISender sender, CancellationToken cancellationToken) =>
            {
                await sender.Send(command, cancellationToken);
                return Results.NoContent();
            })
            .WithName("AdminReorderAdvertisements");

        return app;
    }

    private sealed record UpdateAdvertisementBody(string? Title, string ImageUrl, string? LinkUrl, int SortOrder, bool IsActive);
}
