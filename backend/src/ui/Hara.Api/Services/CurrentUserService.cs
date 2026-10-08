using System.Security.Claims;
using Hara.Application.Common.Interfaces;

namespace Hara.Api.Services;

/// <summary>Reads the signed-in account's id from the request's access token.</summary>
public class CurrentUserService(IHttpContextAccessor httpContextAccessor) : ICurrentUserService
{
    public Guid? UserId
    {
        get
        {
            var user = httpContextAccessor.HttpContext?.User;
            var value = user?.FindFirstValue(ClaimTypes.NameIdentifier) ?? user?.FindFirstValue("sub");

            return Guid.TryParse(value, out var id) ? id : null;
        }
    }
}
