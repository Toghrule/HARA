import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_sign_in/google_sign_in.dart' show GoogleSignInException;

import '../../../core/customer/customer_controller.dart';
import '../../../l10n/app_localizations.dart';

/// Signs the customer in with Google (and out, and deletes the account). Hidden where Google sign-in is not offered.
Future<bool> signInCustomer(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);

  try {
    return await ref.read(customerControllerProvider.notifier).signIn();
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text('${l10n.signInFailed}\n(${_reason(error)})')));
    return false;
  }
}

/// A short technical reason shown under the message, so a failed sign-in can be told apart (Google, Firebase or HARA's server).
String _reason(Object error) {
  if (error is GoogleSignInException) return 'Google: ${error.code.name}';
  if (error is FirebaseAuthException) return 'Firebase: ${error.code}';
  if (error is DioException) return 'HARA: ${error.response?.statusCode ?? error.type.name}';

  return error.runtimeType.toString();
}

/// Asks the customer to confirm, then deletes the account and its reviews.
Future<void> confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.deleteAccountTitle),
      content: Text(l10n.customerDeleteBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        TextButton(
          key: const Key('customerDeleteConfirm'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.deleteAccountConfirm),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    await ref.read(customerControllerProvider.notifier).deleteAccount();
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.signInFailed)));
  }
}
