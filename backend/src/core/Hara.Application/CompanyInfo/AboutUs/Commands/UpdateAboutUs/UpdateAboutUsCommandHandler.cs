using Hara.Application.Common.Interfaces;
using Hara.Domain.CompanyInfo;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.CompanyInfo.AboutUs.Commands.UpdateAboutUs;

public class UpdateAboutUsCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<UpdateAboutUsCommand, AboutUsDto>
{
    public async Task<AboutUsDto> Handle(UpdateAboutUsCommand request, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<AboutUsContent>();
        var content = await repository.Query().FirstOrDefaultAsync(cancellationToken);

        if (content is null)
        {
            content = new AboutUsContent
            {
                CompanyName = request.CompanyName,
                Description = request.Description,
                LogoUrl = request.LogoUrl
            };
            await repository.AddAsync(content, cancellationToken);
        }
        else
        {
            content.CompanyName = request.CompanyName;
            content.Description = request.Description;
            content.LogoUrl = request.LogoUrl;
            repository.Update(content);
        }

        await unitOfWork.SaveChangesAsync(cancellationToken);

        return AboutUsDto.FromEntity(content);
    }
}
