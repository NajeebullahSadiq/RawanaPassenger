import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';

/// Generic empty / error placeholder shown when a screen has no data
/// or fails to load. Pass [action] to render a primary CTA (typically
/// a "Try again" outlined button).
class RawanaEmptyState extends StatelessWidget {
  const RawanaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.tone = RawanaColors.primary,
    this.action,
    this.dense = false,
  });

  /// Variant prewired for error / failure states.
  factory RawanaEmptyState.error({
    Key? key,
    String? title,
    String? message,
    Widget? action,
  }) {
    return RawanaEmptyState(
      key: key,
      icon: LucideIcons.circleAlert,
      title: title ?? '',
      message: message,
      tone: RawanaColors.error,
      action: action,
    );
  }

  final IconData icon;
  final String title;
  final String? message;
  final Color tone;
  final Widget? action;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final double iconBox = dense ? 64 : 80;
    final double iconSize = dense ? 26 : 32;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(dense ? 24 : 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: tone, size: iconSize),
            ),
            SizedBox(height: dense ? 14 : 18),
            Text(
              title.isEmpty ? context.l10n.somethingWentWrong : title,
              textAlign: TextAlign.center,
              style: dense ? context.text.subtitle : context.text.title,
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.body.copyWith(color: RawanaColors.onSurfaceMuted),
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
