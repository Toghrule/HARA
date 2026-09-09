using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.CompanyInfo;
using MediatR;

namespace Hara.Application.CompanyInfo.Contacts.Commands.UpdateContactInfo;

public class UpdateContactInfoCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<UpdateContactInfoCommand, ContactInfoDto>
{
    public async Task<ContactInfoDto> Handle(UpdateContactInfoCommand request, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<ContactInfo>();
        var contact = await repository.GetByIdAsync(request.Id, cancellationToken)
            ?? throw new NotFoundException(nameof(ContactInfo), request.Id);

        contact.Type = request.Type;
        contact.Value = request.Value;
        contact.Label = request.Label;
        contact.SortOrder = request.SortOrder;
        contact.IsActive = request.IsActive;

        repository.Update(contact);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return ContactInfoDto.FromEntity(contact);
    }
}
