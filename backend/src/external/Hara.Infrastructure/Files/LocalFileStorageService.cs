using System.Text.RegularExpressions;
using Hara.Application.Common.Interfaces;
using Microsoft.Extensions.Options;

namespace Hara.Infrastructure.Files;

/// <summary>
/// Stores uploaded files on local disk, under the configurable
/// <see cref="FileStorageOptions.BasePath"/>. Registered behind
/// <see cref="IFileStorageService"/> so it can be swapped for a cloud-storage
/// implementation later without any caller needing to change.
/// </summary>
public partial class LocalFileStorageService(IOptions<FileStorageOptions> options) : IFileStorageService
{
    private readonly FileStorageOptions _options = options.Value;

    public async Task<string> SaveAsync(Stream content, string fileName, string category, CancellationToken cancellationToken = default)
    {
        var safeCategory = SanitizeSegment(category);
        var extension = Path.GetExtension(fileName);
        var storedFileName = $"{Guid.NewGuid():N}{extension}";

        var directory = Path.Combine(_options.BasePath, safeCategory);
        Directory.CreateDirectory(directory);

        var filePath = Path.Combine(directory, storedFileName);
        await using (var fileStream = File.Create(filePath))
        {
            await content.CopyToAsync(fileStream, cancellationToken);
        }

        return $"{_options.PublicBaseUrl.TrimEnd('/')}/{safeCategory}/{storedFileName}";
    }

    public Task DeleteAsync(string relativeUrl, CancellationToken cancellationToken = default)
    {
        var publicBase = _options.PublicBaseUrl.TrimEnd('/') + "/";
        if (!relativeUrl.StartsWith(publicBase, StringComparison.OrdinalIgnoreCase))
        {
            return Task.CompletedTask;
        }

        var relativePath = relativeUrl[publicBase.Length..].Replace('/', Path.DirectorySeparatorChar);
        var filePath = Path.Combine(_options.BasePath, relativePath);

        if (File.Exists(filePath))
        {
            File.Delete(filePath);
        }

        return Task.CompletedTask;
    }

    /// <summary>Strips anything but letters, digits and hyphens so <paramref name="segment"/> can never be used for path traversal.</summary>
    private static string SanitizeSegment(string segment) =>
        NonSafeSegmentCharacters().Replace(segment, string.Empty).ToLowerInvariant() switch
        {
            { Length: > 0 } sanitized => sanitized,
            _ => "misc"
        };

    [GeneratedRegex("[^a-zA-Z0-9-]")]
    private static partial Regex NonSafeSegmentCharacters();
}
