import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/l10n_extensions.dart';
import '../utils/maps_navigation.dart';

/// Calls the other trip party on the masked Rawana line through the phone's
/// dialer. Shows a snackbar with a retry action when the call cannot start.
Future<void> callTripContact(
  BuildContext context, {
  required ApiClient api,
  required String tripId,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l10n = context.l10n;
  final ok = await dialTripContact(api, tripId);
  if (ok || messenger == null) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(l10n.couldNotStartCall),
      action: SnackBarAction(
        label: l10n.tryAgain,
        onPressed: () async {
          final retried = await dialTripContact(api, tripId);
          if (!retried) {
            messenger.showSnackBar(SnackBar(content: Text(l10n.couldNotStartCall)));
          }
        },
      ),
    ),
  );
}
