using Hara.Application.CompanyInfo.AboutUs.Commands.UpdateAboutUs;
using Hara.Application.CompanyInfo.AboutUs.Queries.GetAboutUs;
using Hara.Application.CompanyInfo.Contacts.Commands.CreateContactInfo;
using Hara.Application.CompanyInfo.Contacts.Commands.DeleteContactInfo;
using Hara.Application.CompanyInfo.Contacts.Commands.UpdateContactInfo;
using Hara.Application.CompanyInfo.Contacts.Queries.GetContactInfos;
using Hara.Application.CompanyInfo.SocialLinks.Commands.CreateSocialMediaLink;
using Hara.Application.CompanyInfo.SocialLinks.Commands.DeleteSocialMediaLink;
using Hara.Application.CompanyInfo.SocialLinks.Commands.UpdateSocialMediaLink;
using Hara.Application.CompanyInfo.SocialLinks.Queries.GetSocialMediaLinks;
using Hara.Domain.CompanyInfo;
using MediatR;

namespace Hara.Api.Endpoints;

public static class CompanyInfoEndpoints
{
    public static IEndpointRouteBuilder MapCompanyInfoEndpoints(this IEndpointRouteBuilder app)
    {
        MapPublic(app);
        MapAdminAboutUs(app);
        MapAdminSocialLinks(app);
        MapAdminContacts(app);

        return app;
    }

    private static void MapPublic(IEndpointRouteBuilder app)
    {
        app.MapGet("/api/company-info/about", async (ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetAboutUsQuery(), cancellationToken)))
            .WithTags("CompanyInfo")
            .WithName("GetAboutUs")
            .AllowAnonymous();

        app.MapGet("/api/company-info/social-links", async (ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetSocialMediaLinksQuery(OnlyActive: true), cancellationToken)))
            .WithTags("CompanyInfo")
            .WithName("GetActiveSocialMediaLinks")
            .AllowAnonymous();

        app.MapGet("/api/company-info/contacts", async (ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetContactInfosQuery(OnlyActive: true), cancellationToken)))
            .WithTags("CompanyInfo")
            .WithName("GetActiveContactInfos")
            .AllowAnonymous();
    }

    private static void MapAdminAboutUs(IEndpointRouteBuilder app)
    {
        var admin = app.MapGroup("/api/admin/company-info/about")
            .WithTags("Admin.CompanyInfo")
            .RequireAuthorization("Admin");

        admin.MapGet("/", async (ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetAboutUsQuery(), cancellationToken)))
            .WithName("AdminGetAboutUs");

        admin.MapPut("/", async (UpdateAboutUsCommand command, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(command, cancellationToken)))
            .WithName("AdminUpdateAboutUs");
    }

    private static void MapAdminSocialLinks(IEndpointRouteBuilder app)
    {
        var admin = app.MapGroup("/api/admin/company-info/social-links")
            .WithTags("Admin.CompanyInfo")
            .RequireAuthorization("Admin");

        admin.MapGet("/", async (ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetSocialMediaLinksQuery(OnlyActive: false), cancellationToken)))
            .WithName("AdminGetSocialMediaLinks");

        admin.MapPost("/", async (CreateSocialMediaLinkCommand command, ISender sender, CancellationToken cancellationToken) =>
            {
                var result = await sender.Send(command, cancellationToken);
                return Results.Created((string?)null, result);
            })
            .WithName("AdminCreateSocialMediaLink");

        admin.MapPut("/{id:guid}", async (Guid id, UpdateSocialMediaLinkBody body, ISender sender, CancellationToken cancellationToken) =>
            {
                var command = new UpdateSocialMediaLinkCommand(id, body.Platform, body.Url, body.SortOrder, body.IsActive);
                return Results.Ok(await sender.Send(command, cancellationToken));
            })
            .WithName("AdminUpdateSocialMediaLink");

        admin.MapDelete("/{id:guid}", async (Guid id, ISender sender, CancellationToken cancellationToken) =>
            {
                await sender.Send(new DeleteSocialMediaLinkCommand(id), cancellationToken);
                return Results.NoContent();
            })
            .WithName("AdminDeleteSocialMediaLink");
    }

    private static void MapAdminContacts(IEndpointRouteBuilder app)
    {
        var admin = app.MapGroup("/api/admin/company-info/contacts")
            .WithTags("Admin.CompanyInfo")
            .RequireAuthorization("Admin");

        admin.MapGet("/", async (ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetContactInfosQuery(OnlyActive: false), cancellationToken)))
            .WithName("AdminGetContactInfos");

        admin.MapPost("/", async (CreateContactInfoCommand command, ISender sender, CancellationToken cancellationToken) =>
            {
                var result = await sender.Send(command, cancellationToken);
                return Results.Created((string?)null, result);
            })
            .WithName("AdminCreateContactInfo");

        admin.MapPut("/{id:guid}", async (Guid id, UpdateContactInfoBody body, ISender sender, CancellationToken cancellationToken) =>
            {
                var command = new UpdateContactInfoCommand(id, body.Type, body.Value, body.Label, body.SortOrder, body.IsActive);
                return Results.Ok(await sender.Send(command, cancellationToken));
            })
            .WithName("AdminUpdateContactInfo");

        admin.MapDelete("/{id:guid}", async (Guid id, ISender sender, CancellationToken cancellationToken) =>
            {
                await sender.Send(new DeleteContactInfoCommand(id), cancellationToken);
                return Results.NoContent();
            })
            .WithName("AdminDeleteContactInfo");
    }

    private sealed record UpdateSocialMediaLinkBody(SocialMediaPlatform Platform, string Url, int SortOrder, bool IsActive);

    private sealed record UpdateContactInfoBody(ContactType Type, string Value, string? Label, int SortOrder, bool IsActive);
}
