import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/network/api_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/venue_repository.dart';
import '../providers/venue_providers.dart';

/// What a new owner or waiter sees until they type the six-digit code that was emailed to them: nothing else works before.
class EmailVerifyScreen extends ConsumerStatefulWidget {
  const EmailVerifyScreen({required this.email, required this.actions, super.key});

  final String email;

  /// The account buttons (language, sign out), which the person can still use.
  final List<Widget> actions;

  @override
  ConsumerState<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends ConsumerState<EmailVerifyScreen> {
  /// The server lets a new code be asked for once a minute; the button waits the same.
  static const _cooldownSeconds = 60;

  final _code = TextEditingController();
  Timer? _timer;
  int _wait = _cooldownSeconds; // a code was just sent at sign-up
  bool _submitting = false;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _wait = _cooldownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _wait = _wait > 0 ? _wait - 1 : 0);
      if (_wait == 0) timer.cancel();
    });
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    final code = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        _error = l10n.emailCodeSixDigits;
        _info = null;
      });

      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _info = null;
    });

    try {
      await ref.read(venueRepositoryProvider).verifyEmail(code);
      // Who the person is now has no address to confirm, so the app goes on.
      ref.invalidate(venueMeProvider);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = emailCodeErrorMessage(error, l10n);
      });
    }
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _error = null;
      _info = null;
    });

    try {
      await ref.read(venueRepositoryProvider).resendEmailCode(l10n.localeName);
      if (!mounted) return;
      _code.clear();
      _startCountdown();
      setState(() => _info = l10n.emailResent);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = emailCodeErrorMessage(error, l10n));
    }
  }

  /// A wrong address: the account is signed out, and signing up again with the right one replaces it.
  Future<void> _startOver() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.emailConfirmTitle), actions: widget.actions),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Icon(Icons.mark_email_unread_outlined, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(l10n.emailConfirmBody(widget.email), key: const Key('verifyBody'), style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                TextField(
                  key: const Key('emailCode'),
                  controller: _code,
                  enabled: !_submitting,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 8),
                  decoration: InputDecoration(labelText: l10n.emailCodeLabel, border: const OutlineInputBorder(), counterText: ''),
                  onSubmitted: (_) => _confirm(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, key: const Key('verifyError'), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error), textAlign: TextAlign.center),
                ],
                if (_info != null) ...[
                  const SizedBox(height: 12),
                  Text(_info!, key: const Key('verifyInfo'), style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('verifyConfirm'),
                  onPressed: _submitting ? null : _confirm,
                  child: _submitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l10n.emailConfirmButton),
                ),
                const SizedBox(height: 8),
                TextButton(
                  key: const Key('verifyResend'),
                  onPressed: _submitting || _wait > 0 ? null : _resend,
                  child: Text(_wait > 0 ? l10n.emailResendIn(_wait) : l10n.emailResend),
                ),
                TextButton(
                  key: const Key('verifyStartOver'),
                  onPressed: _submitting ? null : _startOver,
                  child: Text(l10n.emailChangeAddress),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
