import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/customer/customer_controller.dart';
import '../../../core/network/api_client.dart';

/// What a customer wrote about a restaurant: the stars, the words (if any), when, and who (first name and the initial of the last).
class Review {
  const Review({required this.id, required this.stars, required this.createdAt, this.text, this.authorName, this.authorPhotoUrl});

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        stars: (json['stars'] as num).toInt(),
        text: json['text'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        authorName: json['authorName'] as String?,
        authorPhotoUrl: json['authorPhotoUrl'] as String?,
      );

  final String id;
  final int stars;
  final String? text;
  final DateTime createdAt;
  final String? authorName;
  final String? authorPhotoUrl;
}

/// One page of a restaurant's reviews, with the restaurant's average and count.
class ReviewsPage {
  const ReviewsPage({required this.items, required this.hasMore, required this.average, required this.count});

  factory ReviewsPage.fromJson(Map<String, dynamic> json) => ReviewsPage(
        items: [for (final item in (json['items'] as List<dynamic>? ?? const [])) Review.fromJson(item as Map<String, dynamic>)],
        hasMore: json['hasMore'] as bool? ?? false,
        average: (json['average'] as num?)?.toDouble(),
        count: (json['count'] as num?)?.toInt() ?? 0,
      );

  final List<Review> items;
  final bool hasMore;
  final double? average;
  final int count;
}

/// One of the signed-in customer's own reviews, with the restaurant it is about.
class MyReview {
  const MyReview({required this.id, required this.restaurantId, required this.restaurantName, required this.stars, required this.createdAt, this.text});

  factory MyReview.fromJson(Map<String, dynamic> json) => MyReview(
        id: json['id'] as String,
        restaurantId: json['restaurantId'] as String,
        restaurantName: json['restaurantName'] as String,
        stars: (json['stars'] as num).toInt(),
        text: json['text'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String id;
  final String restaurantId;
  final String restaurantName;
  final int stars;
  final String? text;
  final DateTime createdAt;
}

class ReviewsRepository {
  ReviewsRepository(this._apiClient);

  final ApiClient _apiClient;

  /// The reviews of a restaurant, newest first. Open to everyone.
  Future<ReviewsPage> getReviews(String restaurantId, {int page = 1, int pageSize = 10}) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/api/restaurants/$restaurantId/reviews',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );

    return ReviewsPage.fromJson(response.data!);
  }

  /// Every review the signed-in customer wrote, newest first.
  Future<List<MyReview>> getMyReviews() async {
    final response = await _apiClient.dio.get<List<dynamic>>('/api/customer/reviews');

    return [for (final item in response.data ?? const []) MyReview.fromJson(item as Map<String, dynamic>)];
  }

  /// The signed-in customer's own review of the restaurant, or `null` if they have none.
  Future<Review?> getMine(String restaurantId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/api/customer/reviews/$restaurantId');
    final data = response.data;

    return response.statusCode == 204 || data == null ? null : Review.fromJson(data);
  }

  /// Gives the restaurant stars and, if wished, words; a second time it replaces the first review.
  Future<Review> save(String restaurantId, {required int stars, String? text}) async {
    final response = await _apiClient.dio.put<Map<String, dynamic>>(
      '/api/customer/reviews/$restaurantId',
      data: {'stars': stars, 'text': text},
    );

    return Review.fromJson(response.data!);
  }

  Future<void> delete(String restaurantId) async {
    await _apiClient.dio.delete<void>('/api/customer/reviews/$restaurantId');
  }
}

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) => ReviewsRepository(ref.watch(apiClientProvider)));

/// The reviews shown on a restaurant's page: the first page, then more when asked for.
class ReviewsState {
  const ReviewsState({required this.items, required this.hasMore, required this.average, required this.count, this.loadingMore = false});

  final List<Review> items;
  final bool hasMore;
  final double? average;
  final int count;
  final bool loadingMore;
}

class ReviewsNotifier extends AutoDisposeFamilyAsyncNotifier<ReviewsState, String> {
  int _page = 1;

  @override
  Future<ReviewsState> build(String arg) async {
    _page = 1;
    final page = await ref.watch(reviewsRepositoryProvider).getReviews(arg);

    return ReviewsState(items: page.items, hasMore: page.hasMore, average: page.average, count: page.count);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;

    state = AsyncData(ReviewsState(items: current.items, hasMore: current.hasMore, average: current.average, count: current.count, loadingMore: true));

    try {
      final next = await ref.read(reviewsRepositoryProvider).getReviews(arg, page: _page + 1);
      _page += 1;
      state = AsyncData(ReviewsState(items: [...current.items, ...next.items], hasMore: next.hasMore, average: next.average, count: next.count));
    } catch (_) {
      // Keep what is shown; the button is there to try again.
      state = AsyncData(ReviewsState(items: current.items, hasMore: current.hasMore, average: current.average, count: current.count));
    }
  }
}

final reviewsProvider = AsyncNotifierProvider.autoDispose.family<ReviewsNotifier, ReviewsState, String>(ReviewsNotifier.new);

/// The signed-in customer's own review of a restaurant (`null` when nobody is signed in or they have none).
final myReviewProvider = FutureProvider.autoDispose.family<Review?, String>((ref, restaurantId) async {
  if (ref.watch(customerControllerProvider) == null) return null;

  try {
    return await ref.watch(reviewsRepositoryProvider).getMine(restaurantId);
  } catch (_) {
    return null;
  }
});

/// All of the signed-in customer's reviews (empty when nobody is signed in). Shown in My account.
final myReviewsProvider = FutureProvider.autoDispose<List<MyReview>>((ref) async {
  if (ref.watch(customerControllerProvider) == null) return const [];

  return ref.watch(reviewsRepositoryProvider).getMyReviews();
});
