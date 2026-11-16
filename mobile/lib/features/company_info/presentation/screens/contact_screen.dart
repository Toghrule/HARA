import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/open_link.dart';
import '../../../../core/widgets/error_view.dart';
import '../../data/contact_info.dart';
import '../providers/company_info_providers.dart';

class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.contactUs)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(contactsProvider.future),
        child: contactsAsync.when(
          data: (contacts) {
            if (contacts.isEmpty) {
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Center(child: Text(l10n.noContactDetails)),
                  ),
                ),
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: contacts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) => _ContactTile(contact: contacts[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ErrorView(
            message: apiErrorMessage(error, l10n),
            onRetry: () => ref.invalidate(contactsProvider),
          ),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact});

  final ContactInfo contact;

  @override
  Widget build(BuildContext context) {
    final uri = contact.uri;

    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        child: Icon(
        switch (contact.type) {
          ContactType.phone => Icons.phone_outlined,
          ContactType.email => Icons.email_outlined,
          ContactType.other => Icons.contact_support_outlined,
        },
          color: scheme.onPrimaryContainer,
        ),
      ),
      title: Text(contact.title(AppLocalizations.of(context)), style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(contact.value),
      trailing: uri == null ? null : const Icon(Icons.chevron_right),
      onTap: uri == null ? null : () => openLink(context, uri),
      ),
    );
  }
}
