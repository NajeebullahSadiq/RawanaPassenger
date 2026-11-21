import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/app_ui_l10n.dart';
import '../l10n/l10n_extensions.dart';
import 'show_rawana_error.dart';
import 'ui/rawana_action_sheet.dart';
import 'ui/rawana_settings.dart';

/// "Your data" settings section: export account data and delete the account.
class AccountPrivacyActions extends StatefulWidget {
  const AccountPrivacyActions({
    super.key,
    required this.onExport,
    required this.onDelete,
    this.title,
  });

  final Future<Map<String, dynamic>> Function() onExport;
  final Future<void> Function() onDelete;

  /// Section heading; defaults to "Your data".
  final String? title;

  @override
  State<AccountPrivacyActions> createState() => _AccountPrivacyActionsState();
}

class _AccountPrivacyActionsState extends State<AccountPrivacyActions> {
  bool _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final data = await widget.onExport();
      await Clipboard.setData(ClipboardData(text: const JsonEncoder.withIndent('  ').convert(data)));
      if (mounted) showRawanaToast(context, context.l10n.dataExported, icon: LucideIcons.clipboardCheck);
    } catch (e) {
      if (mounted) showRawanaError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (_busy) return;
    final l10n = context.l10n;
    final ok = await RawanaActionSheet.confirm(
      context,
      title: l10n.deleteAccount,
      message: '${l10n.deleteAccountConfirm}\n\n${l10n.deleteAccountWarning}',
      confirmLabel: l10n.deleteAccount,
      cancelLabel: l10n.cancel,
      destructive: true,
      icon: LucideIcons.triangleAlert,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.onDelete();
    } catch (e) {
      // The server refuses deletion while a ride is live or cash is unsettled.
      if (mounted) showRawanaError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RawanaSettingsSection(
      title: widget.title ?? l10n.yourData,
      children: [
        RawanaSettingsTile(
          icon: LucideIcons.download,
          title: l10n.exportMyData,
          subtitle: l10n.exportMyDataHint,
          onTap: _busy ? null : _export,
        ),
        RawanaSettingsTile(
          icon: LucideIcons.trash2,
          title: l10n.deleteAccount,
          subtitle: l10n.deleteAccountHint,
          destructive: true,
          onTap: _busy ? null : _delete,
        ),
      ],
    );
  }
}
