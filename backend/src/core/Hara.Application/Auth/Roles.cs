namespace Hara.Application.Auth;

/// <summary>The role names carried in access tokens. Must match the roles the identity store creates.</summary>
public static class Roles
{
    public const string Admin = "Admin";
    public const string Owner = "Owner";
    public const string Staff = "Staff";
}
