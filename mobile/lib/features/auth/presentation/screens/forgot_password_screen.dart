import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/password_reset_storage.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/language_menu.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/password_reset_repository.dart';
import '../form_validators.dart';
import '../password_field.dart';

enum _Step { loading, ask, waiting, approved, declined }

/// An owner who forgot their password asks HARA to allow a new one. HARA checks it is really them (by phone) and approves
/// in the admin panel; this screen, which keeps asking while it is open, then shows the form for the new password. The
/// request is remembered on the phone, so leaving and coming back picks up where it was.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  /// How often the answer is looked for while the owner waits on this screen.
  static const _checkEvery = Duration(seconds: 5);

  final _emailForm = GlobalKey<FormState>();
  final _passwordForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _newPassword = TextEditingController();
  final _repeatPassword = TextEditingController();

  _Step _step = _Step.loading;
  PasswordResetTicket? _ticket;
  bool _busy = false;
  String? _error;
  String? _notice;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(_resume());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _newPassword.dispose();
    _repeatPassword.dispose();
    super.dispose();
  }

  /// Picks up a request made earlier on this phone.
  Future<void> _resume() async {
    final ticket = await ref.read(passwordResetStorageProvider).read();
    if (!mounted) return;

    if (ticket == null) {
      setState(() => _step = _Step.ask);
      return;
    }

    setState(() {
      _ticket = ticket;
      _step = _Step.waiting;
    });
    await _check(silent: true);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_checkEvery, (_) => unawaited(_check(silent: true)));
  }

  /// Forgets the request, here and on the phone, and goes back to the start with a note.
  Future<void> _forget({String? notice}) async {
    _timer?.cancel();
    await ref.read(passwordResetStorageProvider).clear();
    if (!mounted) return;

    setState(() {
      _ticket = null;
      _step = _Step.ask;
      _notice = notice;
      _error = null;
      _busy = false;
    });
  }

  Future<void> _check({bool silent = false}) async {
    final ticket = _ticket;
    if (ticket == null || _step == _Step.approved) return;

    if (!silent) setState(() => _busy = true);
    try {
      final state = await ref.read(passwordResetRepositoryProvider).status(ticket);
      if (!mounted) return;

      switch (state) {
        case PasswordResetState.pending:
          setState(() {
            _step = _Step.waiting;
            _busy = false;
          });
          if (_timer?.isActive != true) _startTimer();
        case PasswordResetState.approved:
          _timer?.cancel();
          setState(() {
            _step = _Step.approved;
            _busy = false;
            _error = null;
          });
        case PasswordResetState.rejected:
          _timer?.cancel();
          await ref.read(passwordResetStorageProvider).clear();
          if (!mounted) return;
          setState(() {
            _ticket = null;
            _step = _Step.declined;
            _busy = false;
          });
        case PasswordResetState.completed:
        case PasswordResetState.expired:
          await _forget(notice: AppLocalizations.of(context).resetNoLongerValid);
      }
    } catch (error) {
      if (!mounted) return;
      // While waiting a failed check is not worth a message: the next one will try again.
      setState(() {
        _busy = false;
        if (!silent) _error = apiErrorMessage(error, AppLocalizations.of(context));
      });
      if (_step == _Step.waiting && _timer?.isActive != true) _startTimer();
    }
  }

  Future<void> _send() async {
    if (!_emailForm.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      final ticket = await ref.read(passwordResetRepositoryProvider).request(_email.text.trim());
      await ref.read(passwordResetStorageProvider).write(ticket);
      if (!mounted) return;

      setState(() {
        _ticket = ticket;
        _step = _Step.waiting;
        _busy = false;
      });
      _startTimer();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = apiErrorMessage(error, AppLocalizations.of(context));
      });
    }
  }

  Future<void> _save() async {
    final ticket = _ticket;
    if (ticket == null || !_passwordForm.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(passwordResetRepositoryProvider).complete(ticket, _newPassword.text);
      await ref.read(passwordResetStorageProvider).clear();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.resetDone)));
      context.go('/login');
    } catch (error) {
      if (!mounted) return;

      // The request ran out or was used up meanwhile: nothing more can be done with it.
      final data = error is DioException ? error.response?.data : null;
      final errors = data is Map<String, dynamic> ? data['errors'] : null;
      if (errors is Map && errors.keys.any((key) => '$key'.toLowerCase() == 'request')) {
        await _forget(notice: l10n.resetNoLongerValid);
        return;
      }

      setState(() {
        _busy = false;
        _error = registrationErrorMessage(error, l10n);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resetTitle), actions: const [LanguageMenu()]),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_step == _Step.loading) const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
                if (_step == _Step.ask) ..._ask(l10n, theme),
                if (_step == _Step.waiting) ..._waiting(l10n, theme),
                if (_step == _Step.approved) ..._approved(l10n, theme),
                if (_step == _Step.declined) ..._declined(l10n, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _errorLine(ThemeData theme) => [
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, key: const Key('resetError'), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
        ],
      ];

  List<Widget> _ask(AppLocalizations l10n, ThemeData theme) => [
        if (_notice != null) ...[
          Text(_notice!, key: const Key('resetNotice'), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 12),
        ],
        Text(l10n.resetIntro, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        Form(
          key: _emailForm,
          child: TextFormField(
            key: const Key('resetEmail'),
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(labelText: l10n.emailLabel, border: const OutlineInputBorder()),
            validator: FormValidators(l10n).email,
            onFieldSubmitted: (_) => _send(),
          ),
        ),
        ..._errorLine(theme),
        const SizedBox(height: 20),
        FilledButton(
          key: const Key('resetSend'),
          onPressed: _busy ? null : _send,
          child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l10n.resetSend),
        ),
      ];

  List<Widget> _waiting(AppLocalizations l10n, ThemeData theme) => [
        Icon(Icons.hourglass_top, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text(l10n.resetWaitingTitle, key: const Key('resetWaiting'), style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(l10n.resetWaitingBody(_ticket?.email ?? ''), textAlign: TextAlign.center),
        ..._errorLine(theme),
        const SizedBox(height: 20),
        FilledButton.tonal(
          key: const Key('resetCheck'),
          onPressed: _busy ? null : () => _check(),
          child: Text(l10n.resetCheckNow),
        ),
        TextButton(key: const Key('resetCancel'), onPressed: _busy ? null : () => _forget(), child: Text(l10n.resetCancel)),
      ];

  List<Widget> _approved(AppLocalizations l10n, ThemeData theme) {
    final validators = FormValidators(l10n);

    return [
      Text(l10n.resetApprovedTitle, key: const Key('resetApproved'), style: theme.textTheme.titleLarge),
      const SizedBox(height: 8),
      Text(l10n.resetApprovedBody),
      const SizedBox(height: 16),
      Form(
        key: _passwordForm,
        child: Column(
          children: [
            PasswordField(
              key: const Key('resetNewPassword'),
              controller: _newPassword,
              label: l10n.resetNewPasswordLabel,
              enabled: !_busy,
              textInputAction: TextInputAction.next,
              validator: validators.newPassword,
            ),
            const SizedBox(height: 16),
            PasswordField(
              key: const Key('resetRepeatPassword'),
              controller: _repeatPassword,
              label: l10n.confirmPasswordLabel,
              enabled: !_busy,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              validator: validators.sameAs(() => _newPassword.text),
            ),
          ],
        ),
      ),
      ..._errorLine(theme),
      const SizedBox(height: 20),
      FilledButton(
        key: const Key('resetSave'),
        onPressed: _busy ? null : _save,
        child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l10n.resetSave),
      ),
    ];
  }

  List<Widget> _declined(AppLocalizations l10n, ThemeData theme) => [
        Icon(Icons.block, size: 48, color: theme.colorScheme.error),
        const SizedBox(height: 12),
        Text(l10n.resetRejected, key: const Key('resetDeclined'), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        FilledButton.tonal(
          key: const Key('resetAskAgain'),
          onPressed: () => setState(() {
            _step = _Step.ask;
            _error = null;
          }),
          child: Text(l10n.resetAskAgain),
        ),
      ];
}
