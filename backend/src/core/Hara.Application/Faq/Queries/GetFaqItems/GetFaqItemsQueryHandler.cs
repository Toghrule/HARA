using Hara.Application.Common.Interfaces;
using Hara.Domain.Faq;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Faq.Queries.GetFaqItems;

public class GetFaqItemsQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetFaqItemsQuery, IReadOnlyList<FaqItemDto>>
{
    public async Task<IReadOnlyList<FaqItemDto>> Handle(GetFaqItemsQuery request, CancellationToken cancellationToken)
    {
        var query = unitOfWork.Repository<FaqItem>().Query();

        if (request.OnlyActive)
        {
            query = query.Where(f => f.IsActive);
        }

        var faqItems = await query.OrderBy(f => f.SortOrder).ToListAsync(cancellationToken);

        return faqItems.Select(FaqItemDto.FromEntity).ToList();
    }
}
