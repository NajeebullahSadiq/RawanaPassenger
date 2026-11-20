import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/profile_providers.dart';
import '../providers/trip_providers.dart';

class SavedAddressesScreen extends ConsumerWidget {
  const SavedAddressesScreen({super.key});

  static IconData iconFor(String label) {
    switch (label.trim().toLowerCase()) {
      case 'home':
        return LucideIcons.house;
      case 'work':
      case 'office':
        return LucideIcons.briefcase;
      case 'gym':
        return LucideIcons.dumbbell;
      default:
        return LucideIcons.bookmark;
    }
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, [Map<String, dynamic>? existing]) async {
    final saved = await RawanaActionSheet.custom<bool>(
      context,
      _AddressEditor(existing: existing, service: ref.read(passengerServiceProvider)),
    );
    if (saved != true || !context.mounted) return;
    ref.invalidate(savedAddressesProvider);
    showRawanaToast(
      context,
      existing == null ? context.l10n.addressSaved : context.l10n.addressUpdated,
      icon: LucideIcons.circleCheck,
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Map<String, dynamic> item) async {
    final l10n = context.l10n;
    final ok = await RawanaActionSheet.confirm(
      context,
      title: l10n.deleteAddressQuestion,
      message: l10n.deleteAddressMessage(item['label'] as String? ?? ''),
      confirmLabel: l10n.deleteLabel,
      cancelLabel: l10n.cancel,
      destructive: true,
      icon: LucideIcons.trash2,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(passengerServiceProvider).deleteSavedAddress(item['id'] as String);
      ref.invalidate(savedAddressesProvider);
    } catch (e) {
      if (context.mounted) showRawanaError(context, e);
    }
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref, Map<String, dynamic> item) async {
    final l10n = context.l10n;
    final action = await RawanaActionSheet.menu<String>(
      context,
      title: item['label'] as String? ?? l10n.savedAddresses,
      options: [
        RawanaSheetOption(value: 'edit', label: l10n.editAddress, icon: LucideIcons.pencil),
        RawanaSheetOption(value: 'delete', label: l10n.deleteLabel, icon: LucideIcons.trash2),
      ],
    );
    if (!context.mounted) return;
    if (action == 'edit') await _openEditor(context, ref, item);
    if (action == 'delete') await _delete(context, ref, item);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final addressesAsync = ref.watch(savedAddressesProvider);
    return RawanaScaffold(
      title: l10n.savedAddresses,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(LucideIcons.plus),
        label: Text(l10n.add),
        backgroundColor: RawanaColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RawanaAsyncBody<List<Map<String, dynamic>>>(
        data: addressesAsync.valueOrNull,
        error: addressesAsync.error,
        onRetry: () => ref.invalidate(savedAddressesProvider),
        onRefresh: () => ref.refresh(savedAddressesProvider.future),
        isEmpty: (items) => items.isEmpty,
        empty: RawanaEmptyState(
          icon: LucideIcons.bookmark,
          title: l10n.noSavedAddresses,
          message: l10n.savedAddressesEmptyHint,
          action: RawanaPrimaryButton(
            label: l10n.addAddress,
            icon: LucideIcons.plus,
            onPressed: () => _openEditor(context, ref),
          ),
        ),
        builder: (context, items) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            RawanaSurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shadows: const [],
              border: Border.all(color: RawanaColors.divider),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const PlaceRowDivider(),
                    PlaceRow(
                      icon: iconFor(items[i]['label'] as String? ?? ''),
                      title: items[i]['label'] as String? ?? '',
                      subtitle: items[i]['address'] as String? ?? '',
                      onTap: () => _openEditor(context, ref, items[i]),
                      trailing: IconButton(
                        tooltip: l10n.edit,
                        icon: const Icon(LucideIcons.ellipsisVertical, size: 18, color: RawanaColors.onSurfaceMuted),
                        onPressed: () => _showActions(context, ref, items[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressEditor extends StatefulWidget {
  const _AddressEditor({this.existing, required this.service});

  final Map<String, dynamic>? existing;
  final PassengerService service;

  @override
  State<_AddressEditor> createState() => _AddressEditorState();
}

class _AddressEditorState extends State<_AddressEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _labelController = TextEditingController(text: widget.existing?['label'] as String? ?? '');
  late final _addressController = TextEditingController(text: widget.existing?['address'] as String? ?? '');
  late double? _lat = (widget.existing?['lat'] as num?)?.toDouble();
  late double? _lng = (widget.existing?['lng'] as num?)?.toDouble();
  bool _pinChanged = false;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickOnMap() async {
    final result = await context.push<PlaceDetails>(
      Uri(
        path: '/map-picker',
        queryParameters: {
          'mode': 'saved',
          if (_lat != null) 'lat': _lat!.toString(),
          if (_lng != null) 'lng': _lng!.toString(),
        },
      ).toString(),
    );
    if (result == null || !mounted) return;
    setState(() {
      _lat = result.lat;
      _lng = result.lng;
      _pinChanged = true;
      if (result.address.isNotEmpty) _addressController.text = result.address;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      var lat = _lat;
      var lng = _lng;
      if (lat == null || lng == null) {
        final pos = await LocationService.getCurrentPosition();
        lat = pos?.lat;
        lng = pos?.lng;
      }
      if (!mounted) return;
      if (lat == null || lng == null) {
        setState(() => _error = context.l10n.enableLocationToSaveAddress);
        return;
      }
      final label = _labelController.text.trim();
      final address = _addressController.text.trim();
      if (_editing) {
        await widget.service.updateSavedAddress(
          widget.existing!['id'] as String,
          label: label,
          address: address,
          lat: _pinChanged ? lat : null,
          lng: _pinChanged ? lng : null,
        );
      } else {
        await widget.service.addSavedAddress(label: label, address: address, lat: lat, lng: lng);
      }
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
    final pinned = _lat != null && _lng != null;
    String? required(String? v) => (v ?? '').trim().isEmpty ? l10n.fieldRequired : null;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_editing ? l10n.editAddress : l10n.saveANewAddress, style: context.text.headline),
          const SizedBox(height: 16),
          RawanaTextField(
            controller: _labelController,
            label: l10n.addressLabel,
            hint: l10n.addressLabelHint,
            prefixIcon: LucideIcons.tag,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: required,
          ),
          const SizedBox(height: 12),
          RawanaTextField(
            controller: _addressController,
            label: l10n.addressField,
            prefixIcon: LucideIcons.mapPin,
            maxLength: 200,
            maxLines: 2,
            validator: required,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _saving ? null : _pickOnMap,
            icon: Icon(pinned ? LucideIcons.mapPinCheck : LucideIcons.map, size: 18),
            label: Text(pinned ? l10n.locationPinned : l10n.chooseOnMap),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            RawanaBanner.error(message: _error!),
          ],
          const SizedBox(height: 20),
          RawanaPrimaryButton(
            label: l10n.saveAddress,
            icon: LucideIcons.bookmarkPlus,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
