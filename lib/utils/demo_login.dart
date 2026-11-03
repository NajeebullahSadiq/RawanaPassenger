import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/auth_provider.dart';

Future<void> performPassengerDemoLogin({
  required BuildContext context,
  required WidgetRef ref,
  required void Function(bool) setLoading,
  required void Function(String?) setError,
}) async {
  setLoading(true);
  setError(null);
  final auth = ref.read(authServiceProvider);
  // Capture localized strings before the first await so no BuildContext is
  // touched after an async gap.
  final l10n = context.l10n;

  try {
    if (!AppConfig.hasSupabase) {
      setError(l10n.demoLoginNeedsSupabase);
      return;
    }
    final ok = await auth.demoLogin(role: 'passenger');
    if (!ok) {
      setError(l10n.demoLoginFailed);
      return;
    }
    if (context.mounted) context.go('/home');
  } on RawanaAuthException catch (e) {
    setError(authErrorMessage(e.messageKey, l10n: l10n));
  } catch (e) {
    setError(l10n.friendlyApiError(e));
  } finally {
    setLoading(false);
  }
}
