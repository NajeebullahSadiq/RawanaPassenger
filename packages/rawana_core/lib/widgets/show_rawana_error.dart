import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../firebase/crash_reporting.dart';
import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';
import 'ui/rawana_action_sheet.dart';

/// Shows a short, readable explanation instead of a raw server exception.
Future<void> showRawanaError(BuildContext context, Object error) {
  CrashReporting.recordIfUnexpected(error);
  return RawanaActionSheet.info(
    context,
    title: context.l10n.friendlyApiError(error),
    actionLabel: context.l10n.dialogOk,
    icon: LucideIcons.circleAlert,
    tone: RawanaColors.error,
  );
}

/// Brief, non-blocking confirmation ("Saved", "Report sent").
void showRawanaToast(
  BuildContext context,
  String message, {
  bool error = false,
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(label: actionLabel, onPressed: onAction, textColor: RawanaColors.accent)
            : null,
        content: Row(
          children: [
            Icon(
              icon ?? (error ? LucideIcons.circleAlert : LucideIcons.circleCheck),
              size: 18,
              color: error ? RawanaColors.errorSoft : RawanaColors.successSoft,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

Future<void> showRawanaMessage(BuildContext context, String message) {
  return RawanaActionSheet.info(
    context,
    title: message,
    actionLabel: context.l10n.dialogOk,
    icon: LucideIcons.info,
  );
}
