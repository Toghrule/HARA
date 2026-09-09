using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Faq;
using MediatR;

namespace Hara.Application.Faq.Commands.UpdateFaqItem;

public class UpdateFaqItemCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<UpdateFaqItemCommand, FaqItemDto>
{
    public async Task<FaqItemDto> Handle(UpdateFaqItemCommand request, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<FaqItem>();
        var faqItem = await repository.GetByIdAsync(request.Id, cancellationToken)
            ?? throw new NotFoundException(nameof(FaqItem), request.Id);

        faqItem.Question = request.Question;
        faqItem.Answer = request.Answer;
        faqItem.SortOrder = request.SortOrder;
        faqItem.IsActive = request.IsActive;

        repository.Update(faqItem);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return FaqItemDto.FromEntity(faqItem);
    }
}
