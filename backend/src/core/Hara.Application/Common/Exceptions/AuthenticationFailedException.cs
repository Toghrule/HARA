namespace Hara.Application.Common.Exceptions;

/// <summary>Thrown when login credentials are invalid. Mapped to an HTTP 401 response by the API layer's exception-handling middleware.</summary>
public class AuthenticationFailedException : Exception
{
    public AuthenticationFailedException()
        : base("Invalid email or password.")
    {
    }
}
