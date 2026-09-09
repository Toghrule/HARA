using Hara.Application.Common.Interfaces;
using MediatR;

namespace Hara.Application.Uploads.Commands.UploadImage;

public class UploadImageCommandHandler(IFileStorageService fileStorageService) : IRequestHandler<UploadImageCommand, UploadImageResult>
{
    public async Task<UploadImageResult> Handle(UploadImageCommand request, CancellationToken cancellationToken)
    {
        var url = await fileStorageService.SaveAsync(request.Content, request.FileName, request.Category, cancellationToken);
        return new UploadImageResult(url);
    }
}
