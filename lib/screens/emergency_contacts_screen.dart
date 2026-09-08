import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/profile_providers.dart';
import '../providers/trip_providers.dart';

class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends ConsumerState<EmergencyContactsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _addContact() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) return;

    setState(() => _adding = true);
    try {
      await ref.read(passengerServiceProvider).addEmergencyContact(name: name, phone: phone);
      ref.invalidate(emergencyContactsProvider);
      _nameController.clear();
      _phoneController.clear();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _deleteContact(String id) async {
    try {
      await ref.read(passengerServiceProvider).deleteEmergencyContact(id);
      ref.invalidate(emergencyContactsProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(RawanaSpacing.radiusXl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RawanaSheetHandle(),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                ctx.l10n.addEmergencyContact,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                ctx.l10n.maxEmergencyContacts,
                style: const TextStyle(color: RawanaColors.onSurfaceMuted, fontSize: 13),
              ),
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: ctx.l10n.name,
                prefixIcon: const Icon(LucideIcons.user, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: ctx.l10n.phone,
                prefixIcon: const Icon(LucideIcons.phone, size: 18),
              ),
            ),
            const SizedBox(height: 20),
            RawanaPrimaryButton(
              label: ctx.l10n.saveContact,
              icon: LucideIcons.userPlus,
              loading: _adding,
              onPressed: _adding ? null : _addContact,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(emergencyContactsProvider);
    return Scaffold(
      backgroundColor: RawanaColors.surface,
      appBar: AppBar(
        title: Text(context.l10n.emergencyContacts),
        bottom: contactsAsync.maybeWhen(
          data: (contacts) => PreferredSize(
            preferredSize: const Size.fromHeight(28),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                contacts.length >= 3
                    ? context.l10n.maxContactsReached
                    : context.l10n.emergencyContactsCount('${contacts.length}', '3'),
                style: const TextStyle(fontSize: 12, color: RawanaColors.onSurfaceMuted),
              ),
            ),
          ),
          orElse: () => null,
        ),
      ),
      floatingActionButton: contactsAsync.maybeWhen(
        data: (contacts) {
          if (contacts.length >= 3) return null;
          return FloatingActionButton.extended(
            onPressed: _showAddSheet,
            icon: const Icon(LucideIcons.plus),
            label: Text(context.l10n.add),
            backgroundColor: RawanaColors.primary,
            foregroundColor: Colors.white,
          );
        },
        orElse: () => FloatingActionButton.extended(
          onPressed: _showAddSheet,
          icon: const Icon(LucideIcons.plus),
          label: Text(context.l10n.add),
          backgroundColor: RawanaColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
      body: contactsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.failedToLoadContacts('$e'))),
        data: (contacts) {
          if (contacts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        color: RawanaColors.error.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.shieldAlert, color: RawanaColors.error, size: 38),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.noContactsYet,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.emergencyContactsEmptyHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: RawanaColors.onSurfaceMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: contacts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final contact = contacts[i];
              return RawanaSurfaceCard(
                shadows: const [],
                border: Border.all(color: RawanaColors.divider),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: RawanaColors.primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.user, color: RawanaColors.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact['name'] as String? ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            contact['phone'] as String? ?? '',
                            style: const TextStyle(color: RawanaColors.onSurfaceMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 18, color: RawanaColors.error),
                      onPressed: () => _deleteContact(contact['id'] as String),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
