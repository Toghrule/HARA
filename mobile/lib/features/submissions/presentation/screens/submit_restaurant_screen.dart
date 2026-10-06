import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
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
    if (text.isEmpty) return 'This field is required';
    return text.length > max ? 'Too long (max $max characters)' : null;
  }

  String? _optional(String? value, {required int max}) =>
      (value?.trim().length ?? 0) > max ? 'Too long (max $max characters)' : null;

  String? _email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length > 320 || !_emailPattern.hasMatch(text)) return 'Enter a valid email address';
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
      _contactError = hasContact ? null : 'Add an email or a phone number so we can reach you.';
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
          _error = apiErrorMessage(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add your restaurant')),
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
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text('Thank you!', style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'We received your request for "${_restaurantName.text.trim()}". '
            'Our team will review it and get in touch using the contact details you gave us.',
            style: textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Back to restaurants'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    const gap = SizedBox(height: 16);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tell us about your restaurant. We review every request before it appears in HARA.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text('Restaurant', style: textTheme.titleMedium),
          gap,
          TextFormField(
            key: const Key('restaurantName'),
            controller: _restaurantName,
            enabled: !_submitting,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Restaurant name *', border: OutlineInputBorder()),
            validator: (value) => _required(value, max: 200),
          ),
          gap,
          TextFormField(
            key: const Key('address'),
            controller: _address,
            enabled: !_submitting,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
            validator: (value) => _optional(value, max: 400),
          ),
          gap,
          TextFormField(
            key: const Key('restaurantPhone'),
            controller: _restaurantPhone,
            enabled: !_submitting,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Restaurant phone', border: OutlineInputBorder()),
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
            decoration: const InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            validator: (value) => _optional(value, max: 4000),
          ),
          const SizedBox(height: 32),
          Text('About you', style: textTheme.titleMedium),
          gap,
          TextFormField(
            key: const Key('submitterName'),
            controller: _submitterName,
            enabled: !_submitting,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Your name *', border: OutlineInputBorder()),
            validator: (value) => _required(value, max: 200),
          ),
          gap,
          TextFormField(
            key: const Key('submitterEmail'),
            controller: _submitterEmail,
            enabled: !_submitting,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Your email', border: OutlineInputBorder()),
            validator: _email,
          ),
          gap,
          TextFormField(
            key: const Key('submitterPhone'),
            controller: _submitterPhone,
            enabled: !_submitting,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Your phone', border: OutlineInputBorder()),
            validator: (value) => _optional(value, max: 50),
          ),
          const SizedBox(height: 8),
          Text(
            _contactError ?? 'Email or phone — at least one, so we can follow up.',
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
                : const Text('Send request'),
          ),
        ],
      ),
    );
  }
}
