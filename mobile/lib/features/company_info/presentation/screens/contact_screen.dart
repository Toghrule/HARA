import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/utils/open_link.dart';
import '../../../../core/widgets/error_view.dart';
import '../../data/contact_info.dart';
import '../providers/company_info_providers.dart';

class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Contact us')),
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
                    child: const Center(child: Text('No contact details yet.')),
                  ),
                ),
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: contacts.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => _ContactTile(contact: contacts[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ErrorView(
            message: apiErrorMessage(error),
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

    return ListTile(
      leading: Icon(
        switch (contact.type) {
          ContactType.phone => Icons.phone_outlined,
          ContactType.email => Icons.email_outlined,
          ContactType.other => Icons.contact_support_outlined,
        },
      ),
      title: Text(contact.title),
      subtitle: Text(contact.value),
      onTap: uri == null ? null : () => openLink(context, uri),
    );
  }
}
