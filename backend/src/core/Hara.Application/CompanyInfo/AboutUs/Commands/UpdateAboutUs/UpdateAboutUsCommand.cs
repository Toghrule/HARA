using MediatR;

namespace Hara.Application.CompanyInfo.AboutUs.Commands.UpdateAboutUs;

/// <summary>
/// Admin command that creates or replaces the (single) "About Us" content.
/// There's no separate create/delete for this — it behaves as an upsert
/// because the mobile app always shows exactly one about-us page.
/// </summary>
public sealed record UpdateAboutUsCommand(string CompanyName, string Description, string? LogoUrl) : IRequest<AboutUsDto>;
