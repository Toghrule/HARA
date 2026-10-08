namespace Hara.Application.Common.Exceptions;

/// <summary>
/// Thrown when a signed-in user asks for something their account isn't allowed to do (e.g. confirming
/// a code of a restaurant they don't work at). Mapped to an HTTP 403 response by the API layer's
/// exception-handling middleware.
/// </summary>
public class ForbiddenException(string message = "You are not allowed to do this.") : Exception(message);
