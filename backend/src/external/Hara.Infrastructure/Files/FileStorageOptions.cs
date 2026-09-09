namespace Hara.Infrastructure.Files;

/// <summary>
/// Local file storage settings, bound from the <c>FileStorage</c> appsettings
/// section. Both values are configuration-driven (never hardcoded) so the
/// storage location can move — a different disk path today, a mounted
/// volume after deployment — without a code or interface change.
/// </summary>
public class FileStorageOptions
{
    public const string SectionName = "FileStorage";

    /// <summary>Absolute or relative folder on disk where uploaded files are written.</summary>
    public string BasePath { get; set; } = "App_Data/uploads";

    /// <summary>
    /// Base URL under which <see cref="BasePath"/> is served (via static file
    /// middleware), used to build the relative URL returned to callers, e.g. <c>/uploads</c>.
    /// </summary>
    public string PublicBaseUrl { get; set; } = "/uploads";
}
