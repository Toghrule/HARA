using Hara.Application.Common.Interfaces;
using Hara.Domain.CompanyInfo;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.CompanyInfo.SocialLinks.Queries.GetSocialMediaLinks;

public class GetSocialMediaLinksQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetSocialMediaLinksQuery, IReadOnlyList<SocialMediaLinkDto>>
{
    public async Task<IReadOnlyList<SocialMediaLinkDto>> Handle(GetSocialMediaLinksQuery request, CancellationToken cancellationToken)
    {
        var query = unitOfWork.Repository<SocialMediaLink>().Query();

        if (request.OnlyActive)
        {
            query = query.Where(s => s.IsActive);
        }

        var links = await query.OrderBy(s => s.SortOrder).ToListAsync(cancellationToken);

        return links.Select(SocialMediaLinkDto.FromEntity).ToList();
    }
}
