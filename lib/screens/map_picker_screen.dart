import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';

import '../providers/live_location_providers.dart';
import '../providers/trip_providers.dart';

class MapPickerScreen extends ConsumerStatefulWidget {
  const MapPickerScreen({
    super.key,
    required this.mode,
    this.initialLat,
    this.initialLng,
  });

  final String mode;
  final double? initialLat;
  final double? initialLng;

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  LatLng? _selected;
  /// Camera center set once — do not bind to [_selected] or pan fights the user.
  LatLng? _mapCenter;
  String _address = '';
  bool _loadingAddress = false;
  bool _confirming = false;
  Timer? _reverseDebounce;

  bool get _isPickup => widget.mode == 'pickup';
  bool get _isSaved => widget.mode == 'saved';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setInitialLocation());
  }

  @override
  void dispose() {
    _reverseDebounce?.cancel();
    super.dispose();
  }

  Future<void> _setInitialLocation() async {
    if (widget.initialLat != null && widget.initialLng != null) {
      final point = LatLng(widget.initialLat!, widget.initialLng!);
      setState(() => _mapCenter = point);
      _updateSelection(point, immediate: true);
      return;
    }
    final pos = await LocationService.getCurrentPosition();
    if (!mounted) return;
    final point = LatLng(
      pos?.lat ?? RawanaConstants.kabulLat,
      pos?.lng ?? RawanaConstants.kabulLng,
    );
    setState(() => _mapCenter = point);
    _updateSelection(point, immediate: true);
  }

  void _updateSelection(LatLng point, {bool immediate = false}) {
    setState(() => _selected = point);
    _reverseDebounce?.cancel();
    if (immediate) {
      _reverseGeocode(point);
      return;
    }
    _reverseDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _reverseGeocode(point),
    );
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _loadingAddress = true);
    try {
      final place = await ref
          .read(mapsServiceProvider)
          .reverseGeocode(point.latitude, point.longitude);
      if (!mounted) return;
      setState(() {
        _address = place.address.isNotEmpty
            ? place.address
            : '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _address =
            '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      });
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  Future<void> _confirm() async {
    final point = _selected;
    if (point == null) return;
    setState(() => _confirming = true);
    try {
      final place = await ref
          .read(mapsServiceProvider)
          .reverseGeocode(point.latitude, point.longitude);
      if (!mounted) return;
      context.pop(
        PlaceDetails(
          address: place.address.isNotEmpty ? place.address : _address,
          lat: point.latitude,
          lng: point.longitude,
        ),
      );
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final title = _isPickup
        ? context.l10n.choosePickup
        : _isSaved
            ? context.l10n.chooseSavedPlace
            : context.l10n.chooseDestination;
    final actionLabel = _isPickup
        ? context.l10n.useThisPickup
        : _isSaved
            ? context.l10n.useThisLocation
            : context.l10n.useThisDestination;
    final addressText = _address.isEmpty ? context.l10n.moveMapToChoose : _address;
    final liveLoc = ref.watch(passengerLiveLocationProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: RawanaCircleIconButton(
            icon: LucideIcons.arrowLeft,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: Stack(
        children: [
          RawanaMap(
            zoom: 16,
            centerLat: _mapCenter?.latitude ?? selected?.latitude,
            centerLng: _mapCenter?.longitude ?? selected?.longitude,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: [
              if (liveLoc != null)
                RawanaMapMarker.you(lat: liveLoc.lat, lng: liveLoc.lng),
            ],
            onTap: _updateSelection,
            onCameraMove: _updateSelection,
          ),
          Center(
            child: Transform.translate(
              offset: const Offset(0, -22),
              child: Icon(
                _isPickup ? LucideIcons.mapPin : LucideIcons.flag,
                size: 44,
                color: _isPickup
                    ? RawanaColors.primary
                    : RawanaColors.dropoffPin,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: RawanaSurfaceCard(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        RawanaPillBadge(
                          label: title,
                          icon: _isPickup
                              ? LucideIcons.mapPin
                              : LucideIcons.flag,
                          color: _isPickup
                              ? RawanaColors.primary
                              : RawanaColors.dropoffPin,
                        ),
                        const Spacer(),
                        if (_loadingAddress)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      addressText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.tapOrDragMap,
                      style: const TextStyle(
                        color: RawanaColors.onSurfaceMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RawanaPrimaryButton(
                      label: _confirming ? context.l10n.confirming : actionLabel,
                      icon: LucideIcons.check,
                      loading: _confirming,
                      onPressed: selected == null || _confirming
                          ? null
                          : _confirm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
