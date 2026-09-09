using MediatR;

namespace Hara.Application.CompanyInfo.AboutUs.Queries.GetAboutUs;

/// <summary>Fetches the current "About Us" content. Used by both the public and admin endpoints — there's nothing to authorize differently since it's all-or-nothing content.</summary>
public sealed record GetAboutUsQuery : IRequest<AboutUsDto>;
