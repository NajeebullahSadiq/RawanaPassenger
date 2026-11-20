import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/app_ui_l10n.dart';
import '../l10n/l10n_extensions.dart';
import '../widgets/ui/rawana_action_sheet.dart';

/// Explains why location is needed before the OS prompt, and offers Settings
/// when location is off or blocked. Returns whether location is usable.
Future<bool> ensureLocationWithRationale(BuildContext context, {required String reason}) async {
  if (kIsWeb) return true;
  final l10n = context.l10n;
  if (!await Geolocator.isLocationServiceEnabled()) {
    if (!context.mounted) return false;
    final open = await RawanaActionSheet.confirm(
      context,
      title: l10n.locationServicesOffTitle,
      message: l10n.locationServicesOffBody,
      confirmLabel: l10n.openSettings,
      cancelLabel: l10n.notNow,
      icon: LucideIcons.mapPinOff,
    );
    if (open) await Geolocator.openLocationSettings();
    return false;
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    if (!context.mounted) return false;
    final proceed = await RawanaActionSheet.confirm(
      context,
      title: l10n.locationPermissionTitle,
      message: reason,
      confirmLabel: l10n.continueAction,
      cancelLabel: l10n.notNow,
      icon: LucideIcons.mapPin,
    );
    if (!proceed) return false;
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    if (!context.mounted) return false;
    final open = await RawanaActionSheet.confirm(
      context,
      title: l10n.locationBlockedTitle,
      message: l10n.locationBlockedBody,
      confirmLabel: l10n.openSettings,
      cancelLabel: l10n.notNow,
      icon: LucideIcons.mapPinOff,
    );
    if (open) await Geolocator.openAppSettings();
    return false;
  }
  return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
}

/// When notifications are blocked, explains why they matter and offers
/// Settings. Asks the OS first if the user has never been prompted.
Future<bool> ensureNotificationsWithRationale(BuildContext context, {required String reason}) async {
  if (kIsWeb || Firebase.apps.isEmpty) return true;
  try {
    final messaging = FirebaseMessaging.instance;
    var status = (await messaging.getNotificationSettings()).authorizationStatus;
    if (status == AuthorizationStatus.notDetermined) {
      status = (await messaging.requestPermission()).authorizationStatus;
    }
    if (status != AuthorizationStatus.denied) return true;
    if (!context.mounted) return false;
    final l10n = context.l10n;
    final open = await RawanaActionSheet.confirm(
      context,
      title: l10n.notificationsBlockedTitle,
      message: reason,
      confirmLabel: l10n.openSettings,
      cancelLabel: l10n.notNow,
      icon: LucideIcons.bellOff,
    );
    if (open) await Geolocator.openAppSettings();
    return false;
  } catch (_) {
    return true;
  }
}

/// Avoids re-asking on every screen visit after the user said "Not now".
class PermissionPromptGate {
  PermissionPromptGate._();

  static final Set<String> _asked = {};

  static bool shouldAsk(String key) => _asked.add(key);
}