using Hara.Application.Common.Interfaces;
using Hara.Domain.Faq;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Faq.Commands.ReorderFaqItems;

public class ReorderFaqItemsCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<ReorderFaqItemsCommand>
{
    public async Task Handle(ReorderFaqItemsCommand request, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<FaqItem>();
        var faqItems = await repository.Query()
            .Where(f => request.OrderedIds.Contains(f.Id))
            .ToListAsync(cancellationToken);

        for (var i = 0; i < request.OrderedIds.Count; i++)
        {
            var faqItem = faqItems.FirstOrDefault(f => f.Id == request.OrderedIds[i]);
            if (faqItem is null)
            {
                continue;
            }

            faqItem.SortOrder = i;
            repository.Update(faqItem);
        }

        await unitOfWork.SaveChangesAsync(cancellationToken);
    }
}
