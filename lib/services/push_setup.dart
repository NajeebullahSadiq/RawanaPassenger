import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rawana_core/rawana_core.dart';
import '../firebase_options.dart';

Future<void> setupPushNotifications({
  required WidgetRef ref,
  required GoRouter router,
  required Future<void> Function(String token) registerToken,
  void Function()? onTripEvent,
}) async {
  final push = PushNotificationService.instance;
  final ok = await push.initialize(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (!ok) return;

  push.onMessage = (data, {foreground = false}) {
    onTripEvent?.call();
    final route = push.routeForData(
      data,
      role: 'passenger',
      foreground: foreground,
    );
    if (route != null) router.go(route);
  };

  final token = await push.getToken();
  if (token != null) {
    await registerToken(token);
  }

  FirebaseMessaging.instance.onTokenRefresh.listen(registerToken);
}
