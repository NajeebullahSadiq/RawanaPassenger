import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/profile_providers.dart';
import '../providers/trip_providers.dart';

class SavedAddressesScreen extends ConsumerStatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  ConsumerState<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends ConsumerState<SavedAddressesScreen> {
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  bool _adding = false;
  double? _pickedLat;
  double? _pickedLng;

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
          if (_pickedLat != null) 'lat': _pickedLat!.toString(),
          if (_pickedLng != null) 'lng': _pickedLng!.toString(),
        },
      ).toString(),
    );
    if (result == null || !mounted) return;
    setState(() {
      _pickedLat = result.lat;
      _pickedLng = result.lng;
      if (result.address.isNotEmpty) {
        _addressController.text = result.address;
      }
    });
  }

  Future<void> _addAddress() async {
    final label = _labelController.text.trim();
    final address = _addressController.text.trim();
    if (label.isEmpty || address.isEmpty) return;

    setState(() => _adding = true);
    try {
      var lat = _pickedLat;
      var lng = _pickedLng;
      if (lat == null || lng == null) {
        final pos = await LocationService.getCurrentPosition();
        lat = pos?.lat;
        lng = pos?.lng;
      }
      if (lat == null || lng == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.enableLocationToSaveAddress)),
          );
        }
        return;
      }
      await ref.read(passengerServiceProvider).addSavedAddress(
            label: label,
            address: address,
            lat: lat,
            lng: lng,
          );
      ref.invalidate(savedAddressesProvider);
      _labelController.clear();
      _addressController.clear();
      _pickedLat = null;
      _pickedLng = null;
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _adding = false);
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
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
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  ctx.l10n.saveANewAddress,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                ),
              ),
              Text(
                ctx.l10n.chooseOnMap,
                style: const TextStyle(color: RawanaColors.onSurfaceMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _labelController,
                decoration: InputDecoration(
                  labelText: ctx.l10n.addressLabel,
                  hintText: ctx.l10n.addressLabelHint,
                  prefixIcon: const Icon(LucideIcons.tag, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: ctx.l10n.addressField,
                  prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await _pickOnMap();
                  setSheet(() {});
                },
                icon: const Icon(LucideIcons.mapPin, size: 18),
                label: Text(
                  _pickedLat == null ? ctx.l10n.chooseOnMap : ctx.l10n.useThisLocation,
                ),
              ),
              const SizedBox(height: 20),
              RawanaPrimaryButton(
                label: ctx.l10n.saveAddress,
                icon: LucideIcons.bookmarkPlus,
                loading: _adding,
                onPressed: _adding ? null : _addAddress,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return LucideIcons.home;
      case 'work':
      case 'office':
        return LucideIcons.briefcase;
      case 'gym':
        return LucideIcons.dumbbell;
      default:
        return LucideIcons.bookmark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(savedAddressesProvider);
    return Scaffold(
      backgroundColor: RawanaColors.surface,
      appBar: AppBar(title: Text(context.l10n.savedAddresses)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        icon: const Icon(LucideIcons.plus),
        label: Text(context.l10n.add),
        backgroundColor: RawanaColors.primary,
        foregroundColor: Colors.white,
      ),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.failedToLoadAddresses('$e'))),
        data: (addresses) {
          if (addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        color: RawanaColors.primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.bookmark, color: RawanaColors.primary, size: 38),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.noSavedAddresses,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.savedAddressesEmptyHint,
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
            itemCount: addresses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final item = addresses[i];
              final label = item['label'] as String? ?? '';
              final address = item['address'] as String? ?? '';
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_iconFor(label), color: RawanaColors.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(
                            address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: RawanaColors.onSurfaceMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 18, color: RawanaColors.error),
                      onPressed: () async {
                        await ref.read(passengerServiceProvider).deleteSavedAddress(item['id'] as String);
                        ref.invalidate(savedAddressesProvider);
                      },
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
