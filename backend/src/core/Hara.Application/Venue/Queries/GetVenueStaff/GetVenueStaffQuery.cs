using MediatR;

namespace Hara.Application.Venue.Queries.GetVenueStaff;

/// <summary>The owner's team screen: everyone who works at the owner's restaurant or has asked to, waiting requests first.</summary>
public sealed record GetVenueStaffQuery : IRequest<IReadOnlyList<StaffMemberDto>>;
