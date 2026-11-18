import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../data/review.dart';
import 'reviews_section.dart';

/// Everything the signed-in customer has reviewed; a tap opens the restaurant, where the review can be changed or removed.
class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final reviews = ref.watch(myReviewsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myReviewsTitle)),
      body: reviews.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(message: apiErrorMessage(error, l10n), onRetry: () => ref.invalidate(myReviewsProvider)),
        data: (items) => items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(l10n.myReviewsEmpty, key: const Key('myReviewsEmpty'), textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final review = items[index];
                  final text = review.text?.trim();
                  final date = review.createdAt.toLocal();

                  return Card(
                    key: Key('myReview-${review.id}'),
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push('/restaurants/${review.restaurantId}'),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(review.restaurantName, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            const SizedBox(height: 4),
                            StarRow(stars: review.stars),
                            if (text != null && text.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(text)),
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
