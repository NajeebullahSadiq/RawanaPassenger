import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';
import 'show_rawana_error.dart';

class AccountPrivacyActions extends StatelessWidget {
  const AccountPrivacyActions({
    super.key,
    required this.onExport,
    required this.onDelete,
  });

  final Future<Map<String, dynamic>> Function() onExport;
  final Future<void> Function() onDelete;

  Future<void> _export(BuildContext context) async {
    try {
      final data = await onExport();
      await Clipboard.setData(
        ClipboardData(text: const JsonEncoder.withIndent('  ').convert(data)),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.dataExported)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showRawanaError(context, e);
      }
    }
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.deleteAccount),
        content: Text('${ctx.l10n.deleteAccountConfirm}\n\n${ctx.l10n.deleteAccountWarning}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.l10n.deleteAccount)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await onDelete();
    } catch (e) {
      // The server refuses deletion while a ride is live or cash is unsettled;
      // surface that instead of an unhandled exception.
      if (context.mounted) {
        showRawanaError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.download_outlined, color: RawanaColors.primary),
          title: Text(context.l10n.exportMyData, style: const TextStyle(fontWeight: FontWeight.w700)),
          onTap: () => _export(context),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.delete_outline, color: RawanaColors.error),
          title: Text(
            context.l10n.deleteAccount,
            style: const TextStyle(fontWeight: FontWeight.w700, color: RawanaColors.error),
          ),
          onTap: () => _delete(context),
        ),
      ],
    );
  }
}
