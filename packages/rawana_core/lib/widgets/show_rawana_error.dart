import 'package:flutter/material.dart';

import '../l10n/l10n_extensions.dart';

/// Shows a short, readable explanation instead of a raw server exception.
Future<void> showRawanaError(BuildContext context, Object error) {
  return showRawanaMessage(context, context.l10n.friendlyApiError(error));
}

Future<void> showRawanaMessage(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(ctx.l10n.dialogOk),
        ),
      ],
    ),
  );
}
