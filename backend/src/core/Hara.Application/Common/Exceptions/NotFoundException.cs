namespace Hara.Application.Common.Exceptions;

/// <summary>
/// Thrown by a handler when a requested entity doesn't exist. Mapped to an
/// HTTP 404 response by the API layer's exception-handling middleware.
/// </summary>
public class NotFoundException : Exception
{
    public NotFoundException(string entityName, object key)
        : base($"Entity \"{entityName}\" ({key}) was not found.")
    {
    }
}
