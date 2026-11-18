import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/customer/customer_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/google_logo.dart';
import '../../../l10n/app_localizations.dart';
import '../../discounts/data/discount_history.dart';
import '../../restaurants/presentation/providers/favorites_provider.dart';
import '../../restaurants/presentation/providers/restaurant_filters_provider.dart';
import '../data/review.dart';
import 'customer_account_card.dart';

/// "My account": the customer's own place in the app. Signed out it welcomes with the Google button, three short promises and the
/// way in for restaurants; signed in it shows who is signed in, with signing out and deleting the account. More will be added here.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(customerControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myAccount)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (session == null) const _SignedOutCard() else _SignedInCard(name: session.name, photoUrl: session.photoUrl),
          const SizedBox(height: 16),
          const _BenefitTiles(),
          if (session == null) const _Consent(),
          const SizedBox(height: 20),
          const _RestaurantBanner(),
        ],
      ),
    );
  }
}

/// A big rounded white card, the same on both sides of signing in.
class _BigCard extends StatelessWidget {
  const _BigCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: child,
      );
}

class _SignedOutCard extends ConsumerWidget {
  const _SignedOutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return _BigCard(
      key: const Key('customerAccountCard'),
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(Icons.person_rounded, size: 38, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 14),
          Text(l10n.accountWelcomeTitle, textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(l10n.customerSignInHint, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 18),
          OutlinedButton(
            key: const Key('signInWithGoogle'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () => signInCustomer(context, ref),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GoogleLogo(size: 24),
                const SizedBox(width: 12),
                Flexible(child: Text(l10n.accountContinueGoogle, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignedInCard extends ConsumerWidget {
  const _SignedInCard({required this.name, required this.photoUrl});

  final String? name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final photo = photoUrl;

    return _BigCard(
      key: const Key('customerAccountCard'),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: photo == null ? null : NetworkImage(photo),
            child: photo == null ? Icon(Icons.person_rounded, size: 40, color: theme.colorScheme.onPrimaryContainer) : null,
          ),
          const SizedBox(height: 14),
          Text(name ?? l10n.anonymousReviewer, key: const Key('customerName'), textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(l10n.signedInAs, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 18),
          OutlinedButton(
            key: const Key('customerSignOut'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () => ref.read(customerControllerProvider.notifier).signOut(),
            child: Text(l10n.signOut),
          ),
          const SizedBox(height: 4),
          TextButton(
            key: const Key('customerDelete'),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            onPressed: () => confirmDeleteAccount(context, ref),
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
  }
}

/// Three short cards under the main one. Each one opens its own list and shows how many there are: reviews written, discounts taken,
/// favourite places.
class _BenefitTiles extends ConsumerWidget {
  const _BenefitTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final signedIn = ref.watch(customerControllerProvider) != null;
    final reviewCount = signedIn ? ref.watch(myReviewsProvider).valueOrNull?.length ?? 0 : 0;
    final discountCount = ref.watch(discountHistoryProvider).length;
    final favoriteCount = ref.watch(favoritesProvider).length;

    Future<void> openReviews() async {
      if (!signedIn && !await signInCustomer(context, ref)) return;
      if (context.mounted) unawaited(context.push('/my-reviews'));
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Tile(
              key: const Key('tileReviews'),
              icon: Icons.star_rounded,
              title: l10n.accountTileReviewsTitle,
              text: l10n.accountTileReviewsText,
              count: reviewCount,
              onTap: openReviews,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Tile(
              key: const Key('tileDiscounts'),
              icon: Icons.local_offer_rounded,
              title: l10n.accountTileDiscountsTitle,
              text: l10n.accountTileDiscountsText,
              count: discountCount,
              onTap: () => context.push('/my-discounts'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Tile(
              key: const Key('tileFavorites'),
              icon: Icons.favorite_rounded,
              title: l10n.accountTileFavoritesTitle,
              text: l10n.accountTileFavoritesText,
              count: favoriteCount,
              onTap: () {
                ref.read(restaurantFiltersProvider.notifier).setFavorites(true);
                context.go('/');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.text, required this.count, required this.onTap, super.key});

  final IconData icon;
  final String title;
  final String text;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, size: 24, color: theme.colorScheme.onSecondaryContainer),
              ),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              if (count > 0)
                Text('$count', key: const Key('tileCount'), style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900))
              else
                Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

/// "By continuing you agree to the Terms of use and the Privacy policy", with both documents opening on a tap.
class _Consent extends StatelessWidget {
  const _Consent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final base = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final link = base?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Text.rich(
        key: const Key('accountConsent'),
        TextSpan(
          style: base,
          children: [
            TextSpan(text: '${l10n.accountConsentStart} '),
            TextSpan(text: l10n.termsOfUse, style: link, recognizer: TapGestureRecognizer()..onTap = () => context.push('/terms')),
            TextSpan(text: ' ${l10n.accountConsentAnd} '),
            TextSpan(text: l10n.privacyPolicy, style: link, recognizer: TapGestureRecognizer()..onTap = () => context.push('/privacy')),
            TextSpan(text: l10n.accountConsentEnd.startsWith('.') ? l10n.accountConsentEnd : ' ${l10n.accountConsentEnd}'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// The way in for restaurant owners and waiters, at the bottom: a dark card with the logo's gold.
class _RestaurantBanner extends StatelessWidget {
  const _RestaurantBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Material(
      key: const Key('restaurantLogin'),
      color: const Color(0xFF14101A),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/login'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: AppTheme.gold.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.storefront_outlined, color: AppTheme.gold, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.restaurantLoginTitle, style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.gold, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(l10n.restaurantLoginText, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.gold),
            ],
          ),
        ),
      ),
    );
  }
}
