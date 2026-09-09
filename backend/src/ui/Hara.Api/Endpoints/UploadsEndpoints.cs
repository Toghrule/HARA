using Hara.Application.Uploads.Commands.UploadImage;
using MediatR;

namespace Hara.Api.Endpoints;

public static class UploadsEndpoints
{
    public static IEndpointRouteBuilder MapUploadsEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapPost("/api/admin/uploads/{category}", async (string category, IFormFile file, ISender sender, CancellationToken cancellationToken) =>
            {
                await using var stream = file.OpenReadStream();
                var command = new UploadImageCommand(stream, file.FileName, file.ContentType, category);
                var result = await sender.Send(command, cancellationToken);
                return Results.Ok(result);
            })
            .WithTags("Admin.Uploads")
            .WithName("AdminUploadImage")
            .DisableAntiforgery()
            .RequireAuthorization("Admin");

        return app;
    }
}
