using Hara.Application.Common.Interfaces;
using MediatR;

namespace Hara.Application.Auth.Commands.Logout;

public class LogoutCommandHandler(IIdentityService identityService) : IRequestHandler<LogoutCommand>
{
    public Task Handle(LogoutCommand request, CancellationToken cancellationToken) =>
        identityService.RevokeRefreshTokenAsync(request.RefreshToken, cancellationToken);
}
