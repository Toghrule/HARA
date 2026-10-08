using Hara.Application.Auth.Commands.Login;
using MediatR;

namespace Hara.Application.Auth.Commands.RefreshToken;

/// <summary>Trades a refresh token for a new access token (and a new refresh token), so the app stays signed in without asking for the password again.</summary>
public sealed record RefreshTokenCommand(string RefreshToken) : IRequest<LoginResult>;
