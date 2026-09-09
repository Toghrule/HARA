using Hara.Domain.CompanyInfo;
using MediatR;

namespace Hara.Application.CompanyInfo.Contacts.Commands.UpdateContactInfo;

/// <summary>Admin command to update an existing "Contact Us" entry, including its visibility.</summary>
public sealed record UpdateContactInfoCommand(Guid Id, ContactType Type, string Value, string? Label, int SortOrder, bool IsActive) : IRequest<ContactInfoDto>;
