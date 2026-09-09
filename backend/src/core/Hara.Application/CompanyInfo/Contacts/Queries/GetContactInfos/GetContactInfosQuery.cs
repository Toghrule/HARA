using MediatR;

namespace Hara.Application.CompanyInfo.Contacts.Queries.GetContactInfos;

/// <summary>Lists "Contact Us" entries ordered for display. The public endpoint passes <paramref name="OnlyActive"/> = <c>true</c>; the admin endpoint passes <c>false</c>.</summary>
public sealed record GetContactInfosQuery(bool OnlyActive) : IRequest<IReadOnlyList<ContactInfoDto>>;
