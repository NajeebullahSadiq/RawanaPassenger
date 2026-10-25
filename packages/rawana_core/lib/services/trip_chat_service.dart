import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';

class TripMessage {
  const TripMessage({
    required this.id,
    required this.senderRole,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.pending = false,
    this.failed = false,
  });

  final String id;
  final String senderRole;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool pending;
  final bool failed;

  factory TripMessage.fromJson(Map<String, dynamic> json) => TripMessage(
        id: json['id'] as String,
        senderRole: json['sender_role'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
                DateTime.now(),
        readAt: DateTime.tryParse(json['read_at'] as String? ?? '')?.toLocal(),
      );

  TripMessage copyWith({bool? pending, bool? failed}) => TripMessage(
        id: id,
        senderRole: senderRole,
        body: body,
        createdAt: createdAt,
        readAt: readAt,
        pending: pending ?? this.pending,
        failed: failed ?? this.failed,
      );
}

class TripChatThread {
  const TripChatThread({required this.messages, required this.canSend});

  final List<TripMessage> messages;
  final bool canSend;
}

/// In-app passenger ↔ driver chat for an active trip.
class TripChatService {
  TripChatService(this._api);

  final ApiClient _api;

  Future<TripChatThread> fetch(String tripId) async {
    final data = await _api.get('/rides/$tripId/messages');
    final list = data['messages'] as List<dynamic>? ?? const [];
    return TripChatThread(
      messages: list
          .map((e) => TripMessage.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      canSend: data['can_send'] == true,
    );
  }

  Future<TripMessage> send(String tripId, String body) async {
    final data = await _api.post('/rides/$tripId/messages', data: {'body': body});
    return TripMessage.fromJson(
      Map<String, dynamic>.from(data['message'] as Map),
    );
  }

  Future<void> markRead(String tripId) async {
    await _api.post('/rides/$tripId/messages/read');
  }

  Future<int> unreadCount(String tripId) async {
    final data = await _api.get('/rides/$tripId/messages/unread-count');
    return (data['unread'] as num?)?.toInt() ?? 0;
  }
}

/// Polls the unread chat count for the trip currently on screen.
class TripChatUnreadPoller {
  TripChatUnreadPoller(
    this._service, {
    this.interval = const Duration(seconds: 6),
  });

  final TripChatService _service;
  final Duration interval;
  final ValueNotifier<int> unread = ValueNotifier<int>(0);
  String? _tripId;
  Timer? _timer;
  bool _paused = false;

  /// Safe to call from `build`; the first poll is deferred to a microtask.
  void track(String? tripId) {
    if (tripId == _tripId) return;
    _tripId = tripId;
    _timer?.cancel();
    _timer = null;
    scheduleMicrotask(() {
      if (_tripId != tripId) return;
      unread.value = 0;
      if (tripId == null) return;
      refresh();
      _timer = Timer.periodic(interval, (_) => refresh());
    });
  }

  /// Stops polling while the chat screen itself is open.
  void pause() => _paused = true;

  void resume() {
    _paused = false;
    refresh();
  }

  Future<void> refresh() async {
    final tripId = _tripId;
    if (tripId == null || _paused) return;
    try {
      final count = await _service.unreadCount(tripId);
      if (tripId == _tripId && !_paused) unread.value = count;
    } catch (_) {}
  }

  void clear() => unread.value = 0;

  void dispose() {
    _timer?.cancel();
    unread.dispose();
  }
}
