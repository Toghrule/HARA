import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/customer/customer_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../restaurants/presentation/providers/restaurant_provider.dart';
import '../data/review.dart';
import 'customer_account_card.dart';

/// Stars in a row, filled up to [stars].
class StarRow extends StatelessWidget {
  const StarRow({required this.stars, this.size = 16, super.key});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(i <= stars ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: const Color(0xFFF5A623)),
        ],
      );
}

/// The reviews of a restaurant, and the way to write one (signing in with Google first when needed).
class ReviewsSection extends ConsumerWidget {
  const ReviewsSection({required this.restaurantId, super.key});

  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final reviews = ref.watch(reviewsProvider(restaurantId));
    final mine = ref.watch(myReviewProvider(restaurantId)).valueOrNull;
    final canWrite = ref.watch(customerControllerProvider) != null || ref.read(customerControllerProvider.notifier).canSignIn;
    final state = reviews.valueOrNull;

    return Column(
      key: const Key('reviewsSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(l10n.reviewsTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        ),
        if (canWrite)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: OutlinedButton.icon(
              key: const Key('writeReview'),
              onPressed: () => _write(context, ref, mine),
              icon: const Icon(Icons.rate_review_outlined),
              label: Text(mine == null ? l10n.writeReview : l10n.editReview),
            ),
          ),
        if (state == null && reviews.isLoading)
          const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
        else if (state == null || state.items.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(l10n.noReviewsYet, key: const Key('noReviews'), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          )
        else ...[
          for (final review in state.items) _ReviewTile(review: review),
          if (state.hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                key: const Key('reviewsShowMore'),
                onPressed: state.loadingMore ? null : () => ref.read(reviewsProvider(restaurantId).notifier).loadMore(),
                child: Text(l10n.reviewsShowMore),
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _write(BuildContext context, WidgetRef ref, Review? mine) async {
    if (ref.read(customerControllerProvider) == null) {
      final signedIn = await signInCustomer(context, ref);
      if (!signedIn || !context.mounted) return;
    }

    // The customer may already have a review that we had not looked for before they signed in.
    final existing = mine ?? await ref.refresh(myReviewProvider(restaurantId).future);
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ReviewSheet(restaurantId: restaurantId, existing: existing),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final photo = review.authorPhotoUrl;
    final text = review.text?.trim();
    final date = review.createdAt.toLocal();

    return ListTile(
      key: Key('review-${review.id}'),
      leading: CircleAvatar(
        backgroundImage: photo == null ? null : NetworkImage(photo),
        child: photo == null ? const Icon(Icons.person_outline) : null,
      ),
      title: Row(
        children: [
          Flexible(child: Text(review.authorName ?? l10n.anonymousReviewer, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(width: 8),
          StarRow(stars: review.stars, size: 14),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (text != null && text.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(text)),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// Where a signed-in customer picks stars, writes a few words, and saves (or takes the review back).
class ReviewSheet extends ConsumerStatefulWidget {
  const ReviewSheet({required this.restaurantId, this.existing, super.key});

  final String restaurantId;
  final Review? existing;

  @override
  ConsumerState<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<ReviewSheet> {
  late int _stars = widget.existing?.stars ?? 0;
  late final _text = TextEditingController(text: widget.existing?.text ?? '');
  bool _busy = false;
  bool _starsMissing = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_stars == 0) {
      setState(() => _starsMissing = true);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(reviewsRepositoryProvider).save(widget.restaurantId, stars: _stars, text: _text.text.trim().isEmpty ? null : _text.text.trim());
      _refresh();
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.reviewSaved)));
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.signInFailed)));
    }
  }

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(reviewsRepositoryProvider).delete(widget.restaurantId);
      _refresh();
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.reviewRemoved)));
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.signInFailed)));
    }
  }

  void _refresh() {
    ref
      ..invalidate(reviewsProvider(widget.restaurantId))
      ..invalidate(myReviewProvider(widget.restaurantId))
      ..invalidate(myReviewsProvider)
      ..invalidate(restaurantProvider(widget.restaurantId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.reviewPickStars, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    key: Key('star$i'),
                    iconSize: 36,
                    onPressed: _busy ? null : () => setState(() {
                      _stars = i;
                      _starsMissing = false;
                    }),
                    icon: Icon(i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded, color: const Color(0xFFF5A623)),
                  ),
              ],
            ),
            if (_starsMissing) Text(l10n.reviewStarsRequired, key: const Key('starsRequired'), style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 8),
            TextField(
              key: const Key('reviewText'),
              controller: _text,
              enabled: !_busy,
              maxLength: 1000,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(hintText: l10n.reviewHint, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('saveReview'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: _busy ? null : _save,
              child: Text(l10n.saveReview),
            ),
            if (widget.existing != null)
              Center(
                child: TextButton(
                  key: const Key('deleteReview'),
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                  onPressed: _busy ? null : _remove,
                  child: Text(l10n.deleteReview),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
