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

        if (content is null)
        {
            return AboutUsDto.Empty;
        }

        var dto = AboutUsDto.FromEntity(content);
        return request.Language is null ? dto : dto.Localize(request.Language);
    }
}
