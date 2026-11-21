import 'package:flutter/material.dart';

import '../l10n/l10n_extensions.dart';
import '../notifications/notification_router.dart';
import '../widgets/notification_inbox_list.dart';
import '../widgets/ui/rawana_async_body.dart';
import '../widgets/ui/rawana_scaffold.dart';

/// Notification inbox page. [onOpenRoute] receives the deep link for a tapped
/// item (from [NotificationRouter]) or null when it has nowhere to go.
class RawanaNotificationsView extends StatelessWidget {
  const RawanaNotificationsView({
    super.key,
    required this.items,
    required this.error,
    required this.role,
    required this.onRefresh,
    required this.onMarkRead,
    required this.onMarkAllRead,
    required this.onOpenRoute,
  });

  final List<Map<String, dynamic>>? items;
  final Object? error;

  /// `passenger` or `driver`, for [NotificationRouter].
  final String role;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String id) onMarkRead;
  final Future<void> Function() onMarkAllRead;
  final void Function(String route) onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final hasUnread = items?.any((n) => n['is_read'] != true) ?? false;
    return RawanaScaffold(
      title: context.l10n.notifications,
      actions: [
        if (hasUnread) TextButton(onPressed: onMarkAllRead, child: Text(context.l10n.markAllRead)),
      ],
      body: RawanaAsyncBody<List<Map<String, dynamic>>>(
        data: items,
        error: error,
        onRefresh: onRefresh,
        builder: (context, list) => NotificationInboxList(
          notifications: list,
          // Read state is cosmetic; a failed update is retried on the next tap.
          onMarkRead: (id) => onMarkRead(id).catchError((_) {}),
          onOpen: (item) {
            final type = item['type'] as String? ?? '';
            // Live-trip events (accepted, arriving...) are stale once read from the inbox.
            if (!type.startsWith('scheduled_') && !type.startsWith('payout')) return;
            final route = NotificationRouter.routeForType(type, role: role);
            if (route != null && route != '/notifications') onOpenRoute(route);
          },
        ),
      ),
    );
  }
}
