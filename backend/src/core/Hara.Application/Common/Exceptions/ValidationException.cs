using FluentValidation.Results;

namespace Hara.Application.Common.Exceptions;

/// <summary>
/// Thrown by <see cref="Hara.Application.Common.Behaviours.ValidationBehaviour{TRequest,TResponse}"/>
/// when one or more FluentValidation validators fail for a command/query.
/// Mapped to an HTTP 400 response, with <see cref="Errors"/> keyed by property name, by the API layer.
/// </summary>
public class ValidationException : Exception
{
    public ValidationException()
        : base("One or more validation failures have occurred.")
    {
        Errors = new Dictionary<string, string[]>();
    }

    public ValidationException(IEnumerable<ValidationFailure> failures)
        : this()
    {
        Errors = failures
            .GroupBy(f => f.PropertyName, f => f.ErrorMessage)
            .ToDictionary(g => g.Key, g => g.ToArray());
    }

    /// <summary>Validation errors, keyed by the property name that failed.</summary>
    public IDictionary<string, string[]> Errors { get; }
}
