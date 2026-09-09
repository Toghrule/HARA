using Hara.Application.Faq.Commands.CreateFaqItem;
using Hara.Application.Faq.Commands.DeleteFaqItem;
using Hara.Application.Faq.Commands.ReorderFaqItems;
using Hara.Application.Faq.Commands.UpdateFaqItem;
using Hara.Application.Faq.Queries.GetFaqItems;
using MediatR;

namespace Hara.Api.Endpoints;

public static class FaqEndpoints
{
    public static IEndpointRouteBuilder MapFaqEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/api/faq", async (ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetFaqItemsQuery(OnlyActive: true), cancellationToken)))
            .WithTags("Faq")
            .WithName("GetActiveFaqItems")
            .AllowAnonymous();

        var admin = app.MapGroup("/api/admin/faq")
            .WithTags("Admin.Faq")
            .RequireAuthorization("Admin");

        admin.MapGet("/", async (ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetFaqItemsQuery(OnlyActive: false), cancellationToken)))
            .WithName("AdminGetFaqItems");

        admin.MapPost("/", async (CreateFaqItemCommand command, ISender sender, CancellationToken cancellationToken) =>
            {
                var result = await sender.Send(command, cancellationToken);
                return Results.Created((string?)null, result);
            })
            .WithName("AdminCreateFaqItem");

        admin.MapPut("/{id:guid}", async (Guid id, UpdateFaqItemBody body, ISender sender, CancellationToken cancellationToken) =>
            {
                var command = new UpdateFaqItemCommand(id, body.Question, body.Answer, body.SortOrder, body.IsActive);
                return Results.Ok(await sender.Send(command, cancellationToken));
            })
            .WithName("AdminUpdateFaqItem");

        admin.MapDelete("/{id:guid}", async (Guid id, ISender sender, CancellationToken cancellationToken) =>
            {
                await sender.Send(new DeleteFaqItemCommand(id), cancellationToken);
                return Results.NoContent();
            })
            .WithName("AdminDeleteFaqItem");

        admin.MapPatch("/reorder", async (ReorderFaqItemsCommand command, ISender sender, CancellationToken cancellationToken) =>
            {
                await sender.Send(command, cancellationToken);
                return Results.NoContent();
            })
            .WithName("AdminReorderFaqItems");

        return app;
    }

    private sealed record UpdateFaqItemBody(string Question, string Answer, int SortOrder, bool IsActive);
}
