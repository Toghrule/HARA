using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Faq;
using MediatR;

namespace Hara.Application.Faq.Commands.DeleteFaqItem;

public class DeleteFaqItemCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<DeleteFaqItemCommand>
{
    public async Task Handle(DeleteFaqItemCommand request, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<FaqItem>();
        var faqItem = await repository.GetByIdAsync(request.Id, cancellationToken)
            ?? throw new NotFoundException(nameof(FaqItem), request.Id);

        repository.Remove(faqItem);
        await unitOfWork.SaveChangesAsync(cancellationToken);
    }
}
