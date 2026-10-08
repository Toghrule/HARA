import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/language_menu.dart';
import '../../../../l10n/app_localizations.dart';
import '../form_validators.dart';
import '../password_field.dart';

/// Sign-in for restaurant owners and waiters.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).signIn(email: _email.text.trim(), password: _password.text);
      if (mounted) context.go('/venue');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
        _error = error is DioException && error.response?.statusCode == 401
            ? l10n.wrongCredentials
            : apiErrorMessage(error, l10n);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final validators = FormValidators(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.signIn), actions: const [LanguageMenu()]),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    key: const Key('email'),
                    controller: _email,
                    enabled: !_submitting,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(labelText: l10n.emailLabel, border: const OutlineInputBorder()),
                    validator: validators.email,
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    key: const Key('password'),
                    controller: _password,
                    label: l10n.passwordLabel,
                    enabled: !_submitting,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    validator: validators.existingPassword,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    key: const Key('submit'),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.signIn),
                  ),
                  const SizedBox(height: 16),
                  Center(child: Text(l10n.noAccountYet, style: theme.textTheme.bodyMedium)),
                  TextButton(onPressed: () => context.pushReplacement('/register-owner'), child: Text(l10n.registerAsOwner)),
                  TextButton(onPressed: () => context.pushReplacement('/register-staff'), child: Text(l10n.registerAsStaff)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
