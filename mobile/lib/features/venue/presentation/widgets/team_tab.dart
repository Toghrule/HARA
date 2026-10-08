import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/venue_models.dart';
import '../../data/venue_repository.dart';
import '../providers/venue_providers.dart';

/// The owner's team: waiters waiting for approval first, then everyone else.
class TeamTab extends ConsumerWidget {
  const TeamTab({super.key});

  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);

    try {
      await action();
      ref.invalidate(venueStaffProvider);
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(error, l10n))));
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, StaffMember member) async {
    final l10n = AppLocalizations.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.removeStaffTitle(member.fullName)),
        content: Text(l10n.removeStaffBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(
            key: const Key('removeDialogYes'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.removeStaff),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;

    await _run(context, ref, () => ref.read(venueRepositoryProvider).removeStaff(member.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final staffAsync = ref.watch(venueStaffProvider);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(venueStaffProvider.future),
      child: staffAsync.when(
        data: (members) {
          final waiting = members.where((member) => member.status == MemberStatus.pending).toList();
          final team = members.where((member) => member.status != MemberStatus.pending).toList();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (waiting.isNotEmpty) ...[
                _Heading(l10n.waitingForYou),
                for (final member in waiting)
                  ListTile(
                    key: Key('member-${member.id}'),
                    title: Text(member.fullName),
                    subtitle: Text([member.email, if (member.phoneNumber != null) member.phoneNumber!].join('\n')),
                    isThreeLine: member.phoneNumber != null,
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          key: Key('approve-${member.id}'),
                          tooltip: l10n.approve,
                          icon: Icon(Icons.check_circle_outline, color: Colors.green.shade700),
                          onPressed: () => _run(context, ref, () => ref.read(venueRepositoryProvider).approveStaff(member.id)),
                        ),
                        IconButton(
                          key: Key('decline-${member.id}'),
                          tooltip: l10n.decline,
                          icon: Icon(Icons.cancel_outlined, color: theme.colorScheme.error),
                          onPressed: () => _run(context, ref, () => ref.read(venueRepositoryProvider).rejectStaff(member.id)),
                        ),
                      ],
                    ),
                  ),
                const Divider(),
              ],
              _Heading(l10n.teamMembers),
              for (final member in team)
                ListTile(
                  key: Key('member-${member.id}'),
                  title: Text(member.fullName),
                  subtitle: Text(
                    [
                      member.isOwner ? l10n.roleOwner : l10n.roleStaff,
                      if (member.status == MemberStatus.rejected) l10n.declinedLabel,
                      member.email,
                    ].join(' · '),
                  ),
                  trailing: member.isOwner
                      ? null
                      : IconButton(
                          key: Key('remove-${member.id}'),
                          tooltip: l10n.removeStaff,
                          icon: const Icon(Icons.person_remove_outlined),
                          onPressed: () => _remove(context, ref, member),
                        ),
                ),
              if (team.every((member) => member.isOwner) && waiting.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.noStaffYet, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorView(
          message: apiErrorMessage(error, l10n),
          onRetry: () => ref.invalidate(venueStaffProvider),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}
