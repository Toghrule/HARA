import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/submissions_repository.dart';

/// "Own a restaurant? Add it to HARA" — an anonymous request the HARA team reviews.
class SubmitRestaurantScreen extends ConsumerStatefulWidget {
  const SubmitRestaurantScreen({super.key});

  @override
  ConsumerState<SubmitRestaurantScreen> createState() => _SubmitRestaurantScreenState();
}

class _SubmitRestaurantScreenState extends ConsumerState<SubmitRestaurantScreen> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _restaurantName = TextEditingController();
  final _address = TextEditingController();
  final _restaurantPhone = TextEditingController();
  final _description = TextEditingController();
  final _submitterName = TextEditingController();
  final _submitterEmail = TextEditingController();
  final _submitterPhone = TextEditingController();

  bool _submitting = false;
  bool _submitted = false;
  String? _contactError;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _restaurantName,
      _address,
      _restaurantPhone,
      _description,
      _submitterName,
      _submitterEmail,
      _submitterPhone,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value, {required int max}) {
    final text = value?.trim() ?? '';
    final l10n = AppLocalizations.of(context);
    if (text.isEmpty) return l10n.fieldRequired;
    return text.length > max ? l10n.tooLong(max) : null;
  }

  String? _optional(String? value, {required int max}) =>
      (value?.trim().length ?? 0) > max ? AppLocalizations.of(context).tooLong(max) : null;

  String? _email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length > 320 || !_emailPattern.hasMatch(text)) return AppLocalizations.of(context).invalidEmail;
    return null;
  }

  String? _orNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    final hasContact = _orNull(_submitterEmail) != null || _orNull(_submitterPhone) != null;

    setState(() {
      _error = null;
      _contactError = hasContact ? null : AppLocalizations.of(context).contactRequired;
    });
    if (!formValid || !hasContact) return;

    setState(() => _submitting = true);
    try {
      await ref.read(submissionsRepositoryProvider).create(
            restaurantName: _restaurantName.text.trim(),
            address: _orNull(_address),
            phoneNumber: _orNull(_restaurantPhone),
            description: _orNull(_description),
            submitterName: _submitterName.text.trim(),
            submitterEmail: _orNull(_submitterEmail),
            submitterPhoneNumber: _orNull(_submitterPhone),
          );
      if (mounted) setState(() => _submitted = true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = apiErrorMessage(error, AppLocalizations.of(context));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).addYourRestaurant)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _submitted ? _buildThanks(context) : _buildForm(context),
          ),
        ),
      ),
    );
  }

  Widget _buildThanks(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(l10n.thankYou, style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            l10n.requestReceived(_restaurantName.text.trim()),
            style: textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/'),
            child: Text(l10n.backToRestaurants),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    const gap = SizedBox(height: 16);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.submitIntro,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text(l10n.sectionRestaurant, style: textTheme.titleMedium),
          gap,
          TextFormField(
            key: const Key('restaurantName'),
            controller: _restaurantName,
            enabled: !_submitting,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.restaurantNameLabel, border: const OutlineInputBorder()),
            validator: (value) => _required(value, max: 200),
          ),
          gap,
          TextFormField(
            key: const Key('address'),
            controller: _address,
            enabled: !_submitting,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.addressLabel, border: const OutlineInputBorder()),
            validator: (value) => _optional(value, max: 400),
          ),
          gap,
          TextFormField(
            key: const Key('restaurantPhone'),
            controller: _restaurantPhone,
            enabled: !_submitting,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.restaurantPhoneLabel, border: const OutlineInputBorder()),
            validator: (value) => _optional(value, max: 50),
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
            validator: (value) => _optional(value, max: 4000),
          ),
          const SizedBox(height: 32),
          Text(l10n.sectionAboutYou, style: textTheme.titleMedium),
          gap,
          TextFormField(
            key: const Key('submitterName'),
            controller: _submitterName,
            enabled: !_submitting,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.yourNameLabel, border: const OutlineInputBorder()),
            validator: (value) => _required(value, max: 200),
          ),
          gap,
          TextFormField(
            key: const Key('submitterEmail'),
            controller: _submitterEmail,
            enabled: !_submitting,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.yourEmailLabel, border: const OutlineInputBorder()),
            validator: _email,
          ),
          gap,
          TextFormField(
            key: const Key('submitterPhone'),
            controller: _submitterPhone,
            enabled: !_submitting,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: l10n.yourPhoneLabel, border: const OutlineInputBorder()),
            validator: (value) => _optional(value, max: 50),
          ),
          const SizedBox(height: 8),
          Text(
            _contactError ?? l10n.contactHint,
            style: textTheme.bodySmall?.copyWith(
              color: _contactError != null ? theme.colorScheme.error : null,
            ),
          ),
          if (_error != null) ...[
            gap,
            Text(_error!, style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.sendRequest),
          ),
        ],
      ),
    );
  }
}
