using FluentValidation;

namespace Hara.Application.Uploads.Commands.UploadImage;

public class UploadImageCommandValidator : AbstractValidator<UploadImageCommand>
{
    private static readonly string[] AllowedContentTypes = ["image/jpeg", "image/png", "image/webp", "image/gif"];

    public UploadImageCommandValidator()
    {
        RuleFor(c => c.FileName).NotEmpty();
        RuleFor(c => c.Category).NotEmpty();
        RuleFor(c => c.ContentType)
            .Must(contentType => AllowedContentTypes.Contains(contentType.ToLowerInvariant()))
            .WithMessage($"Only the following image types are allowed: {string.Join(", ", AllowedContentTypes)}.");
    }
}
