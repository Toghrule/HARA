import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/venue_models.dart';
import '../../data/venue_repository.dart';
import 'reservation_detail_card.dart';

/// The waiter types the code a customer shows, sees whether it is good and what discount to give, and
/// confirms it.
class CodeConfirmTab extends ConsumerStatefulWidget {
  const CodeConfirmTab({super.key});

  @override
  ConsumerState<CodeConfirmTab> createState() => _CodeConfirmTabState();
}

class _CodeConfirmTabState extends ConsumerState<CodeConfirmTab> {
  final _controller = TextEditingController();

  bool _checking = false;
  VenueReservation? _found;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    setState(() {
      _checking = true;
      _found = null;
      _error = null;
    });

    try {
      final found = await ref.read(venueRepositoryProvider).lookup(code);
      if (mounted) setState(() => _found = found);
    } catch (error) {
      if (!mounted) return;

      setState(() => _error = error is DioException && error.response?.statusCode == 404
          ? l10n.codeNotFoundHere
          : apiErrorMessage(error, l10n));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          key: const Key('codeInput'),
          controller: _controller,
          enabled: !_checking,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.search,
          inputFormatters: [
            LengthLimitingTextInputFormatter(16),
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
          ],
          style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 4),
          textAlign: TextAlign.center,
          decoration: InputDecoration(labelText: l10n.codeInputLabel, border: const OutlineInputBorder()),
          onSubmitted: (_) => _check(),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          key: const Key('checkCode'),
          onPressed: _checking ? null : _check,
          child: _checking
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.checkCode),
        ),
        const SizedBox(height: 16),
        if (_error != null)
          Text(
            _error!,
            key: const Key('codeError'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
          ),
        if (_found != null) ReservationDetailCard(reservation: _found!),
      ],
    );
  }
}
