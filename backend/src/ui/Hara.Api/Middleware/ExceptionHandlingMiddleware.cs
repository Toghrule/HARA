using Hara.Application.Common.Exceptions;
using ValidationException = Hara.Application.Common.Exceptions.ValidationException;

namespace Hara.Api.Middleware;

/// <summary>
/// Translates Application-layer exceptions into the HTTP responses endpoints
/// don't have to think about individually: <see cref="ValidationException"/> → 400,
/// <see cref="AuthenticationFailedException"/> → 401, <see cref="NotFoundException"/> → 404,
/// anything else → 500 (with details hidden outside Development).
/// </summary>
public class ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger, IHostEnvironment environment)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (ValidationException ex)
        {
            await WriteProblemAsync(context, StatusCodes.Status400BadRequest, "Validation failed", ex.Errors);
        }
        catch (AuthenticationFailedException ex)
        {
            await WriteProblemAsync(context, StatusCodes.Status401Unauthorized, ex.Message);
        }
        catch (NotFoundException ex)
        {
            await WriteProblemAsync(context, StatusCodes.Status404NotFound, ex.Message);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Unhandled exception while processing {Method} {Path}", context.Request.Method, context.Request.Path);
            var detail = environment.IsDevelopment() ? ex.ToString() : "An unexpected error occurred.";
            await WriteProblemAsync(context, StatusCodes.Status500InternalServerError, "An unexpected error occurred.", detail: detail);
        }
    }

    private static async Task WriteProblemAsync(HttpContext context, int statusCode, string title, IDictionary<string, string[]>? errors = null, string? detail = null)
    {
        context.Response.ContentType = "application/problem+json";
        context.Response.StatusCode = statusCode;

        var problem = new
        {
            title,
            status = statusCode,
            detail,
            errors
        };

        await context.Response.WriteAsJsonAsync(problem);
    }
}
