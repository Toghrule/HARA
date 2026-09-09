using MediatR;

namespace Hara.Application.Restaurants.Submissions.Commands.DeleteSubmission;

/// <summary>Admin command to permanently remove a submission, e.g. after it has been actioned or is spam.</summary>
public sealed record DeleteSubmissionCommand(Guid Id) : IRequest;
