import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';
import 'ui/rawana_action_sheet.dart';

/// Shows a short, readable explanation instead of a raw server exception.
Future<void> showRawanaError(BuildContext context, Object error) {
  return RawanaActionSheet.info(
    context,
    title: context.l10n.friendlyApiError(error),
    actionLabel: context.l10n.dialogOk,
    icon: LucideIcons.circleAlert,
    tone: RawanaColors.error,
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
