using Hara.Domain.CompanyInfo;
using MediatR;

namespace Hara.Application.CompanyInfo.Contacts.Commands.CreateContactInfo;

/// <summary>Admin command to add a "Contact Us" entry (a phone number or an email address).</summary>
public sealed record CreateContactInfoCommand(ContactType Type, string Value, string? Label, int SortOrder) : IRequest<ContactInfoDto>;
