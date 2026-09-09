using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using MediatR;

namespace Hara.Application.Auth.Commands.Login;

public class LoginCommandHandler(IIdentityService identityService) : IRequestHandler<LoginCommand, LoginResult>
{
    public async Task<LoginResult> Handle(LoginCommand request, CancellationToken cancellationToken)
    {
        var result = await identityService.AuthenticateAsync(request.Email, request.Password, cancellationToken);

        if (!result.Succeeded)
        {
            throw new AuthenticationFailedException();
        }

        return new LoginResult(result.Token!, result.ExpiresAtUtc!.Value);
    }
}
