using Hara.Domain.Common;
using Hara.Domain.Restaurants;

namespace Hara.Domain.Members;

/// <summary>What a person does at a restaurant.</summary>
public enum MemberRole
{
    /// <summary>Runs the restaurant's account: confirms customer codes and approves the waiters.</summary>
    Owner = 0,

    /// <summary>A waiter or cashier: confirms customer codes.</summary>
    Staff = 1
}

/// <summary>Whether a <see cref="RestaurantMember"/> may act for the restaurant yet.</summary>
public enum MemberStatus
{
    /// <summary>Signed up and waiting for the restaurant's owner to approve. Can sign in but can't do anything for the restaurant.</summary>
    Pending = 0,

    /// <summary>Approved: may confirm customer codes for the restaurant.</summary>
    Approved = 1,

    /// <summary>Declined by the owner. Kept so the person is told, instead of just failing to sign in.</summary>
    Rejected = 2
}

/// <summary>
/// An account that works at a <see cref="Restaurant"/>. The sign-in itself (email, password, tokens) lives in
/// ASP.NET Core Identity; this row says which restaurant the account belongs to and in what role. An owner
/// gets one when the admin creates their restaurant from their registration; a waiter gets one, pending,
/// when they register for a restaurant.
/// </summary>
public class RestaurantMember : BaseAuditableEntity
{
    /// <summary>The Identity account. One account belongs to at most one restaurant.</summary>
    public Guid UserId { get; set; }

    /// <summary>The restaurant this person works at.</summary>
    public Guid RestaurantId { get; set; }

    /// <summary>The restaurant this person works at.</summary>
    public Restaurant? Restaurant { get; set; }

    public MemberRole Role { get; set; }

    public MemberStatus Status { get; set; }

    /// <summary>The person's name, so an owner knows who is asking to join.</summary>
    public string FullName { get; set; } = string.Empty;

    /// <summary>A copy of the sign-in email, shown to the owner when reviewing a waiter.</summary>
    public string Email { get; set; } = string.Empty;

    /// <summary>Optional contact phone number.</summary>
    public string? PhoneNumber { get; set; }
}
