import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase/firebase_initializer.dart';
import '../notifications/notification_router.dart';

typedef PushMessageHandler =
    void Function(Map<String, dynamic> data, {bool foreground});

/// Optional push notifications — skips gracefully when Firebase is not configured.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static FirebaseOptions? _backgroundOptions;

  final _localNotifications = FlutterLocalNotificationsPlugin();
  PushMessageHandler? onMessage;
  bool _initialized = false;

  bool get isAvailable => _initialized;

  /// Background FCM handler (top-level required by Firebase).
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await initializeFirebaseForBackground(_backgroundOptions);
  }

  Future<bool> initialize({FirebaseOptions? options}) async {
    if (_initialized) return true;
    _backgroundOptions = options;
    try {
      var ready = await initializeFirebaseApp(options: options);
      if (!ready && options == null) {
        ready = await initializeFirebaseApp();
      }
      if (!ready) return false;

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _localNotifications.initialize(
        const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: (_) {},
      );

      await FirebaseMessaging.instance.requestPermission();
      FirebaseMessaging.onMessage.listen(_handleForeground);
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _dispatch(m.data));

      _initialized = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: Firebase not configured ($e)');
      }
      return false;
    }
  }

  Future<String?> getToken() async {
    if (!_initialized) return null;
    try {
      return FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  void _handleForeground(RemoteMessage message) {
    _showLocal(message);
    _dispatch(message.data, foreground: true);
  }

  void _dispatch(Map<String, dynamic> data, {bool foreground = false}) {
    onMessage?.call(data, foreground: foreground);
  }

  Future<void> _showLocal(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'rawana_trips',
        'Trip updates',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  /// Informational pushes (e.g. scheduled-ride reminders) only navigate when
  /// tapped; arriving in the foreground must not pull the user off their screen.
  String? routeForData(
    Map<String, dynamic> data, {
    String role = 'passenger',
    bool foreground = false,
  }) {
    final type = data['type'] as String?;
    if (type == null) return null;
    if (foreground && NotificationRouter.isTapOnly(type)) return null;
    return NotificationRouter.routeForType(type, role: role);
  }
}
