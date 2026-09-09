using Hara.Application.Common.Interfaces;
using Hara.Domain.CompanyInfo;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.CompanyInfo.Contacts.Queries.GetContactInfos;

public class GetContactInfosQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetContactInfosQuery, IReadOnlyList<ContactInfoDto>>
{
    public async Task<IReadOnlyList<ContactInfoDto>> Handle(GetContactInfosQuery request, CancellationToken cancellationToken)
    {
        var query = unitOfWork.Repository<ContactInfo>().Query();

        if (request.OnlyActive)
        {
            query = query.Where(c => c.IsActive);
        }

        var contacts = await query.OrderBy(c => c.SortOrder).ToListAsync(cancellationToken);

        return contacts.Select(ContactInfoDto.FromEntity).ToList();
    }
}
