import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/language_menu.dart';
import '../../../../l10n/app_localizations.dart';
import '../form_validators.dart';
import '../password_field.dart';

/// A restaurant owner creates an account and describes the restaurant in one go. The HARA team reviews
/// it; the owner can sign in straight away and sees "waiting for approval" until then.
class RegisterOwnerScreen extends ConsumerStatefulWidget {
  const RegisterOwnerScreen({super.key});

  @override
  ConsumerState<RegisterOwnerScreen> createState() => _RegisterOwnerScreenState();
}

class _RegisterOwnerScreenState extends ConsumerState<RegisterOwnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _restaurantName = TextEditingController();
  final _address = TextEditingController();
  final _restaurantPhone = TextEditingController();
  final _description = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _fullName,
      _email,
      _phone,
      _password,
      _confirmPassword,
      _restaurantName,
      _address,
      _restaurantPhone,
      _description,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _orNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).registerOwner(
            email: _email.text.trim(),
            password: _password.text,
            fullName: _fullName.text.trim(),
            phoneNumber: _orNull(_phone),
            restaurantName: _restaurantName.text.trim(),
            address: _address.text.trim(),
            restaurantPhoneNumber: _orNull(_restaurantPhone),
            description: _orNull(_description),
          );
      if (mounted) context.go('/venue');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
        _error = registrationErrorMessage(error, l10n);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final validators = FormValidators(l10n);
    const gap = SizedBox(height: 16);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.registerOwnerTitle), actions: const [LanguageMenu()]),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(l10n.registerOwnerIntro, style: textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  Text(l10n.sectionAccount, style: textTheme.titleMedium),
                  gap,
                  TextFormField(
                    key: const Key('fullName'),
                    controller: _fullName,
                    enabled: !_submitting,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l10n.yourNameLabel, border: const OutlineInputBorder()),
                    validator: (value) => validators.required(value, max: 200),
                  ),
                  gap,
                  TextFormField(
                    key: const Key('email'),
                    controller: _email,
                    enabled: !_submitting,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: l10n.emailLabel, border: const OutlineInputBorder()),
                    validator: validators.email,
                  ),
                  gap,
                  TextFormField(
                    key: const Key('phone'),
                    controller: _phone,
                    enabled: !_submitting,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: l10n.yourPhoneLabel, border: const OutlineInputBorder()),
                    validator: (value) => validators.optional(value, max: 50),
                  ),
                  gap,
                  PasswordField(
                    key: const Key('password'),
                    controller: _password,
                    label: l10n.passwordLabel,
                    enabled: !_submitting,
                    textInputAction: TextInputAction.next,
                    validator: validators.newPassword,
                  ),
                  gap,
                  PasswordField(
                    key: const Key('confirmPassword'),
                    controller: _confirmPassword,
                    label: l10n.confirmPasswordLabel,
                    enabled: !_submitting,
                    textInputAction: TextInputAction.next,
                    validator: validators.sameAs(() => _password.text),
                  ),
                  const SizedBox(height: 32),
                  Text(l10n.sectionRestaurant, style: textTheme.titleMedium),
                  gap,
                  TextFormField(
                    key: const Key('restaurantName'),
                    controller: _restaurantName,
                    enabled: !_submitting,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: l10n.restaurantNameLabel, border: const OutlineInputBorder()),
                    validator: (value) => validators.required(value, max: 200),
                  ),
                  gap,
                  TextFormField(
                    key: const Key('address'),
                    controller: _address,
                    enabled: !_submitting,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: '${l10n.addressLabel} *', border: const OutlineInputBorder()),
                    validator: (value) => validators.required(value, max: 400),
                  ),
                  gap,
                  TextFormField(
                    key: const Key('restaurantPhone'),
                    controller: _restaurantPhone,
                    enabled: !_submitting,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: l10n.restaurantPhoneLabel, border: const OutlineInputBorder()),
                    validator: (value) => validators.optional(value, max: 50),
                  ),
                  gap,
                  TextFormField(
                    key: const Key('description'),
                    controller: _description,
                    enabled: !_submitting,
                    minLines: 3,
                    maxLines: 6,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      labelText: l10n.descriptionLabel,
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => validators.optional(value, max: 4000),
                  ),
                  if (_error != null) ...[
                    gap,
                    Text(_error!, style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('submit'),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.createAccount),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
