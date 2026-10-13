import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/network/api_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/password_field.dart';
import '../../data/venue_repository.dart';

/// Asks the signed-in person to confirm with their password, then deletes their account. Pops with `true`
/// once the account is gone and this device has forgotten the session.
class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  ConsumerState<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final _password = TextEditingController();

  bool _deleting = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  /// The server's English complaints about the password, in the app's language.
  String _message(Object error, AppLocalizations l10n) {
    if (error is DioException && error.response?.statusCode == 400) {
      final data = error.response?.data;
      final errors = data is Map<String, dynamic> ? data['errors'] : null;

      if (errors is Map) {
        for (final entry in errors.entries) {
          if ('${entry.key}'.toLowerCase() != 'password') continue;

          final messages = entry.value is List ? (entry.value as List).map((message) => '$message'.toLowerCase()) : <String>[];

          return messages.any((message) => message.contains('too many')) ? l10n.tooManyWrongPasswords : l10n.wrongPassword;
        }
      }
    }

    return apiErrorMessage(error, l10n);
  }

  Future<void> _delete() async {
    if (_password.text.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    setState(() {
      _deleting = true;
      _error = null;
    });

    try {
      await ref.read(venueRepositoryProvider).deleteAccount(_password.text);
      await ref.read(authControllerProvider.notifier).accountDeleted();
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _deleting = false;
        _error = _message(error, l10n);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.deleteAccountTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteAccountBody),
            const SizedBox(height: 16),
            PasswordField(
              key: const Key('deletePassword'),
              controller: _password,
              label: l10n.passwordLabel,
              enabled: !_deleting,
              validator: (_) => null,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _delete(),
            ),
            const SizedBox(height: 4),
            Text(l10n.deleteAccountPasswordHint, style: theme.textTheme.bodySmall),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, key: const Key('deleteError'), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _deleting ? null : () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
        FilledButton(
          key: const Key('deleteAccountConfirm'),
          style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: theme.colorScheme.onError),
          onPressed: _deleting ? null : _delete,
          child: _deleting
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.deleteAccountConfirm),
        ),
      ],
    );
  }
}
