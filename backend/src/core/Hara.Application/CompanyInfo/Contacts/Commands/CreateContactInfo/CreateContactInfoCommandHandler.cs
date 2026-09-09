using Hara.Application.Common.Interfaces;
using Hara.Domain.CompanyInfo;
using MediatR;

namespace Hara.Application.CompanyInfo.Contacts.Commands.CreateContactInfo;

public class CreateContactInfoCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<CreateContactInfoCommand, ContactInfoDto>
{
    public async Task<ContactInfoDto> Handle(CreateContactInfoCommand request, CancellationToken cancellationToken)
    {
        var contact = new ContactInfo
        {
            Type = request.Type,
            Value = request.Value,
            Label = request.Label,
            SortOrder = request.SortOrder
        };

        await unitOfWork.Repository<ContactInfo>().AddAsync(contact, cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return ContactInfoDto.FromEntity(contact);
    }
}
