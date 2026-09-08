import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/profile_providers.dart';
import '../providers/trip_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(notificationsInboxProvider);
    return Scaffold(
      backgroundColor: RawanaColors.surface,
      appBar: AppBar(title: Text(context.l10n.notifications)),
      body: inbox.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) => NotificationInboxList(
          notifications: items,
          onOpen: (_) {},
          onMarkRead: (id) async {
            await ref.read(passengerServiceProvider).markNotificationRead(id);
            ref.invalidate(notificationsInboxProvider);
          },
        ),
      ),
    );
  }
}
