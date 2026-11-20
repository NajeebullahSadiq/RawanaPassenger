import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';

import '../booking/places.dart';
import '../providers/history_providers.dart';
import '../providers/live_location_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/trip_providers.dart';

enum _Field { pickup, dropoff }

class DestinationSearchScreen extends ConsumerStatefulWidget {
  const DestinationSearchScreen({super.key, this.focusPickup = false});

  /// Opens with the pickup field active (e.g. from the pickup chip on Home).
  final bool focusPickup;

  @override
  ConsumerState<DestinationSearchScreen> createState() => _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends ConsumerState<DestinationSearchScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _pickupFocus = FocusNode();
  final _dropoffFocus = FocusNode();

  PlaceDetails? _pickup;
  bool _pickupIsGps = false;

  /// Set once the passenger picks a pickup themselves; GPS must not replace it.
  bool _pickupChosenByUser = false;
  _Field _active = _Field.dropoff;
  List<PlaceSuggestion> _suggestions = [];
  bool _loading = false;
  bool _failed = false;
  Timer? _debounce;
  int _searchToken = 0;
  bool _selecting = false;

  TextEditingController get _activeController =>
      _active == _Field.pickup ? _pickupController : _dropoffController;

  @override
  void initState() {
    super.initState();
    _active = widget.focusPickup ? _Field.pickup : _Field.dropoff;
    _pickupFocus.addListener(() => _onFocus(_Field.pickup, _pickupFocus));
    _dropoffFocus.addListener(() => _onFocus(_Field.dropoff, _dropoffFocus));
    _pickupController.addListener(() => _onQueryChanged(_Field.pickup));
    _dropoffController.addListener(() => _onQueryChanged(_Field.dropoff));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      (widget.focusPickup ? _pickupFocus : _dropoffFocus).requestFocus();
      ref.read(passengerLiveLocationProvider.notifier).refresh();
      final loc = ref.read(passengerLiveLocationProvider);
      if (loc != null) unawaited(_applyGpsPickup(loc.lat, loc.lng));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pickupController.dispose();
    _dropoffController.dispose();
    _pickupFocus.dispose();
    _dropoffFocus.dispose();
    super.dispose();
  }

  void _onFocus(_Field field, FocusNode node) {
    if (!node.hasFocus || _active == field) return;
    setState(() {
      _active = field;
      _suggestions = [];
      _failed = false;
      _loading = false;
    });
    if (field == _Field.pickup) {
      _pickupController.selection =
          TextSelection(baseOffset: 0, extentOffset: _pickupController.text.length);
    }
  }

  Future<void> _applyGpsPickup(double lat, double lng) async {
    if (_pickupChosenByUser || _pickup != null) return;
    var address = '';
    try {
      address = (await ref.read(mapsServiceProvider).reverseGeocode(lat, lng)).address;
    } catch (_) {}
    if (!mounted || _pickupChosenByUser) return;
    _setPickup(PlaceDetails(address: address.isNotEmpty ? address : context.l10n.currentLocation, lat: lat, lng: lng),
        gps: true, byUser: false);
  }

  void _setPickup(PlaceDetails place, {required bool gps, bool byUser = true}) {
    setState(() {
      _pickup = place;
      _pickupIsGps = gps;
      if (byUser) _pickupChosenByUser = true;
      _suggestions = [];
    });
    _pickupController.value = TextEditingValue(
      text: gps ? context.l10n.currentLocation : place.address,
      selection: const TextSelection.collapsed(offset: -1),
    );
  }

  String _shownText(_Field field) {
    if (field == _Field.pickup && _pickup != null) {
      return _pickupIsGps ? context.l10n.currentLocation : _pickup!.address;
    }
    return '';
  }

