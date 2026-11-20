import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../api/api_client.dart';
import '../l10n/app_ui_l10n.dart';
import '../l10n/l10n_extensions.dart';
import '../widgets/show_rawana_error.dart';

bool _handlingExpiry = false;

/// Signs the user out and returns to [authRoute] when the backend rejects a
/// session that can no longer be refreshed.
void installSessionExpiryHandler({
  required GoRouter router,
  required GlobalKey<NavigatorState> navigatorKey,
  required bool Function() isLoggedIn,
  required Future<void> Function() signOut,
  String authRoute = '/auth',
}) {
  ApiClient.onSessionExpired = () async {
    if (_handlingExpiry || !isLoggedIn()) return;
    _handlingExpiry = true;
    try {
      await signOut();
    } catch (_) {
    } finally {
      router.go(authRoute);
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        showRawanaToast(context, context.l10n.errorSessionExpired, error: true);
      }
      _handlingExpiry = false;
    }
  };
}
