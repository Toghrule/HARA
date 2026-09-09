using Microsoft.AspNetCore.Identity;

namespace Hara.Persistence.Identity;

/// <summary>
/// An admin panel user. There is no mobile app account concept — only
/// admins authenticate, via <see cref="Hara.Application.Common.Interfaces.IIdentityService"/>.
/// </summary>
public class ApplicationUser : IdentityUser<Guid>
{
}
