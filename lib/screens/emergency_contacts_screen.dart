import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/profile_providers.dart';
import '../providers/trip_providers.dart';

const _maxContacts = 3;

class EmergencyContactsScreen extends ConsumerWidget {
  const EmergencyContactsScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final saved = await RawanaActionSheet.custom<bool>(
      context,
      _ContactEditor(service: ref.read(passengerServiceProvider)),
    );
    if (saved != true || !context.mounted) return;
    ref.invalidate(emergencyContactsProvider);
    showRawanaToast(context, context.l10n.contactSaved, icon: LucideIcons.circleCheck);
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, Map<String, dynamic> contact) async {
    final l10n = context.l10n;
    final ok = await RawanaActionSheet.confirm(
      context,
      title: l10n.removeContactQuestion,
      message: l10n.removeContactMessage(contact['name'] as String? ?? ''),
      confirmLabel: l10n.removeLabel,
      cancelLabel: l10n.cancel,
      destructive: true,
      icon: LucideIcons.userMinus,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(passengerServiceProvider).deleteEmergencyContact(contact['id'] as String);
      ref.invalidate(emergencyContactsProvider);
    } catch (e) {
      if (context.mounted) showRawanaError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final contactsAsync = ref.watch(emergencyContactsProvider);
    final contacts = contactsAsync.valueOrNull;
    final canAdd = contacts == null || contacts.length < _maxContacts;
    return RawanaScaffold(
      title: l10n.emergencyContacts,
      floatingActionButton: canAdd && contacts != null && contacts.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _add(context, ref),
              icon: const Icon(LucideIcons.plus),
              label: Text(l10n.add),
              backgroundColor: RawanaColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: RawanaAsyncBody<List<Map<String, dynamic>>>(
        data: contacts,
        error: contactsAsync.error,
        onRetry: () => ref.invalidate(emergencyContactsProvider),
        onRefresh: () => ref.refresh(emergencyContactsProvider.future),
        isEmpty: (items) => items.isEmpty,
        empty: RawanaEmptyState(
          icon: LucideIcons.shieldAlert,
          tone: RawanaColors.error,
          title: l10n.noContactsYet,
          message: l10n.emergencyContactsEmptyHint,
          action: RawanaPrimaryButton(
            label: l10n.addEmergencyContact,
            icon: LucideIcons.userPlus,
            onPressed: () => _add(context, ref),
          ),
        ),
        builder: (context, items) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            RawanaBanner(
              icon: LucideIcons.shieldCheck,
              message: items.length >= _maxContacts
                  ? l10n.maxContactsReached
                  : '${l10n.emergencyContactsHint} · ${l10n.emergencyContactsCount('${items.length}', '$_maxContacts')}',
            ),
            const SizedBox(height: 16),
            RawanaSettingsSection(
              children: [
                for (final contact in items)
                  RawanaSettingsTile(
                    icon: LucideIcons.user,
                    title: contact['name'] as String? ?? '',
                    subtitle: contact['phone'] as String? ?? '',
                    trailing: IconButton(
                      tooltip: l10n.removeLabel,
                      icon: const Icon(LucideIcons.trash2, size: 18, color: RawanaColors.error),
                      onPressed: () => _remove(context, ref, contact),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactEditor extends StatefulWidget {
  const _ContactEditor({required this.service});

  final PassengerService service;

  @override
  State<_ContactEditor> createState() => _ContactEditorState();
}

class _ContactEditorState extends State<_ContactEditor> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  static bool _phoneValid(String raw) {
    final value = raw.trim();
    if (!RegExp(r'^\+?[\d\s()-]+$').hasMatch(value)) return false;
    final digits = value.replaceAll(RegExp(r'\D'), '').length;
    return digits >= 7 && digits <= 15;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.addEmergencyContact(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = context.l10n.friendlyApiError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.addEmergencyContact, style: context.text.headline),
          const SizedBox(height: 4),
          Text(l10n.maxEmergencyContacts, style: context.text.caption),
          const SizedBox(height: 16),
          RawanaTextField(
            controller: _nameController,
            label: l10n.name,
            prefixIcon: LucideIcons.user,
            autofocus: true,
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (v) => (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
          ),
          const SizedBox(height: 12),
          RawanaTextField(
            controller: _phoneController,
            label: l10n.phone,
            hint: '+93 70 123 4567',
            prefixIcon: LucideIcons.phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d+\s()-]')),
              LengthLimitingTextInputFormatter(20),
            ],
            validator: (v) => _phoneValid(v ?? '') ? null : l10n.contactPhoneInvalid,
            onSubmitted: (_) => _saving ? null : _save(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            RawanaBanner.error(message: _error!),
          ],
          const SizedBox(height: 20),
          RawanaPrimaryButton(
            label: l10n.saveContact,
            icon: LucideIcons.userPlus,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
