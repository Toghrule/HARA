import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../reservations/data/reservation.dart';
import '../../data/venue_models.dart';
import '../../data/venue_repository.dart';
import '../providers/venue_providers.dart';
import 'reservation_detail_card.dart';

/// Customers' requests waiting for the restaurant's answer, oldest first. Accepting one starts the customer's
/// hold timer and shows them their code; declining it tells them to look elsewhere. The list refreshes itself
/// while the restaurant screens are open (see the venue home), so a new request appears within seconds.
class RequestsTab extends ConsumerStatefulWidget {
  const RequestsTab({super.key});

  @override
  ConsumerState<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends ConsumerState<RequestsTab> {
  final Set<String> _busy = {};

  Future<void> _answer(VenueReservation request, {required bool accept}) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy.add(request.code));

    try {
      final repository = ref.read(venueRepositoryProvider);
      if (accept) {
        await repository.accept(request.code);
      } else {
        await repository.decline(request.code);
      }
      messenger.showSnackBar(
        SnackBar(content: Text(accept ? l10n.requestAccepted(reservationHoldMinutes) : l10n.requestDeclinedDone)),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(error, l10n))));
    } finally {
      ref.invalidate(venueReservationsProvider);
      if (mounted) setState(() => _busy.remove(request.code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requestsAsync = ref.watch(venueReservationsProvider(ReservationFilter.pending));

    return RefreshIndicator(
      onRefresh: () => ref.refresh(venueReservationsProvider(ReservationFilter.pending).future),
      child: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: Center(child: Text(l10n.noRequestsWaiting, key: const Key('noRequests'))),
                ),
              ),
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = requests[index];

              return _RequestCard(
                key: Key('request-${request.code}'),
                request: request,
                busy: _busy.contains(request.code),
                onAccept: () => _answer(request, accept: true),
                onDecline: () => _answer(request, accept: false),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorView(
          message: apiErrorMessage(error, l10n),
          onRetry: () => ref.invalidate(venueReservationsProvider(ReservationFilter.pending)),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
    super.key,
  });

  final VenueReservation request;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(request.phoneNumber, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(l10n.sentAt(formatClock(request.createdAt)), style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            _AnswerCountdown(deadline: request.expiresAt),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    key: Key('decline-${request.code}'),
                    onPressed: busy ? null : onDecline,
                    style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                    child: Text(l10n.decline),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    key: Key('accept-${request.code}'),
                    onPressed: busy ? null : onAccept,
                    child: busy
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.acceptRequest),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Answer within 12:34", ticking every second.
class _AnswerCountdown extends StatefulWidget {
  const _AnswerCountdown({required this.deadline});

  final DateTime deadline;

  @override
  State<_AnswerCountdown> createState() => _AnswerCountdownState();
}

class _AnswerCountdownState extends State<_AnswerCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Text(
      l10n.answerWithin(formatCountdown(widget.deadline.difference(DateTime.now()))),
      style: Theme.of(context).textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );
  }
}
