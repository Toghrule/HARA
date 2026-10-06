import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../data/reservation.dart';
import '../../data/reservations_repository.dart';

/// Shows the customer their reservation code to present at the venue, with a
/// live countdown until the reservation window ends, and lets them cancel it.
class ReservationCodeScreen extends ConsumerStatefulWidget {
  const ReservationCodeScreen({required this.reservation, super.key});

  final Reservation reservation;

  @override
  ConsumerState<ReservationCodeScreen> createState() => _ReservationCodeScreenState();
}

class _ReservationCodeScreenState extends ConsumerState<ReservationCodeScreen> {
  Timer? _timer;
  late Duration _remaining;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _remaining = _computeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = _computeRemaining();
      if (remaining != _remaining) setState(() => _remaining = remaining);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _computeRemaining() {
    final remaining = widget.reservation.expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  String get _countdownLabel =>
      '${_two(_remaining.inMinutes)}:${_two(_remaining.inSeconds.remainder(60))}';

  String get _validUntilLabel {
    final local = widget.reservation.expiresAt.toLocal();
    return '${_two(local.hour)}:${_two(local.minute)}';
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel reservation?'),
        content: const Text(
          'Your code will stop working and the table will be released. '
          'You can make a new reservation afterwards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel reservation'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await ref.read(reservationsRepositoryProvider).cancel(widget.reservation.code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reservation cancelled')));
      context.go('/');
    } catch (error) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      final notFound = error is DioException && error.response?.statusCode == 404;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notFound ? 'We couldn\'t find this reservation.' : apiErrorMessage(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservation = widget.reservation;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final expired = _remaining == Duration.zero;

    return Scaffold(
      appBar: AppBar(title: const Text('Your reservation'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    reservation.restaurantName,
                    style: textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text('Your code', style: textTheme.labelLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Card(
                    color: expired
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            reservation.code,
                            style: textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 6,
                              decoration: expired ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copy code',
                            icon: const Icon(Icons.copy),
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: reservation.code));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Code copied')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    expired ? 'This reservation has expired' : 'Valid for $_countdownLabel',
                    style: textTheme.titleMedium?.copyWith(
                      color: expired ? theme.colorScheme.error : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Table held until $_validUntilLabel (${reservation.durationMinutes} min)',
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    reservation.discountPercent > 0
                        ? 'Show this code at the venue when you arrive to get '
                            '${reservation.discountPercent}% off your bill.'
                        : 'Show this code at the venue when you arrive.',
                    style: textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _cancelling ? null : () => context.go('/'),
                    child: const Text('Done'),
                  ),
                  if (!expired) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _cancelling ? null : _cancel,
                      style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                      child: _cancelling
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Cancel reservation'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
