namespace Hara.Application.Common.Interfaces;

/// <summary>Who is making the current request, so handlers can scope what they do to that person.</summary>
public interface ICurrentUserService
{
    /// <summary>The signed-in account's id, or <c>null</c> for an anonymous request.</summary>
    Guid? UserId { get; }
}
