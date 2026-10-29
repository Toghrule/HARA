import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../legal/legal_documents.dart';
import '../../../legal/legal_text_screen.dart';
import '../../data/venue_repository.dart';
import '../providers/venue_providers.dart';

/// What a restaurant account sees until it has accepted the current terms: the texts that are new or changed, each with a
/// box, and nothing else. Owners are asked for the terms of use and the restaurant agreement, waiters for the terms of use.
class TermsGateScreen extends ConsumerStatefulWidget {
  const TermsGateScreen({required this.pending, required this.actions, super.key});

  /// What is still to be accepted: `terms` and/or `venueAgreement`, as the server names them.
  final List<String> pending;

  /// The account buttons (language, sign out), which the person can still use.
  final List<Widget> actions;

  @override
  ConsumerState<TermsGateScreen> createState() => _TermsGateScreenState();
}

class _TermsGateScreenState extends ConsumerState<TermsGateScreen> {
  final _ticked = <String>{};
  bool _submitting = false;
  String? _error;

  bool get _allTicked => widget.pending.every(_ticked.contains);

  Future<void> _accept() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(venueRepositoryProvider).acceptTerms(
            termsVersion: widget.pending.contains('terms') ? termsVersion : 0,
            venueAgreementVersion: widget.pending.contains('venueAgreement') ? venueAgreementVersion : 0,
          );
      // Who the person is now has nothing pending, so the app opens.
      ref.invalidate(venueMeProvider);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = apiErrorMessage(error, AppLocalizations.of(context));
      });
    }
  }

  Widget _box(String name, String label, LegalText text) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            key: Key('gate-$name'),
            value: _ticked.contains(name),
            onChanged: _submitting ? null : (value) => setState(() => value == true ? _ticked.add(name) : _ticked.remove(name)),
            title: Text(label),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          TextButton(
            key: Key('gate-read-$name'),
            onPressed: () => context.push(legalTextRoute(text)),
            child: Text(text == LegalText.terms ? AppLocalizations.of(context).termsOfUse : AppLocalizations.of(context).venueAgreementTitle),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.termsGateTitle), actions: widget.actions),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.termsGateBody, key: const Key('gateBody'), style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                if (widget.pending.contains('terms')) _box('terms', l10n.acceptTermsLabel, LegalText.terms),
                if (widget.pending.contains('venueAgreement')) _box('venueAgreement', l10n.acceptAgreementLabel, LegalText.venueAgreement),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, key: const Key('gateError'), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('gateAccept'),
                  onPressed: _submitting || !_allTicked ? null : _accept,
                  child: _submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.termsAcceptButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
