namespace Hara.Application.Common.Interfaces;

/// <summary>
/// Stores uploaded files (currently restaurant/ad/logo images) and hands
/// back a URL the mobile app and admin panel can load them from. Kept as an
/// abstraction so today's local-disk implementation can later be swapped for
/// cloud storage without changing any command handler that uses it.
/// </summary>
public interface IFileStorageService
{
    /// <summary>
    /// Saves <paramref name="content"/> under the given <paramref name="category"/>
    /// (e.g. "restaurants", "advertisements") and returns the relative URL it
    /// can be retrieved from.
    /// </summary>
    /// <param name="content">The file's binary content.</param>
    /// <param name="fileName">Original file name, used to derive the stored file's extension.</param>
    /// <param name="category">Logical grouping folder for the file, e.g. the module that owns it.</param>
    Task<string> SaveAsync(Stream content, string fileName, string category, CancellationToken cancellationToken = default);

    /// <summary>Deletes a previously saved file, identified by the relative URL <see cref="SaveAsync"/> returned. No-ops if it no longer exists.</summary>
    Task DeleteAsync(string relativeUrl, CancellationToken cancellationToken = default);
}
