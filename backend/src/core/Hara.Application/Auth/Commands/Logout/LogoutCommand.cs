using MediatR;

namespace Hara.Application.Auth.Commands.Logout;

/// <summary>Signs out of this device by revoking its refresh token.</summary>
public sealed record LogoutCommand(string RefreshToken) : IRequest;
