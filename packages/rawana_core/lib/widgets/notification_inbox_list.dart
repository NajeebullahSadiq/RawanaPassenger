import 'package:flutter/material.dart';

import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';
import 'rawana_empty_state.dart';
import 'rawana_surface_card.dart';

class NotificationInboxList extends StatelessWidget {
  const NotificationInboxList({
    super.key,
    required this.notifications,
    required this.onOpen,
    this.onMarkRead,
  });

  final List<Map<String, dynamic>> notifications;
  final void Function(Map<String, dynamic> item) onOpen;
  final Future<void> Function(String id)? onMarkRead;

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: RawanaEmptyState(
            icon: Icons.notifications_none_rounded,
            title: context.l10n.noNotificationsYet,
            message: context.l10n.notificationsEmptyHint,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = notifications[index];
        final unread = item['is_read'] != true;
        return RawanaSurfaceCard(
          shadows: const [],
          border: Border.all(color: RawanaColors.divider),
          padding: const EdgeInsets.all(14),
          onTap: () {
            onOpen(item);
            final id = item['id'] as String?;
            if (unread && id != null) onMarkRead?.call(id);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.notifications_rounded,
                color: unread ? RawanaColors.primary : RawanaColors.onSurfaceMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String? ?? '',
                      style: TextStyle(
                        fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['body'] as String? ?? '',
                      style: const TextStyle(
                        color: RawanaColors.onSurfaceMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
