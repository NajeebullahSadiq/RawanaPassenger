import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/app_ui_l10n.dart';
import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';
import 'rawana_empty_state.dart';

/// Inbox feed shared by both apps. Tapping an item marks it read and calls
/// [onOpen] (the screen routes it via `NotificationRouter`).
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

  static IconData iconForType(String? type) {
    final t = type ?? '';
    if (t.startsWith('scheduled_')) return LucideIcons.calendarClock;
    if (t.startsWith('ticket') || t.startsWith('support')) return LucideIcons.lifeBuoy;
    if (t.startsWith('payout') || t.contains('wallet') || t.contains('settlement')) return LucideIcons.wallet;
    if (t.startsWith('maintenance')) return LucideIcons.wrench;
    if (t.startsWith('promo')) return LucideIcons.tag;
    if (t.startsWith('document') || t.contains('approval')) return LucideIcons.fileCheck;
    if (t.startsWith('trip') || t.startsWith('ride') || t.startsWith('driver')) return LucideIcons.car;
    return LucideIcons.bell;
  }

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return RawanaEmptyState(
        icon: LucideIcons.bellOff,
        title: context.l10n.noNotificationsYet,
        message: context.l10n.notificationsEmptyHint,
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = notifications[index];
        return _InboxTile(
          item: item,
          icon: iconForType(item['type'] as String?),
          onTap: () {
            final id = item['id'] as String?;
            if (item['is_read'] != true && id != null) onMarkRead?.call(id);
            onOpen(item);
          },
        );
      },
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({required this.item, required this.icon, required this.onTap});

  final Map<String, dynamic> item;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = item['is_read'] != true;
    final created = DateTime.tryParse(item['sent_at'] as String? ?? item['created_at'] as String? ?? '');
    final radius = BorderRadius.circular(RawanaSpacing.radiusLg);
    return Material(
      color: unread ? RawanaColors.primary.withValues(alpha: 0.04) : Colors.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: unread ? RawanaColors.primary.withValues(alpha: 0.18) : RawanaColors.divider,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (unread ? RawanaColors.primary : RawanaColors.onSurfaceMuted).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(RawanaSpacing.radiusSm),
                ),
                child: Icon(icon, size: 18, color: unread ? RawanaColors.primary : RawanaColors.onSurfaceMuted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['title'] as String? ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: unread ? context.text.bodyStrong : context.text.body,
                          ),
                        ),
                        if (created != null) ...[
                          const SizedBox(width: 8),
                          Text(context.l10n.relativeTime(created), style: context.text.caption),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['body'] as String? ?? '',
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.caption.copyWith(color: RawanaColors.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
              if (unread)
                Container(
                  margin: const EdgeInsetsDirectional.only(start: 8, top: 6),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: RawanaColors.primary, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
