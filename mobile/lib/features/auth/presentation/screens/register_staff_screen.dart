import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/language_menu.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../restaurants/data/restaurant.dart';
import '../../../restaurants/data/restaurants_repository.dart';
import '../form_validators.dart';
import '../password_field.dart';

/// A waiter signs up for the restaurant they work at. That restaurant's owner has to approve them.
class RegisterStaffScreen extends ConsumerStatefulWidget {
  const RegisterStaffScreen({super.key});

  @override
  ConsumerState<RegisterStaffScreen> createState() => _RegisterStaffScreenState();
}

class _RegisterStaffScreenState extends ConsumerState<RegisterStaffScreen> {
  static const _searchDelay = Duration(milliseconds: 400);

  final _formKey = GlobalKey<FormState>();
  final _search = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  Timer? _searchDebounce;
  int _searchGeneration = 0;
  List<Restaurant>? _results;
  Object? _searchError;
  Restaurant? _selected;
  bool _restaurantMissing = false;

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runSearch('');
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    for (final controller in [_search, _fullName, _email, _phone, _password, _confirmPassword]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDelay, () => _runSearch(value));
  }

  Future<void> _runSearch(String term) async {
    final generation = ++_searchGeneration;
    setState(() => _searchError = null);

    try {
      final found = await ref.read(restaurantsRepositoryProvider).getRestaurants(search: term, pageSize: 20);
      // A slower, older search must not overwrite the answer to what is typed now.
      if (mounted && generation == _searchGeneration) setState(() => _results = found);
    } catch (error) {
      if (mounted && generation == _searchGeneration) setState(() => _searchError = error);
    }
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    setState(() => _restaurantMissing = _selected == null);
    if (!formValid || _selected == null) return;

    final l10n = AppLocalizations.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).registerStaff(
            email: _email.text.trim(),
            password: _password.text,
            fullName: _fullName.text.trim(),
            phoneNumber: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            restaurantId: _selected!.id,
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
      appBar: AppBar(title: Text(l10n.registerStaffTitle), actions: const [LanguageMenu()]),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(l10n.registerStaffIntro, style: textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  Text(l10n.yourRestaurantSection, style: textTheme.titleMedium),
                  gap,
                  TextField(
                    key: const Key('restaurantSearch'),
                    controller: _search,
                    enabled: !_submitting,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: l10n.searchHint,
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildResults(l10n),
                  if (_restaurantMissing)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.selectRestaurantRequired,
                        style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 32),
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
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    validator: validators.sameAs(() => _password.text),
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

  Widget _buildResults(AppLocalizations l10n) {
    if (_searchError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(l10n.couldntLoadRestaurants(apiErrorMessage(_searchError!, l10n))),
      );
    }

    final results = _results;
    if (results == null) {
      return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
    }

    if (results.isEmpty) {
      final term = _search.text.trim();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(term.isEmpty ? l10n.noRestaurantsYet : l10n.noRestaurantsMatch(term)),
      );
    }

    return RadioGroup<String>(
      groupValue: _selected?.id,
      onChanged: (id) {
        if (_submitting || id == null) return;

        setState(() {
          _selected = results.firstWhere((restaurant) => restaurant.id == id);
          _restaurantMissing = false;
        });
      },
      child: Column(
        children: [
          for (final restaurant in results)
            RadioListTile<String>(
              key: Key('restaurant-${restaurant.id}'),
              value: restaurant.id,
              title: Text(restaurant.name),
              subtitle: Text(restaurant.address),
              contentPadding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}
