using Hara.Application.Restaurants.Submissions.Commands.CreateSubmission;
using Hara.Application.Restaurants.Submissions.Commands.DeleteSubmission;
using Hara.Application.Restaurants.Submissions.Commands.ReviewSubmission;
using Hara.Application.Restaurants.Submissions.Queries.GetSubmissionById;
using Hara.Application.Restaurants.Submissions.Queries.GetSubmissions;
using Hara.Domain.Restaurants;
using MediatR;

namespace Hara.Api.Endpoints;

public static class SubmissionsEndpoints
{
    public static IEndpointRouteBuilder MapSubmissionsEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapPost("/api/submissions", async (CreateSubmissionCommand command, ISender sender, CancellationToken cancellationToken) =>
            {
                var result = await sender.Send(command, cancellationToken);
                return Results.Created((string?)null, result);
            })
            .WithTags("Submissions")
            .WithName("CreateSubmission")
            .AllowAnonymous();

        var admin = app.MapGroup("/api/admin/submissions")
            .WithTags("Admin.Submissions")
            .RequireAuthorization("Admin");

        admin.MapGet("/", async (SubmissionStatus? status, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetSubmissionsQuery(status), cancellationToken)))
            .WithName("AdminGetSubmissions");

        admin.MapGet("/{id:guid}", async (Guid id, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetSubmissionByIdQuery(id), cancellationToken)))
            .WithName("AdminGetSubmissionById");

        admin.MapPatch("/{id:guid}/status", async (Guid id, ReviewSubmissionBody body, ISender sender, CancellationToken cancellationToken) =>
            {
                var command = new ReviewSubmissionCommand(id, body.Decision, body.AdminNote);
                return Results.Ok(await sender.Send(command, cancellationToken));
            })
            .WithName("AdminReviewSubmission");

        admin.MapDelete("/{id:guid}", async (Guid id, ISender sender, CancellationToken cancellationToken) =>
            {
                await sender.Send(new DeleteSubmissionCommand(id), cancellationToken);
                return Results.NoContent();
            })
            .WithName("AdminDeleteSubmission");

        return app;
    }

    private sealed record ReviewSubmissionBody(SubmissionStatus Decision, string? AdminNote);
}
