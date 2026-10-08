import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/venue_models.dart';
import '../providers/venue_providers.dart';
import 'reservation_detail_card.dart';

/// The restaurant's reservations, active ones first. Tapping one opens it, ready to confirm.
class ReservationsTab extends ConsumerStatefulWidget {
  const ReservationsTab({super.key});

  @override
  ConsumerState<ReservationsTab> createState() => _ReservationsTabState();
}

class _ReservationsTabState extends ConsumerState<ReservationsTab> {
  ReservationFilter _filter = ReservationFilter.active;

  String _label(AppLocalizations l10n, ReservationFilter filter) => switch (filter) {
        ReservationFilter.active => l10n.filterActive,
        ReservationFilter.used => l10n.filterUsed,
        ReservationFilter.all => l10n.filterAll,
      };

  void _open(VenueReservation reservation) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.of(sheetContext).viewInsets.bottom),
        child: SingleChildScrollView(child: ReservationDetailCard(reservation: reservation)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reservationsAsync = ref.watch(venueReservationsProvider(_filter));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SegmentedButton<ReservationFilter>(
            key: const Key('reservationFilter'),
            segments: [
              for (final filter in ReservationFilter.values)
                ButtonSegment(value: filter, label: Text(_label(l10n, filter))),
            ],
            selected: {_filter},
            onSelectionChanged: (selection) => setState(() => _filter = selection.first),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(venueReservationsProvider(_filter).future),
            child: reservationsAsync.when(
              data: (reservations) {
                if (reservations.isEmpty) {
                  return LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(height: constraints.maxHeight, child: Center(child: Text(l10n.noReservationsHere))),
                    ),
                  );
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: reservations.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) => _ReservationTile(reservation: reservations[index], onTap: _open),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => ErrorView(
                message: apiErrorMessage(error, l10n),
                onRetry: () => ref.invalidate(venueReservationsProvider(_filter)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReservationTile extends StatelessWidget {
  const _ReservationTile({required this.reservation, required this.onTap});

  final VenueReservation reservation;
  final ValueChanged<VenueReservation> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListTile(
      key: Key('reservation-${reservation.code}'),
      title: Text(reservation.code, style: theme.textTheme.titleMedium?.copyWith(letterSpacing: 2, fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${reservation.phoneNumber}\n${formatDayAndClock(reservation.createdAt)} · ${l10n.minutesShort(reservation.durationMinutes)}',
      ),
      isThreeLine: true,
      trailing: Text(
        reservation.isUsable ? l10n.validUntilLine(formatClock(reservation.expiresAt)) : reservationStatusText(l10n, reservation.effectiveStatus),
        textAlign: TextAlign.end,
      ),
      onTap: () => onTap(reservation),
    );
  }
}
