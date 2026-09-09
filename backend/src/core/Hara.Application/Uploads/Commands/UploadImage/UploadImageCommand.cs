using MediatR;

namespace Hara.Application.Uploads.Commands.UploadImage;

/// <summary>
/// Admin command to upload a single image (a restaurant cover photo, an ad
/// slide, a logo, etc.) and get back the URL to store on the owning entity's
/// <c>ImageUrl</c>/<c>LogoUrl</c> field. Decoupled from any specific entity
/// so the same endpoint serves every module that needs an image.
/// </summary>
/// <param name="Content">Raw file bytes.</param>
/// <param name="FileName">Original file name, used to derive the stored extension.</param>
/// <param name="ContentType">The uploaded file's MIME type, validated against an image allow-list.</param>
/// <param name="Category">Logical folder to store the file under, e.g. "restaurants" or "advertisements".</param>
public sealed record UploadImageCommand(Stream Content, string FileName, string ContentType, string Category) : IRequest<UploadImageResult>;

/// <summary>Outcome of a successful <see cref="UploadImageCommand"/>.</summary>
/// <param name="Url">The relative URL the uploaded image can now be retrieved from.</param>
public sealed record UploadImageResult(string Url);
