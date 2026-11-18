import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../data/discount_history.dart';

/// The places where this phone took a discount code, newest first; a tap opens the restaurant (to take today's code again).
class MyDiscountsScreen extends ConsumerWidget {
  const MyDiscountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final items = ref.watch(discountHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myDiscountsTitle)),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l10n.myDiscountsEmpty, key: const Key('myDiscountsEmpty'), textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final date = item.at.toLocal();

                return Card(
                  key: Key('myDiscount-${item.restaurantId}'),
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: const Icon(Icons.local_offer_rounded),
                    title: Text(item.restaurantName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${l10n.discountPercentOff(item.percent)} · ${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/restaurants/${item.restaurantId}'),
                  ),
                );
              },
            ),
    );
  }
}
