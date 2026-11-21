import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_client.dart';
import '../l10n/l10n_extensions.dart';
import '../utils/maps_navigation.dart';
import 'show_rawana_error.dart';

/// Calls the other trip party on the masked Rawana line through the phone's
/// dialer. Shows a toast with a retry action when the call cannot start.
Future<void> callTripContact(
  BuildContext context, {
  required ApiClient api,
  required String tripId,
}) async {
  final l10n = context.l10n;
  final ok = await dialTripContact(api, tripId);
  if (ok || !context.mounted) return;
  showRawanaToast(
    context,
    l10n.couldNotStartCall,
    error: true,
    icon: LucideIcons.phoneOff,
    actionLabel: l10n.tryAgain,
    onAction: () async {
      final retried = await dialTripContact(api, tripId);
      if (!retried && context.mounted) {
        showRawanaToast(context, l10n.couldNotStartCall, error: true, icon: LucideIcons.phoneOff);
      }
    },
  );
}
