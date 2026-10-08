using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Hara.Application.Common.Interfaces;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace Hara.Persistence.Identity;

/// <summary>
/// ASP.NET Core Identity-backed implementation of <see cref="IIdentityService"/>: registers accounts,
/// verifies credentials and issues JWT access tokens plus rotating refresh tokens. Uses
/// <see cref="UserManager{TUser}"/> directly rather than <c>SignInManager</c> — the latter needs an
/// <c>HttpContext</c> for cookie sign-in, which this stateless, JWT-only API never has.
/// </summary>
public class IdentityService(
    UserManager<ApplicationUser> userManager,
    RoleManager<IdentityRole<Guid>> roleManager,
    ApplicationDbContext dbContext,
    IOptions<JwtOptions> jwtOptions) : IIdentityService
{
    private readonly JwtOptions _jwtOptions = jwtOptions.Value;

    public async Task<AuthenticationResult> AuthenticateAsync(string email, string password, CancellationToken cancellationToken = default)
    {
        var user = await userManager.FindByEmailAsync(email);
        if (user is null)
        {
            return Failed;
        }

        if (await userManager.IsLockedOutAsync(user))
        {
            return Failed;
        }

        if (!await userManager.CheckPasswordAsync(user, password))
        {
            await userManager.AccessFailedAsync(user);
            return Failed;
        }

        await userManager.ResetAccessFailedCountAsync(user);

        return await IssueTokensAsync(user, cancellationToken);
    }

    public async Task<AuthenticationResult> RefreshAsync(string refreshToken, CancellationToken cancellationToken = default)
    {
        var hash = Hash(refreshToken);
        var stored = await dbContext.Set<RefreshToken>().FirstOrDefaultAsync(t => t.TokenHash == hash, cancellationToken);
        if (stored is null)
        {
            return Failed;
        }

        var now = DateTimeOffset.UtcNow;

        if (stored.RevokedAt is not null)
        {
            // A token that was already used shows up again: either a stolen copy or a replay. Sign every
            // device of this account out so neither the thief nor the owner keeps a working session.
            await RevokeAllAsync(stored.UserId, now, cancellationToken);
            return Failed;
        }

        if (stored.ExpiresAt <= now)
        {
            return Failed;
        }

        var user = await userManager.FindByIdAsync(stored.UserId.ToString());
        if (user is null || await userManager.IsLockedOutAsync(user))
        {
            return Failed;
        }

        stored.RevokedAt = now;

        return await IssueTokensAsync(user, cancellationToken);
    }

    public async Task RevokeRefreshTokenAsync(string refreshToken, CancellationToken cancellationToken = default)
    {
        var hash = Hash(refreshToken);
        var stored = await dbContext.Set<RefreshToken>().FirstOrDefaultAsync(t => t.TokenHash == hash && t.RevokedAt == null, cancellationToken);
        if (stored is null)
        {
            return;
        }

        stored.RevokedAt = DateTimeOffset.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<RegistrationResult> RegisterAsync(string email, string password, string role, CancellationToken cancellationToken = default)
    {
        if (!await roleManager.RoleExistsAsync(role))
        {
            await roleManager.CreateAsync(new IdentityRole<Guid>(role));
        }

        var user = new ApplicationUser { UserName = email, Email = email };
        var created = await userManager.CreateAsync(user, password);
        if (!created.Succeeded)
        {
            return new RegistrationResult(false, null, ToErrors(created));
        }

        var inRole = await userManager.AddToRoleAsync(user, role);
        if (!inRole.Succeeded)
        {
            await userManager.DeleteAsync(user);
            return new RegistrationResult(false, null, ToErrors(inRole));
        }

        return new RegistrationResult(true, user.Id, new Dictionary<string, string[]>());
    }

    public async Task DeleteUserAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var user = await userManager.FindByIdAsync(userId.ToString());
        if (user is not null)
        {
            await userManager.DeleteAsync(user);
        }
    }

    private static AuthenticationResult Failed => new(false, null, null);

    private async Task<AuthenticationResult> IssueTokensAsync(ApplicationUser user, CancellationToken cancellationToken)
    {
        var roles = (await userManager.GetRolesAsync(user)).ToList();
        var expiresAt = DateTimeOffset.UtcNow.AddMinutes(_jwtOptions.ExpiryMinutes);
        var accessToken = CreateAccessToken(user, roles, expiresAt);

        var refreshToken = NewRefreshTokenValue();
        var now = DateTimeOffset.UtcNow;
        dbContext.Set<RefreshToken>().Add(new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            TokenHash = Hash(refreshToken),
            CreatedAt = now,
            ExpiresAt = now.AddDays(_jwtOptions.RefreshTokenDays),
        });

        // Sessions that ended long ago only take up space.
        var stale = await dbContext.Set<RefreshToken>()
            .Where(t => t.UserId == user.Id && t.ExpiresAt < now.AddDays(-30))
            .ToListAsync(cancellationToken);
        dbContext.Set<RefreshToken>().RemoveRange(stale);

        await dbContext.SaveChangesAsync(cancellationToken);

        return new AuthenticationResult(true, accessToken, expiresAt, refreshToken, user.Id, roles);
    }

    private async Task RevokeAllAsync(Guid userId, DateTimeOffset now, CancellationToken cancellationToken)
    {
        var active = await dbContext.Set<RefreshToken>().Where(t => t.UserId == userId && t.RevokedAt == null).ToListAsync(cancellationToken);
        foreach (var token in active)
        {
            token.RevokedAt = now;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private string CreateAccessToken(ApplicationUser user, IEnumerable<string> roles, DateTimeOffset expiresAt)
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

    private static string NewRefreshTokenValue() =>
        Convert.ToBase64String(RandomNumberGenerator.GetBytes(32)).Replace('+', '-').Replace('/', '_').TrimEnd('=');

    private static string Hash(string refreshToken) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(refreshToken)));

    private static Dictionary<string, string[]> ToErrors(IdentityResult result) =>
        result.Errors
            .GroupBy(error => error.Code.Contains("Password", StringComparison.Ordinal) ? "password" : "email")
            .ToDictionary(group => group.Key, group => group.Select(error => error.Description).ToArray());
}
