using MediatR;

namespace Hara.Application.CompanyInfo.Contacts.Commands.DeleteContactInfo;

/// <summary>Admin command to remove a "Contact Us" entry.</summary>
public sealed record DeleteContactInfoCommand(Guid Id) : IRequest;
