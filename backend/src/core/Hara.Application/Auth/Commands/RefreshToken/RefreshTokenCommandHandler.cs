using Hara.Application.Auth.Commands.Login;
using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using MediatR;

namespace Hara.Application.Auth.Commands.RefreshToken;

public class RefreshTokenCommandHandler(IIdentityService identityService) : IRequestHandler<RefreshTokenCommand, LoginResult>
{
    public async Task<LoginResult> Handle(RefreshTokenCommand request, CancellationToken cancellationToken)
    {
        var result = await identityService.RefreshAsync(request.RefreshToken, cancellationToken);

        if (!result.Succeeded)
        {
            throw new AuthenticationFailedException();
        }

        return new LoginResult(result.Token!, result.ExpiresAtUtc!.Value, result.RefreshToken, result.Roles);
    }
}
