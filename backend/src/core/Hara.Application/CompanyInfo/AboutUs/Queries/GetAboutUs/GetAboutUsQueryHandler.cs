using Hara.Application.Common.Interfaces;
using Hara.Domain.CompanyInfo;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.CompanyInfo.AboutUs.Queries.GetAboutUs;

public class GetAboutUsQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetAboutUsQuery, AboutUsDto>
{
    public async Task<AboutUsDto> Handle(GetAboutUsQuery request, CancellationToken cancellationToken)
    {
        var content = await unitOfWork.Repository<AboutUsContent>().Query().FirstOrDefaultAsync(cancellationToken);

        return content is null ? AboutUsDto.Empty : AboutUsDto.FromEntity(content);
    }
}
