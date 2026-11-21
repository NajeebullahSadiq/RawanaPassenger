import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/profile_providers.dart';
import '../providers/trip_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(notificationsInboxProvider);
    final service = ref.read(passengerServiceProvider);
    return RawanaNotificationsView(
      items: inbox.valueOrNull,
      error: inbox.hasError ? inbox.error : null,
      role: 'passenger',
      onRefresh: () => ref.refresh(notificationsInboxProvider.future),
      onMarkRead: (id) async {
        await service.markNotificationRead(id);
        ref.invalidate(notificationsInboxProvider);
      },
      onMarkAllRead: () async {
        try {
          await service.markAllNotificationsRead();
        } catch (e) {
          if (context.mounted) showRawanaError(context, e);
        }
        ref.invalidate(notificationsInboxProvider);
      },
      onOpenRoute: (route) => context.push(route),
    );
  }
}
