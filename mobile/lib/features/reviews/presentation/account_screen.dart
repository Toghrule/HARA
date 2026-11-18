import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import 'customer_account_card.dart';

/// "My account": the customer's own place in the app (sign-in with Google, who is signed in, signing out, deleting the account).
/// More things will be added here later.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myAccount)),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        children: const [CustomerAccountCard()],
      ),
    );
  }
}
