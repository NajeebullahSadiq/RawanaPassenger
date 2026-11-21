import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:rawana_core/rawana_core.dart';

import '../providers/live_location_providers.dart';
import '../providers/nearby_drivers_provider.dart';
import '../providers/trip_providers.dart';
import 'booking_map.dart';

/// Hosts the one map shared by Home, ride options, confirm pickup, searching
/// and the live trip. Each step only draws its sheet on top.
class BookingShell extends StatelessWidget {
  const BookingShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _BookingMapLayer()),
          // Transparent so the map stays tappable around the sheets, but
          // still gives ink splashes a surface above the platform view.
          Positioned.fill(
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ],
      ),
    );
  }
}

class _BookingMapLayer extends ConsumerWidget {
  const _BookingMapLayer();

  VehicleKind _kindFor(WidgetRef ref, String? rideTypeId, String? fallbackKey) {
    if (fallbackKey != null) return VehicleKind.fromIconName(fallbackKey);
    final types = ref.watch(rideTypesProvider).valueOrNull ?? const <RideType>[];
    for (final t in types) {
      if (t.id == rideTypeId) return VehicleKind.fromIconName(t.artKey);
    }
    return VehicleKind.car;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final map = ref.watch(bookingMapProvider);
    final live = ref.watch(passengerLiveLocationProvider);
    final homePickup = ref.watch(homeMapPickupProvider);
    final nearby = ref.watch(nearbyDriversProvider);
    final draft = ref.watch(bookingDraftProvider);
    final l10n = context.l10n;

    final markers = <RawanaMapMarker>[];
    double? centerLat;
    double? centerLng;
    var zoom = 15.5;
    var fit = true;
    double? pulseLat;
    double? pulseLng;
    ValueChanged<LatLng>? onCameraMove;
    VoidCallback? onCameraIdle;

    switch (map.scene) {
      case BookingScene.home:
        fit = false;
        centerLat = homePickup?.lat ?? live?.lat;
        centerLng = homePickup?.lng ?? live?.lng;
        markers.addAll(buildNearbyDriverMarkers(nearby));
        if (live != null) markers.add(RawanaMapMarker.you(lat: live.lat, lng: live.lng, l10n: l10n));
      case BookingScene.rideOptions:
        final kind = _kindFor(ref, draft?.rideTypeId, null);
        markers.addAll(buildNearbyDriverMarkers(nearby, vehicleKind: kind));
        if (map.pickup != null) {
          markers.add(RawanaMapMarker.pickup(lat: map.pickup!.latitude, lng: map.pickup!.longitude, l10n: l10n));
        }
        if (map.dropoff != null) {
          markers.add(RawanaMapMarker.dropoff(lat: map.dropoff!.latitude, lng: map.dropoff!.longitude, l10n: l10n));
        }
      case BookingScene.confirmPickup:
        fit = false;
        zoom = 17.5;
        centerLat = map.pinTarget?.latitude;
        centerLng = map.pinTarget?.longitude;
        markers.addAll(buildNearbyDriverMarkers(nearby, vehicleKind: _kindFor(ref, draft?.rideTypeId, null)));
        onCameraMove = (p) {
          ref.read(bookingPinProvider.notifier).state = p;
          if (!ref.read(bookingPinMovingProvider)) {
            ref.read(bookingPinMovingProvider.notifier).state = true;
          }
        };
        onCameraIdle = () => ref.read(bookingPinMovingProvider.notifier).state = false;
      case BookingScene.searching:
        final kind = _kindFor(ref, draft?.rideTypeId, null);
        markers.addAll(buildNearbyDriverMarkers(nearby, vehicleKind: kind));
        if (map.pickup != null) {
          pulseLat = map.pickup!.latitude;
          pulseLng = map.pickup!.longitude;
          markers.add(RawanaMapMarker.pickup(lat: pulseLat, lng: pulseLng, l10n: l10n));
        }
      case BookingScene.trip:
        final trip = ref.watch(activeTripProvider).valueOrNull;
        final driver = ref.watch(driverLocationProvider);
        final kind = _kindFor(ref, trip?.rideTypeId, trip?.rideArtKey);
        markers.addAll(
          buildTripLiveMarkers(
            passengerLat: map.tripStarted ? null : live?.lat,
            passengerLng: map.tripStarted ? null : live?.lng,
            passengerIsCurrentUser: true,
            driverLat: driver?.lat,
            driverLng: driver?.lng,
            driverHeading: driver?.heading,
            pickupLat: map.pickup?.latitude,
            pickupLng: map.pickup?.longitude,
            dropoffLat: map.dropoff?.latitude,
            dropoffLng: map.dropoff?.longitude,
            showPickup: !map.tripStarted,
            showDropoff: map.tripStarted,
            vehicleKind: kind,
            driverLabel: trip?.driver?.name,
            l10n: l10n,
          ),
        );
    }

    final showRoute = map.scene == BookingScene.rideOptions || map.scene == BookingScene.trip;
    return RawanaMap(
      zoom: zoom,
      centerLat: centerLat,
      centerLng: centerLng,
      markers: markers,
      polylinePoints: showRoute ? map.routePoints : const [],
      secondaryPolylinePoints:
          map.scene == BookingScene.rideOptions ? map.alternativePoints : const [],
      polylineColor: RawanaColors.routeLine,
      fitRouteBounds: fit,
      boundsPadding: 56,
      fitRouteRevision: map.fitRevision,
      cameraResetRevision: map.resetRevision,
      recenterRevision: map.recenterRevision,
      mapPadding: EdgeInsets.only(top: map.topInset, bottom: map.bottomInset),
      onCameraMove: onCameraMove,
      onCameraIdle: onCameraIdle,
      showCompass: map.scene != BookingScene.confirmPickup,
      pulseLat: pulseLat,
      pulseLng: pulseLng,
    );
  }
}

/// Page for routes inside [BookingShell]: fades, and has no modal barrier so
/// taps outside the sheet reach the shared map.
class MapShellPage<T> extends Page<T> {
  const MapShellPage({super.key, required this.child});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => _MapShellRoute<T>(this);
}

class _MapShellRoute<T> extends PageRoute<T> {
  _MapShellRoute(MapShellPage<T> page) : super(settings: page);

  MapShellPage<T> get _page => settings as MapShellPage<T>;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => true;

  @override
  Duration get transitionDuration => RawanaMotion.medium;

  @override
  Widget buildModalBarrier() => const SizedBox.shrink();

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return _page.child;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: RawanaMotion.curve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

/// Keeps the map's bottom padding equal to the height of [child].
class MapInsetReporter extends ConsumerStatefulWidget {
  const MapInsetReporter({super.key, required this.child, this.extra = 0});

  final Widget child;

  /// Added on top of the measured height (e.g. a floating button row).
  final double extra;

  @override
  ConsumerState<MapInsetReporter> createState() => _MapInsetReporterState();
}

class _MapInsetReporterState extends ConsumerState<MapInsetReporter> {
  final _key = GlobalKey();

  void _report() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !mounted) return;
    ref.read(bookingMapProvider.notifier).setBottomInset(box.size.height + widget.extra);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _report());
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: KeyedSubtree(key: _key, child: widget.child),
      ),
    );
  }
}
