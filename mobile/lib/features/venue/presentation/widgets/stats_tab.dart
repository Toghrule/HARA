import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/venue_models.dart';
import '../providers/venue_providers.dart';

/// How the restaurant is doing. The owner sees the restaurant's day, month and year; every waiter (and the owner
/// too) sees how many codes they confirmed themselves today.
class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statsAsync = ref.watch(venueStatsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(venueStatsProvider.future),
      child: statsAsync.when(
        data: (stats) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (stats.today != null) _PeriodCard(title: l10n.statsToday, counts: stats.today!, keyPrefix: 'today'),
            if (stats.thisMonth != null) _PeriodCard(title: l10n.statsThisMonth, counts: stats.thisMonth!, keyPrefix: 'month'),
            if (stats.thisYear != null) _PeriodCard(title: l10n.statsThisYear, counts: stats.thisYear!, keyPrefix: 'year'),
            Card(
              child: ListTile(
                title: Text(l10n.statsMyToday),
                trailing: Text(
                  '${stats.redeemedByMeToday}',
                  key: const Key('statsMine'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.statsHint, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorView(
          message: apiErrorMessage(error, l10n),
          onRetry: () => ref.invalidate(venueStatsProvider),
        ),
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.title, required this.counts, required this.keyPrefix});

  final String title;
  final PeriodCounts counts;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _Number(label: l10n.statsAccepted, value: counts.accepted, valueKey: Key('$keyPrefix-accepted'))),
                Expanded(child: _Number(label: l10n.statsCame, value: counts.redeemed, valueKey: Key('$keyPrefix-came'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Number extends StatelessWidget {
  const _Number({required this.label, required this.value, required this.valueKey});

  final String label;
  final int value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$value', key: valueKey, style: Theme.of(context).textTheme.headlineMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
