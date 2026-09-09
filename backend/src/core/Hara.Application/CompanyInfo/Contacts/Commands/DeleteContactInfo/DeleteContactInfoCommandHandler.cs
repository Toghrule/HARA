using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.CompanyInfo;
using MediatR;

namespace Hara.Application.CompanyInfo.Contacts.Commands.DeleteContactInfo;

public class DeleteContactInfoCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<DeleteContactInfoCommand>
{
    public async Task Handle(DeleteContactInfoCommand request, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<ContactInfo>();
        var contact = await repository.GetByIdAsync(request.Id, cancellationToken)
            ?? throw new NotFoundException(nameof(ContactInfo), request.Id);

        repository.Remove(contact);
        await unitOfWork.SaveChangesAsync(cancellationToken);
    }
}
