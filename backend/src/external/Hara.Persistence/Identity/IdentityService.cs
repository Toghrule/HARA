using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Hara.Application.Common.Interfaces;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace Hara.Persistence.Identity;

/// <summary>
/// ASP.NET Core Identity-backed implementation of <see cref="IIdentityService"/>: verifies admin
/// credentials and issues JWT bearer tokens. Uses <see cref="UserManager{TUser}"/> directly rather
/// than <c>SignInManager</c> — the latter needs an <c>HttpContext</c> for cookie sign-in, which this
/// stateless, JWT-only API never has.
/// </summary>
public class IdentityService(
    UserManager<ApplicationUser> userManager,
    IOptions<JwtOptions> jwtOptions) : IIdentityService
{
    private readonly JwtOptions _jwtOptions = jwtOptions.Value;

    public async Task<AuthenticationResult> AuthenticateAsync(string email, string password, CancellationToken cancellationToken = default)
    {
        var user = await userManager.FindByEmailAsync(email);
        if (user is null)
        {
            return new AuthenticationResult(false, null, null);
        }

        if (await userManager.IsLockedOutAsync(user))
        {
            return new AuthenticationResult(false, null, null);
        }

        if (!await userManager.CheckPasswordAsync(user, password))
        {
            await userManager.AccessFailedAsync(user);
            return new AuthenticationResult(false, null, null);
        }

        await userManager.ResetAccessFailedCountAsync(user);

        var roles = await userManager.GetRolesAsync(user);
        var expiresAt = DateTimeOffset.UtcNow.AddMinutes(_jwtOptions.ExpiryMinutes);
        var token = CreateToken(user, roles, expiresAt);

        return new AuthenticationResult(true, token, expiresAt);
    }

    private string CreateToken(ApplicationUser user, IEnumerable<string> roles, DateTimeOffset expiresAt)
    {
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };
        claims.AddRange(roles.Select(role => new Claim(ClaimTypes.Role, role)));

        var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtOptions.SigningKey));
        var credentials = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _jwtOptions.Issuer,
            audience: _jwtOptions.Audience,
            claims: claims,
            expires: expiresAt.UtcDateTime,
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
