import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';

import '../providers/live_location_providers.dart';
import '../providers/nearby_drivers_provider.dart';
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
  /// Where the camera opened. Never rebound to the selection, or the map would
  /// fight the user's drag.
  LatLng? _mapCenter;

  /// Point under the centre pin once the camera settles.
  LatLng? _selected;

  /// Live camera target while the user is dragging.
  LatLng? _cameraTarget;
  bool _moving = false;
  String _address = '';
  LatLng? _addressFor;
  bool _loadingAddress = false;
  bool _confirming = false;
  int _geocodeToken = 0;
  int _recenterRevision = 0;

  /// Last step before requesting: fine-tune where the driver should stop.
  bool get _isConfirm => widget.mode == 'confirm_pickup';
  bool get _isPickup => widget.mode == 'pickup' || _isConfirm;
  bool get _isSaved => widget.mode == 'saved';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setInitialLocation());
  }

  Future<void> _setInitialLocation() async {
    LatLng point;
    if (widget.initialLat != null && widget.initialLng != null) {
      point = LatLng(widget.initialLat!, widget.initialLng!);
    } else {
      final live = ref.read(passengerLiveLocationProvider);
      final pos = live ?? await LocationService.getCurrentPosition();
      if (!mounted) return;
      point = LatLng(
        pos?.lat ?? RawanaConstants.kabulLat,
        pos?.lng ?? RawanaConstants.kabulLng,
      );
    }
    setState(() {
      _mapCenter = point;
      _selected = point;
      _cameraTarget = point;
    });
    _reverseGeocode(point);
  }

  void _onCameraMove(LatLng target) {
    _cameraTarget = target;
    if (!_moving) setState(() => _moving = true);
  }

  void _onCameraIdle() {
    final target = _cameraTarget;
    if (target == null) return;
    final unchanged = _selected != null &&
        (_selected!.latitude - target.latitude).abs() < 1e-6 &&
        (_selected!.longitude - target.longitude).abs() < 1e-6;
    setState(() {
      _moving = false;
      _selected = target;
    });
    if (!unchanged || _addressFor != target) _reverseGeocode(target);
  }

  Future<void> _reverseGeocode(LatLng point) async {
    final token = ++_geocodeToken;
    setState(() => _loadingAddress = true);
    String address;
    try {
      final place = await ref
          .read(mapsServiceProvider)
          .reverseGeocode(point.latitude, point.longitude);
      address = place.address;
    } catch (_) {
      address = '';
    }
    // A newer drag already started another lookup; drop this stale answer.
    if (!mounted || token != _geocodeToken) return;
    setState(() {
      _address = address.isNotEmpty
          ? address
          : '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      _addressFor = point;
      _loadingAddress = false;
    });
  }

  Future<void> _confirm() async {
    final point = _selected;
    if (point == null || _moving) return;
    if (_addressFor != point || _loadingAddress) {
      setState(() => _confirming = true);
      await _reverseGeocode(point);
      if (!mounted) return;
      setState(() => _confirming = false);
    }
    if (!mounted) return;
    context.pop(
      PlaceDetails(address: _address, lat: point.latitude, lng: point.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isConfirm
        ? context.l10n.confirmPickupTitle
        : _isPickup
        ? context.l10n.choosePickup
        : _isSaved
            ? context.l10n.chooseSavedPlace
            : context.l10n.chooseDestination;
    final actionLabel = _isConfirm
        ? context.l10n.confirmPickup
        : _isPickup
        ? context.l10n.useThisPickup
        : _isSaved
            ? context.l10n.useThisLocation
            : context.l10n.useThisDestination;
    final pinColor = _isPickup ? RawanaColors.pickupPin : RawanaColors.dropoffPin;
    final addressText = _moving
        ? context.l10n.movingMap
        : _address.isEmpty
            ? context.l10n.moveMapToChoose
            : _address;
    final liveLoc = ref.watch(passengerLiveLocationProvider);
    final nearbyDrivers =
        _isConfirm ? ref.watch(nearbyDriversProvider) : const <NearbyDriver>[];
    final center = _mapCenter;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: RawanaCircleIconButton(
            icon: RawanaIcons.back,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: center == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                RawanaMap(
                  zoom: 17,
                  centerLat: center.latitude,
                  centerLng: center.longitude,
                  myLocationEnabled: liveLoc != null,
                  recenterRevision: _recenterRevision,
                  markers: [
                    ...buildNearbyDriverMarkers(nearbyDrivers),
                    if (liveLoc != null)
                      RawanaMapMarker.you(lat: liveLoc.lat, lng: liveLoc.lng),
                  ],
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _onCameraIdle,
                  compassTop:
                      MediaQuery.paddingOf(context).top + kToolbarHeight + 12,
                ),
                IgnorePointer(
                  child: Center(
                    child: RawanaCenterPin(lifted: _moving, color: pinColor, square: !_isPickup),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (liveLoc != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: RawanaCircleIconButton(
                              icon: LucideIcons.locateFixed,
                              tooltip: context.l10n.useCurrentLocation,
                              onPressed: () => setState(() => _recenterRevision++),
                            ),
                          ),
                        RawanaSurfaceCard(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  RawanaPillBadge(
                                    label: title,
                                    icon: _isPickup ? LucideIcons.mapPin : LucideIcons.flag,
                                    color: pinColor,
                                  ),
                                  const Spacer(),
                                  if (_loadingAddress && !_moving)
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 150),
                                opacity: _moving || _loadingAddress ? 0.5 : 1,
                                child: Text(
                                  addressText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.title,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isConfirm
                                    ? context.l10n.confirmPickupHint
                                    : _isPickup
                                    ? context.l10n.pickupSpotHint
                                    : context.l10n.tapOrDragMap,
                                style: context.text.caption,
                              ),
                              const SizedBox(height: 16),
                              RawanaPrimaryButton(
                                label: _confirming ? context.l10n.confirming : actionLabel,
                                icon: LucideIcons.check,
                                loading: _confirming,
                                onPressed: _selected == null || _confirming || _moving
                                    ? null
                                    : _confirm,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
