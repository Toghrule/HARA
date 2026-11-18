using FluentValidation;
using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Customers;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;
using ValidationException = Hara.Application.Common.Exceptions.ValidationException;

namespace Hara.Application.Reviews;

/// <summary>A review as everyone sees it: the stars, the words, when, and who (first name and the initial of the last; no email).</summary>
public sealed record ReviewDto(Guid Id, int Stars, string? Text, DateTimeOffset CreatedAt, string? AuthorName, string? AuthorPhotoUrl);

/// <summary>A review for the admin, who also sees which restaurant and whose it is (the email).</summary>
public sealed record AdminReviewDto(Guid Id, Guid RestaurantId, string RestaurantName, int Stars, string? Text, DateTimeOffset CreatedAt, string? AuthorName, string? AuthorEmail);

public sealed record ReviewsPageDto(IReadOnlyList<ReviewDto> Items, bool HasMore, double? Average, int Count);

/// <summary>Keeps a restaurant's average and count in step with its reviews (worked out from them, so it can never drift).</summary>
public static class RatingTotals
{
    public static async Task RecomputeAsync(IUnitOfWork unitOfWork, Guid restaurantId, CancellationToken cancellationToken)
    {
        var restaurant = await unitOfWork.Repository<Restaurant>().GetByIdAsync(restaurantId, cancellationToken);
        if (restaurant is null)
        {
            return;
        }

        var stars = await unitOfWork.Repository<Review>().Query().Where(r => r.RestaurantId == restaurantId).Select(r => r.Stars).ToListAsync(cancellationToken);
        restaurant.RatingCount = stars.Count;
        restaurant.RatingTotal = stars.Sum();
        unitOfWork.Repository<Restaurant>().Update(restaurant);
    }
}

/// <summary>The reviews of a restaurant, newest first, a page at a time. Open to everyone.</summary>
public sealed record GetReviewsQuery(Guid RestaurantId, int Page = 1, int PageSize = 20) : IRequest<ReviewsPageDto>;

public class GetReviewsQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetReviewsQuery, ReviewsPageDto>
{
    public async Task<ReviewsPageDto> Handle(GetReviewsQuery request, CancellationToken cancellationToken)
    {
        var restaurant = await unitOfWork.Repository<Restaurant>().GetByIdAsync(request.RestaurantId, cancellationToken);
        if (restaurant is null || !restaurant.IsActive)
        {
            throw new NotFoundException(nameof(Restaurant), request.RestaurantId);
        }

        var pageSize = Math.Clamp(request.PageSize, 1, 50);
        var page = Math.Max(request.Page, 1);

        var rows = await unitOfWork.Repository<Review>().Query()
            .Where(r => r.RestaurantId == request.RestaurantId)
            .OrderByDescending(r => r.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize + 1)
            .Select(r => new { r.Id, r.Stars, r.Text, r.CreatedAt, r.Customer!.DisplayName, r.Customer.PhotoUrl })
            .ToListAsync(cancellationToken);

        var items = rows.Take(pageSize)
            .Select(r => new ReviewDto(r.Id, r.Stars, r.Text, r.CreatedAt, CustomerProfile.ShortName(r.DisplayName), r.PhotoUrl))
            .ToList();

        return new ReviewsPageDto(items, rows.Count > pageSize, restaurant.RatingAverage, restaurant.RatingCount);
    }
}

/// <summary>The signed-in customer's own review of a restaurant, or <c>null</c> if they have none.</summary>
public sealed record GetMyReviewQuery(Guid RestaurantId) : IRequest<ReviewDto?>;

public class GetMyReviewQueryHandler(IUnitOfWork unitOfWork, ICurrentUserService currentUser) : IRequestHandler<GetMyReviewQuery, ReviewDto?>
{
    public async Task<ReviewDto?> Handle(GetMyReviewQuery request, CancellationToken cancellationToken)
    {
        var userId = currentUser.UserId ?? throw new ForbiddenException();

        return await unitOfWork.Repository<Review>().Query()
            .Where(r => r.RestaurantId == request.RestaurantId && r.CustomerId == userId)
            .Select(r => new ReviewDto(r.Id, r.Stars, r.Text, r.CreatedAt, CustomerProfile.ShortName(r.Customer!.DisplayName), r.Customer.PhotoUrl))
            .FirstOrDefaultAsync(cancellationToken);
    }
}

public sealed record MyReviewDto(Guid Id, Guid RestaurantId, string RestaurantName, int Stars, string? Text, DateTimeOffset CreatedAt);

/// <summary>Every review the signed-in customer wrote (of restaurants still listed), newest first.</summary>
public sealed record GetMyReviewsQuery : IRequest<IReadOnlyList<MyReviewDto>>;

public class GetMyReviewsQueryHandler(IUnitOfWork unitOfWork, ICurrentUserService currentUser) : IRequestHandler<GetMyReviewsQuery, IReadOnlyList<MyReviewDto>>
{
    public async Task<IReadOnlyList<MyReviewDto>> Handle(GetMyReviewsQuery request, CancellationToken cancellationToken)
    {
        var userId = currentUser.UserId ?? throw new ForbiddenException();

        return await unitOfWork.Repository<Review>().Query()
            .Where(r => r.CustomerId == userId && r.Restaurant!.IsActive)
            .OrderByDescending(r => r.CreatedAt)
            .Select(r => new MyReviewDto(r.Id, r.RestaurantId, r.Restaurant!.Name, r.Stars, r.Text, r.CreatedAt))
            .ToListAsync(cancellationToken);
    }
}

