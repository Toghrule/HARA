import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../../../l10n/app_localizations.dart';
import '../../restaurants/data/restaurant.dart';
import '../data/discount_history.dart';
import '../data/discounts_repository.dart';

/// The customer tapped "Get the discount": asks HARA for their code at [restaurant] (today's, if they already took one) and opens it.
/// A failure is said in a message instead.
Future<void> getDiscount(BuildContext context, WidgetRef ref, Restaurant restaurant) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final router = GoRouter.of(context);

  try {
    final code = await ref.read(discountsRepositoryProvider).getCode(restaurant.id);
    await ref.read(discountHistoryProvider.notifier).add(code);
    await router.push('/discount', extra: code);
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(error, l10n))));
  }
}
