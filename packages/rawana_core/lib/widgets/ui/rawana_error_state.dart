import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/rawana_theme.dart';

/// Inline error with an optional retry action, for lists and sheets.
class RawanaErrorState extends StatelessWidget {
  const RawanaErrorState({
    super.key,
    required this.title,
    this.message,
    this.retryLabel,
    this.onRetry,
    this.icon = LucideIcons.circleAlert,
    this.compact = false,
  });

  final String title;
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final action = (onRetry != null && retryLabel != null)
        ? TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: Text(retryLabel!),
          )
        : null;
    if (compact) {
      return Row(
        children: [
          Icon(icon, size: 20, color: RawanaColors.error),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: text.bodyStrong)),
          ?action,
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: RawanaColors.errorSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: RawanaColors.error, size: 26),
          ),
          const SizedBox(height: 14),
          Text(title, style: text.title, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!, style: text.caption, textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 8), action],
        ],
      ),
    );
  }
}