/// <summary>The signed-in customer gives a restaurant stars and, if they wish, words. A second time it replaces their first review (one per customer per restaurant).</summary>
public sealed record SaveMyReviewCommand(Guid RestaurantId, int Stars, string? Text) : IRequest<ReviewDto>;

public class SaveMyReviewCommandValidator : AbstractValidator<SaveMyReviewCommand>
{
    public SaveMyReviewCommandValidator()
    {
        RuleFor(c => c.RestaurantId).NotEmpty();
        RuleFor(c => c.Stars).InclusiveBetween(Review.MinStars, Review.MaxStars);
        RuleFor(c => c.Text).MaximumLength(Review.MaxTextLength);
    }
}

public class SaveMyReviewCommandHandler(IUnitOfWork unitOfWork, ICurrentUserService currentUser) : IRequestHandler<SaveMyReviewCommand, ReviewDto>
{
    public async Task<ReviewDto> Handle(SaveMyReviewCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUser.UserId ?? throw new ForbiddenException();
        var profile = await unitOfWork.Repository<CustomerProfile>().Query().FirstOrDefaultAsync(p => p.Id == userId, cancellationToken)
            ?? throw new ForbiddenException("Only customers who signed in with Google can write reviews.");

        var restaurant = await unitOfWork.Repository<Restaurant>().GetByIdAsync(request.RestaurantId, cancellationToken);
        if (restaurant is null || !restaurant.IsActive)
        {
            throw new NotFoundException(nameof(Restaurant), request.RestaurantId);
        }

        var reviews = unitOfWork.Repository<Review>();
        var text = string.IsNullOrWhiteSpace(request.Text) ? null : request.Text.Trim();

        var review = await reviews.Query().FirstOrDefaultAsync(r => r.RestaurantId == request.RestaurantId && r.CustomerId == userId, cancellationToken);
        if (review is null)
        {
            review = new Review { RestaurantId = request.RestaurantId, CustomerId = userId, Stars = request.Stars, Text = text };
            await reviews.AddAsync(review, cancellationToken);
        }
        else
        {
            review.Stars = request.Stars;
            review.Text = text;
            reviews.Update(review);
        }

        try
        {
            await unitOfWork.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            // Two saves at the same moment: the other one made the review. Say so; the customer can save again to change it.
            throw new ValidationException("stars", "Your review was saved a moment ago. Please try again to change it.");
        }

        await RatingTotals.RecomputeAsync(unitOfWork, request.RestaurantId, cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return new ReviewDto(review.Id, review.Stars, review.Text, review.CreatedAt, profile.PublicName, profile.PhotoUrl);
    }
}

/// <summary>The signed-in customer takes back their review of a restaurant.</summary>
public sealed record DeleteMyReviewCommand(Guid RestaurantId) : IRequest<Unit>;

public class DeleteMyReviewCommandHandler(IUnitOfWork unitOfWork, ICurrentUserService currentUser) : IRequestHandler<DeleteMyReviewCommand, Unit>
{
    public async Task<Unit> Handle(DeleteMyReviewCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUser.UserId ?? throw new ForbiddenException();
        var reviews = unitOfWork.Repository<Review>();

        var review = await reviews.Query().FirstOrDefaultAsync(r => r.RestaurantId == request.RestaurantId && r.CustomerId == userId, cancellationToken)
            ?? throw new NotFoundException(nameof(Review), request.RestaurantId);

        reviews.Remove(review);
        await unitOfWork.SaveChangesAsync(cancellationToken);
        await RatingTotals.RecomputeAsync(unitOfWork, request.RestaurantId, cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return Unit.Value;
    }
}

/// <summary>Admin: the newest reviews, a page at a time, to read and remove the ones that do not belong.</summary>
public sealed record GetAdminReviewsQuery(int Page = 1, int PageSize = 50) : IRequest<IReadOnlyList<AdminReviewDto>>;

public class GetAdminReviewsQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetAdminReviewsQuery, IReadOnlyList<AdminReviewDto>>
{
    public async Task<IReadOnlyList<AdminReviewDto>> Handle(GetAdminReviewsQuery request, CancellationToken cancellationToken)
    {
        var pageSize = Math.Clamp(request.PageSize, 1, 200);
        var page = Math.Max(request.Page, 1);

        var rows = await unitOfWork.Repository<Review>().Query()
            .OrderByDescending(r => r.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(r => new { r.Id, r.RestaurantId, RestaurantName = r.Restaurant!.Name, r.Stars, r.Text, r.CreatedAt, r.Customer!.DisplayName, r.Customer.Email })
            .ToListAsync(cancellationToken);

        return rows.Select(r => new AdminReviewDto(r.Id, r.RestaurantId, r.RestaurantName, r.Stars, r.Text, r.CreatedAt, r.DisplayName, r.Email)).ToList();
    }
}

/// <summary>Admin: removes a review that does not belong (abuse, an unfair attack, spam).</summary>
public sealed record DeleteReviewAsAdminCommand(Guid Id) : IRequest<Unit>;

public class DeleteReviewAsAdminCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<DeleteReviewAsAdminCommand, Unit>
{
    public async Task<Unit> Handle(DeleteReviewAsAdminCommand request, CancellationToken cancellationToken)
    {
        var reviews = unitOfWork.Repository<Review>();
        var review = await reviews.GetByIdAsync(request.Id, cancellationToken) ?? throw new NotFoundException(nameof(Review), request.Id);

        var restaurantId = review.RestaurantId;
        reviews.Remove(review);
        await unitOfWork.SaveChangesAsync(cancellationToken);
        await RatingTotals.RecomputeAsync(unitOfWork, restaurantId, cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return Unit.Value;
    }
}
