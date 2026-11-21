import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/auth_provider.dart';

/// Signs in with the shared demo rider account. Throws on failure.
Future<void> passengerDemoLogin(BuildContext context, WidgetRef ref) async {
  final router = GoRouter.of(context);
  final ok = await ref.read(authServiceProvider).demoLogin(role: 'passenger');
  if (!ok) throw RawanaAuthException('supabase_not_configured');
  router.go('/home');
}
