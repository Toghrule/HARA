using Hara.Application.Common.Interfaces;
using Hara.Domain.Faq;
using MediatR;

namespace Hara.Application.Faq.Commands.CreateFaqItem;

public class CreateFaqItemCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<CreateFaqItemCommand, FaqItemDto>
{
    public async Task<FaqItemDto> Handle(CreateFaqItemCommand request, CancellationToken cancellationToken)
    {
        var faqItem = new FaqItem
        {
            Question = request.Question,
            Answer = request.Answer,
            SortOrder = request.SortOrder,
            IsActive = true
        };

        await unitOfWork.Repository<FaqItem>().AddAsync(faqItem, cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return FaqItemDto.FromEntity(faqItem);
    }
}
