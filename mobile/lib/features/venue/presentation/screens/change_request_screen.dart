import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/language_menu.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/form_validators.dart';
import '../../data/venue_me.dart';
import '../../data/venue_repository.dart';

/// The owner asks HARA to change something about their restaurant. They can't edit it directly: fields
/// left empty stay as they are, and HARA reviews what is filled in.
class ChangeRequestScreen extends ConsumerStatefulWidget {
  const ChangeRequestScreen({required this.restaurant, super.key});

  final VenueRestaurant restaurant;

  @override
  ConsumerState<ChangeRequestScreen> createState() => _ChangeRequestScreenState();
}

class _ChangeRequestScreenState extends ConsumerState<ChangeRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _discount = TextEditingController();
  final _description = TextEditingController();
  final _descriptionRu = TextEditingController();
  final _descriptionEn = TextEditingController();
  final _note = TextEditingController();

  bool _submitting = false;
  bool _nothingFilled = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [_name, _address, _phone, _discount, _description, _descriptionRu, _descriptionEn, _note]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _orNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    final anything = [_name, _address, _phone, _discount, _description, _descriptionRu, _descriptionEn].any((c) => c.text.trim().isNotEmpty);

    setState(() {
      _nothingFilled = !anything;
      _error = null;
    });
    if (!formValid || !anything) return;

    final l10n = AppLocalizations.of(context);
    setState(() => _submitting = true);

    try {
      await ref.read(venueRepositoryProvider).createChangeRequest(
            name: _orNull(_name),
            address: _orNull(_address),
            phoneNumber: _orNull(_phone),
            discountPercent: int.tryParse(_discount.text.trim()),
            description: _orNull(_description),
            descriptionRu: _orNull(_descriptionRu),
            descriptionEn: _orNull(_descriptionEn),
            ownerNote: _orNull(_note),
          );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.requestSent)));
      context.pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
        _error = apiErrorMessage(error, l10n);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final validators = FormValidators(l10n);
    final restaurant = widget.restaurant;
    const gap = SizedBox(height: 16);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.requestAChange), actions: const [LanguageMenu()]),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(l10n.changeRequestIntro, style: theme.textTheme.bodyMedium),
                  gap,
                  TextFormField(
                    key: const Key('name'),
                    controller: _name,
                    enabled: !_submitting,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.nameLabel,
                      helperText: l10n.currentValue(restaurant.name),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => validators.optional(value, max: 200),
                  ),
                  gap,
                  TextFormField(
                    key: const Key('address'),
                    controller: _address,
                    enabled: !_submitting,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.addressLabel,
                      helperText: l10n.currentValue(restaurant.address),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => validators.optional(value, max: 400),
                  ),
                  gap,
                  TextFormField(
                    key: const Key('phone'),
                    controller: _phone,
                    enabled: !_submitting,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: l10n.restaurantPhoneLabel, border: const OutlineInputBorder()),
                    validator: (value) => validators.optional(value, max: 50),
                  ),
                  gap,
                  TextFormField(
                    key: const Key('discount'),
                    controller: _discount,
                    enabled: !_submitting,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.discountLabel,
                      helperText: l10n.currentValue('${restaurant.discountPercent}%'),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null;
                      final number = int.tryParse(text);

                      return number == null || number < 0 || number > 100 ? l10n.discountRange : null;
                    },
                  ),
                  gap,
                  for (final (key, controller, label) in [
                    ('description', _description, l10n.descriptionAzLabel),
                    ('descriptionRu', _descriptionRu, l10n.descriptionRuLabel),
                    ('descriptionEn', _descriptionEn, l10n.descriptionEnLabel),
                  ]) ...[
                    TextFormField(
                      key: Key(key),
                      controller: controller,
                      enabled: !_submitting,
                      minLines: 2,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(labelText: label, alignLabelWithHint: true, border: const OutlineInputBorder()),
                      validator: (value) => validators.optional(value, max: 4000),
                    ),
                    gap,
                  ],
                  TextFormField(
                    key: const Key('note'),
                    controller: _note,
                    enabled: !_submitting,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: l10n.noteForHara, border: const OutlineInputBorder()),
                    validator: (value) => validators.optional(value, max: 1000),
                  ),
                  if (_nothingFilled) ...[
                    gap,
                    Text(l10n.askForOneChange, key: const Key('nothingFilled'), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                  ],
                  if (_error != null) ...[
                    gap,
                    Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('submit'),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.sendRequest),
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
