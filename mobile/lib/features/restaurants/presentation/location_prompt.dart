import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_service.dart';
import '../../../core/location/user_location_provider.dart';
import '../../../l10n/app_localizations.dart';

/// At first launch: says what location is for and asks, once. Whatever the answer, the restaurants are all there; saying no
/// only means no sorting by distance. Does nothing if this build has no location, or the person was already asked.
Future<void> askForLocationOnce(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(userLocationProvider.notifier);
  await controller.ready;
  if (!context.mounted || !controller.shouldExplain) return;

  final l10n = AppLocalizations.of(context);
  final allow = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const Key('locationExplain'),
      icon: const Icon(Icons.near_me_outlined),
      title: Text(l10n.locationExplainTitle),
      content: Text(l10n.locationExplainBody),
      actions: [
        TextButton(key: const Key('locationNotNow'), onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.locationNotNow)),
        FilledButton(key: const Key('locationAllow'), onPressed: () => Navigator.pop(dialogContext, true), child: Text(l10n.locationAllow)),
      ],
    ),
  );

  if (allow == true) {
    await controller.request();
  } else {
    await controller.markAsked();
  }
}

/// The person picked "Nearest": makes sure the phone's position is known, asking for permission if that is still possible.
/// Returns whether sorting by distance can go ahead; if not, says why.
Future<bool> ensureLocationForNearest(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(userLocationProvider.notifier);
  await controller.ready;
  if (!context.mounted) return false;

  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  void say(String text, {SnackBarAction? action}) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), action: action));

  var access = ref.read(userLocationProvider).access;
  if (access == LocationAccess.denied) access = await controller.request();

  switch (access) {
    case LocationAccess.granted:
      if (ref.read(userLocationProvider).position == null) await controller.refreshPosition();
      if (ref.read(userLocationProvider).position != null) return true;

      say(l10n.locationUnavailable);
      return false;
    case LocationAccess.deniedForever:
      say(l10n.locationDeniedForever, action: SnackBarAction(label: l10n.locationOpenSettings, onPressed: controller.openSettings));
      return false;
    case LocationAccess.serviceOff:
      say(l10n.locationServiceOff, action: SnackBarAction(label: l10n.locationOpenSettings, onPressed: controller.openSettings));
      return false;
    case LocationAccess.denied:
      // Refused just now: nothing to add, they know.
      return false;
  }
}