  void _onQueryChanged(_Field field) {
    if (field != _active) return;
    final q = _activeController.text.trim();
    if (q == _shownText(field)) return;
    _debounce?.cancel();
    if (q.length < 2) {
      setState(() {
        _suggestions = [];
        _loading = false;
        _failed = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _failed = false;
    });
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q));
  }

  Future<void> _search(String q) async {
    final token = ++_searchToken;
    final near = _pickup ?? _gpsPoint();
    try {
      final results = await ref.read(mapsServiceProvider).autocomplete(q, lat: near?.lat, lng: near?.lng);
      if (!mounted || token != _searchToken) return;
      setState(() {
        _suggestions = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || token != _searchToken) return;
      setState(() {
        _suggestions = [];
        _loading = false;
        _failed = true;
      });
    }
  }

  PlaceDetails? _gpsPoint() {
    final loc = ref.read(passengerLiveLocationProvider);
    return loc == null ? null : PlaceDetails(address: '', lat: loc.lat, lng: loc.lng);
  }

  Future<void> _useCurrentLocation() async {
    final pos = ref.read(passengerLiveLocationProvider) ?? await LocationService.getCurrentPosition();
    if (!mounted) return;
    if (pos == null) {
      await RawanaActionSheet.info(
        context,
        title: context.l10n.locationOffTitle,
        message: context.l10n.locationOffBody,
        actionLabel: context.l10n.dialogOk,
        icon: LucideIcons.mapPinOff,
        tone: RawanaColors.warning,
      );
      return;
    }
    var address = '';
    try {
      address = (await ref.read(mapsServiceProvider).reverseGeocode(pos.lat, pos.lng)).address;
    } catch (_) {}
    if (!mounted) return;
    _setPickup(
      PlaceDetails(address: address.isNotEmpty ? address : context.l10n.currentLocation, lat: pos.lat, lng: pos.lng),
      gps: true,
    );
    _dropoffFocus.requestFocus();
  }

  Future<void> _pick(Future<PlaceDetails> Function() resolve) async {
    if (_selecting) return;
    setState(() => _selecting = true);
    try {
      final place = await resolve();
      if (!mounted) return;
      if (_active == _Field.pickup) {
        _setPickup(place, gps: false);
        if (_dropoffController.text.trim().isEmpty) _dropoffFocus.requestFocus();
        return;
      }
      await _continueTo(place);
    } catch (_) {
      if (mounted) showRawanaMessage(context, context.l10n.couldNotSelectPlace);
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  Future<void> _continueTo(PlaceDetails destination) async {
    final pickup = _pickup;
    if (pickup == null) {
      _dropoffController.text = destination.address;
      _pickupFocus.requestFocus();
      showRawanaMessage(context, context.l10n.choosePickupFirst);
      return;
    }
    ref.read(bookingDraftProvider.notifier).state = TripBookingDraft(
      pickupLat: pickup.lat,
      pickupLng: pickup.lng,
      pickupAddress: pickup.address,
      dropoffLat: destination.lat,
      dropoffLng: destination.lng,
      dropoffAddress: destination.address,
    );
    context.go('/ride-selection');
  }

  Future<void> _selectSuggestion(PlaceSuggestion s) => _pick(() async {
        final details = await ref.read(mapsServiceProvider).getPlace(s.placeId);
        return PlaceDetails(
          address: details.address.isNotEmpty ? details.address : s.description,
          lat: details.lat,
          lng: details.lng,
        );
      });

  Future<void> _selectKnown(String address, double lat, double lng) =>
      _pick(() async => PlaceDetails(address: address, lat: lat, lng: lng));

  Future<void> _setOnMap() async {
    final anchor = _pickup ?? _gpsPoint();
    final result = await context.push<PlaceDetails>(
      Uri(
        path: '/map-picker',
        queryParameters: {
          'mode': _active == _Field.pickup ? 'pickup' : 'dropoff',
          if (anchor != null) 'lat': anchor.lat.toString(),
          if (anchor != null) 'lng': anchor.lng.toString(),
        },
      ).toString(),
    );
    if (result == null || !mounted) return;
    final place = PlaceDetails(
      address: result.address.isNotEmpty
          ? result.address
          : (_active == _Field.pickup ? context.l10n.selectedPickup : context.l10n.selectedDestination),
      lat: result.lat,
      lng: result.lng,
    );
    await _pick(() async => place);
  }

  void _close() => context.canPop() ? context.pop() : context.go('/home');

  @override
  Widget build(BuildContext context) {
    ref.listen(passengerLiveLocationProvider, (_, next) {
      if (next != null) unawaited(_applyGpsPickup(next.lat, next.lng));
    });
    final query = _activeController.text.trim();
    final searching = query.length >= 2 && query != _shownText(_active);
    final saved = parseSavedPlaces(ref.watch(savedAddressesProvider).valueOrNull ?? const []);
    final recent = ref.watch(recentPlacesProvider).valueOrNull ?? const <RecentPlace>[];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: _close,
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    icon: const Icon(LucideIcons.arrowLeft),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _FieldStack(
                      pickupController: _pickupController,
                      dropoffController: _dropoffController,
                      pickupFocus: _pickupFocus,
                      dropoffFocus: _dropoffFocus,
                      active: _active,
                      onClear: () => _activeController.clear(),
                    ),
                  ),
                ],
              ),
            ),
            if (_selecting) const LinearProgressIndicator(minHeight: 2) else const Divider(height: 2),
            Expanded(
              child: searching
                  ? _Results(
                      loading: _loading,
                      failed: _failed,
                      suggestions: _suggestions,
                      onRetry: () => _search(query),
                      onSelect: _selectSuggestion,
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        if (_active == _Field.pickup) ...[
                          PlaceRow(
                            icon: LucideIcons.locateFixed,
                            title: context.l10n.currentLocation,
                            subtitle: context.l10n.pickupFromCurrentLocation,
                            highlight: true,
                            onTap: _useCurrentLocation,
                          ),
                          const PlaceRowDivider(),
                        ],
                        for (final place in saved)
                          PlaceRow(
                            icon: savedPlaceIcon(place.label),
                            title: place.label.isEmpty ? place.address : savedPlaceTitle(context, place.label),
                            subtitle: place.label.isEmpty ? null : place.address,
                            onTap: () => _selectKnown(
                              place.address.isNotEmpty ? place.address : place.label,
                              place.lat,
                              place.lng,
                            ),
                          ),
                        for (final place in recent)
                          Builder(builder: (context) {
                            final (title, subtitle) = splitAddress(place.address);
                            return PlaceRow(
                              icon: LucideIcons.clock,
                              title: title,
                              subtitle: subtitle,
                              onTap: () => _selectKnown(place.address, place.lat, place.lng),
                            );
                          }),
                      ],
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PlaceRow(
                icon: LucideIcons.mapPinned,
                title: context.l10n.setLocationOnMap,
                highlight: true,
                onTap: _setOnMap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldStack extends StatelessWidget {
  const _FieldStack({
    required this.pickupController,
    required this.dropoffController,
    required this.pickupFocus,
    required this.dropoffFocus,
    required this.active,
    required this.onClear,
  });

  final TextEditingController pickupController;
  final TextEditingController dropoffController;
  final FocusNode pickupFocus;
  final FocusNode dropoffFocus;
  final _Field active;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: RawanaColors.pickupPin, width: 3),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: RawanaColors.outline,
                  ),
                ),
                Container(width: 10, height: 10, color: RawanaColors.dropoffPin),
                const SizedBox(height: 20),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                _SearchField(
                  controller: pickupController,
                  focusNode: pickupFocus,
                  hint: context.l10n.pickupTitle,
                  active: active == _Field.pickup,
                  onClear: onClear,
                ),
                const SizedBox(height: 8),
                _SearchField(
                  controller: dropoffController,
                  focusNode: dropoffFocus,
                  hint: context.l10n.searchDestinationHint,
                  active: active == _Field.dropoff,
                  onClear: onClear,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.active,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool active;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: RawanaMotion.fast,
      height: 48,
      decoration: BoxDecoration(
        color: active ? Colors.white : RawanaColors.surfaceAlt,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
        border: Border.all(
          color: active ? RawanaColors.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: context.text.bodyStrong,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: context.text.body.copyWith(color: RawanaColors.onSurfaceFaint),
                filled: false,
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          if (active)
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => controller.text.isEmpty
                  ? const SizedBox(width: 8)
                  : IconButton(
                      onPressed: onClear,
                      icon: const Icon(LucideIcons.x, size: 18),
                      color: RawanaColors.onSurfaceMuted,
                      tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                    ),
            ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.loading,
    required this.failed,
    required this.suggestions,
    required this.onRetry,
    required this.onSelect,
  });

  final bool loading;
  final bool failed;
  final List<PlaceSuggestion> suggestions;
  final VoidCallback onRetry;
  final ValueChanged<PlaceSuggestion> onSelect;

  @override
  Widget build(BuildContext context) {
    if (loading && suggestions.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: const [
          RawanaSkeletonRow(),
          RawanaSkeletonRow(),
          RawanaSkeletonRow(),
          RawanaSkeletonRow(),
        ],
      );
    }
    if (failed) {
      return RawanaErrorState(
        title: context.l10n.searchFailed,
        retryLabel: context.l10n.tryAgain,
        onRetry: onRetry,
        icon: LucideIcons.wifiOff,
      );
    }
    if (suggestions.isEmpty) {
      return RawanaErrorState(title: context.l10n.noPlacesFound, icon: LucideIcons.searchX);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: suggestions.length,
      separatorBuilder: (_, _) => const PlaceRowDivider(),
      itemBuilder: (context, i) {
        final s = suggestions[i];
        return PlaceRow(
          icon: LucideIcons.mapPin,
          title: s.mainText,
          subtitle: s.secondaryText,
          onTap: () => onSelect(s),
        );
      },
    );
  }
}
