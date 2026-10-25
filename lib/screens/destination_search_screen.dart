import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/history_providers.dart';
import '../providers/live_location_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/trip_providers.dart';

class DestinationSearchScreen extends ConsumerStatefulWidget {
  const DestinationSearchScreen({super.key});

  @override
  ConsumerState<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState
    extends ConsumerState<DestinationSearchScreen> {
  final _destController = TextEditingController();
  final _destFocusNode = FocusNode();
  String _pickupAddress = '';
  double? _pickupLat;
  double? _pickupLng;
  List<PlaceSuggestion> _suggestions = [];
  Timer? _debounce;
  bool _loading = false;

  /// Set once the passenger picks a pickup themselves; GPS updates must not
  /// replace it afterwards.
  bool _pickupChosenByUser = false;
  int _searchToken = 0;

  /// Guards against a double tap pushing ride selection twice.
  bool _selecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(passengerLiveLocationProvider.notifier).refresh();
      final loc = ref.read(passengerLiveLocationProvider);
      if (loc != null) {
        unawaited(_applyGpsPickup(loc.lat, loc.lng));
      }
    });
    _destController.addListener(_onSearchChanged);
  }

  /// Uses GPS as the default pickup only until one is set.
  Future<void> _applyGpsPickup(double lat, double lng) async {
    if (_pickupChosenByUser || _pickupLat != null) return;
    await _applyPickup(lat, lng, fromGps: true);
  }

  void _setUserPickup(double lat, double lng, String address) {
    setState(() {
      _pickupChosenByUser = true;
      _pickupLat = lat;
      _pickupLng = lng;
      _pickupAddress = address;
    });
  }

  Future<void> _applyPickup(double lat, double lng, {bool fromGps = false}) async {
    try {
      final place = await ref.read(mapsServiceProvider).reverseGeocode(lat, lng);
      if (!mounted) return;
      if (fromGps && _pickupChosenByUser) return;
      setState(() {
        _pickupLat = lat;
        _pickupLng = lng;
        _pickupAddress = place.address.isNotEmpty
            ? place.address
            : context.l10n.currentLocation;
      });
    } catch (_) {
      if (!mounted || (fromGps && _pickupChosenByUser)) return;
      setState(() {
        _pickupLat = lat;
        _pickupLng = lng;
        _pickupAddress = context.l10n.currentLocation;
      });
    }
  }

  Future<void> _ensurePickupReady() async {
    if (_pickupLat != null && _pickupLng != null) return;
    final pos = await LocationService.getCurrentPosition();
    if (!mounted) return;
    if (pos != null) {
      await _applyPickup(pos.lat, pos.lng);
      return;
    }
    // Last resort so search selection is not blocked when GPS is denied.
    await _applyPickup(RawanaConstants.kabulLat, RawanaConstants.kabulLng);
    if (!mounted) return;
    setState(() => _pickupAddress = context.l10n.kabulFallbackPickup);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.locationUnavailableEnableGps),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _destController.removeListener(_onSearchChanged);
    _destController.dispose();
    _destFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      final q = _destController.text.trim();
      final token = ++_searchToken;
      if (q.length < 2) {
        setState(() {
          _suggestions = [];
          _loading = false;
        });
        return;
      }
      setState(() => _loading = true);
      try {
        final results = await ref
            .read(mapsServiceProvider)
            .autocomplete(q, lat: _pickupLat, lng: _pickupLng);
        if (mounted && token == _searchToken) setState(() => _suggestions = results);
      } catch (_) {
        if (mounted && token == _searchToken) setState(() => _suggestions = []);
      } finally {
        if (mounted && token == _searchToken) setState(() => _loading = false);
      }
    });
  }

  Future<void> _selectDestination(PlaceSuggestion suggestion) =>
      _goToRideSelection(() async {
        final details =
            await ref.read(mapsServiceProvider).getPlace(suggestion.placeId);
        return PlaceDetails(
          address: details.address.isNotEmpty
              ? details.address
              : suggestion.description,
          lat: details.lat,
          lng: details.lng,
        );
      });

  /// Saved and recent places already carry coordinates.
  Future<void> _selectKnownPlace(String address, double lat, double lng) =>
      _goToRideSelection(
        () async => PlaceDetails(address: address, lat: lat, lng: lng),
      );

  Future<void> _goToRideSelection(
    Future<PlaceDetails> Function() resolveDestination,
  ) async {
    if (_selecting) return;
    setState(() => _selecting = true);
    try {
      await _ensurePickupReady();
      if (!mounted) return;
      if (_pickupLat == null || _pickupLng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.choosePickupFirst)),
        );
        return;
      }
      final destination = await resolveDestination();
      if (!mounted) return;
      ref.read(bookingDraftProvider.notifier).state = TripBookingDraft(
        pickupLat: _pickupLat!,
        pickupLng: _pickupLng!,
        pickupAddress: _pickupAddress,
        dropoffLat: destination.lat,
        dropoffLng: destination.lng,
        dropoffAddress: destination.address,
      );
      await context.push('/ride-selection');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotSelectPlace)),
      );
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  Future<void> _choosePickupOnMap() async {
    final result = await context.push<PlaceDetails>(
      Uri(
        path: '/map-picker',
        queryParameters: {
          'mode': 'pickup',
          if (_pickupLat != null) 'lat': _pickupLat!.toString(),
          if (_pickupLng != null) 'lng': _pickupLng!.toString(),
        },
      ).toString(),
    );
    if (result == null || !mounted) return;
    _setUserPickup(
      result.lat,
      result.lng,
      result.address.isNotEmpty ? result.address : context.l10n.selectedPickup,
    );
  }

  Future<void> _chooseDropoffOnMap() async {
    if (_selecting) return;
    await _ensurePickupReady();
    if (!mounted) return;
    if (_pickupLat == null || _pickupLng == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.choosePickupFirstShort)));
      return;
    }
    final result = await context.push<PlaceDetails>(
      Uri(
        path: '/map-picker',
        queryParameters: {
          'mode': 'dropoff',
          'lat': _pickupLat!.toString(),
          'lng': _pickupLng!.toString(),
        },
      ).toString(),
    );
    if (result == null || !mounted) return;
    ref.read(bookingDraftProvider.notifier).state = TripBookingDraft(
      pickupLat: _pickupLat!,
      pickupLng: _pickupLng!,
      pickupAddress: _pickupAddress,
      dropoffLat: result.lat,
      dropoffLng: result.lng,
      dropoffAddress: result.address.isNotEmpty
          ? result.address
          : context.l10n.selectedDestination,
    );
    context.push('/ride-selection');
  }

  Future<void> _editPickup() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RawanaSpacing.radiusXl),
        ),
      ),
      builder: (sheetContext) => _EditPickupSheet(
        initialAddress: _pickupAddress,
        pickupLat: _pickupLat,
        pickupLng: _pickupLng,
        onPickupSelected: _setUserPickup,
        onChooseMap: () async {
          Navigator.pop(sheetContext);
          await _choosePickupOnMap();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(passengerLiveLocationProvider, (prev, next) {
      if (next != null) {
        unawaited(_applyGpsPickup(next.lat, next.lng));
      } else if (mounted && !_pickupChosenByUser && _pickupLat == null) {
        setState(() => _pickupAddress = context.l10n.enableLocationToBook);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: RawanaCircleIconButton(
            icon: LucideIcons.arrowLeft,
            background: RawanaColors.surfaceAlt,
            iconColor: RawanaColors.onSurface,
            elevated: false,
            size: 40,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
        ),
        title: Text(context.l10n.planYourTrip),
        bottom: _selecting
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
              boxShadow: RawanaShadows.floating,
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: RawanaColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: RawanaColors.success.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          5,
                          (_) => Container(
                            width: 2,
                            height: 2,
                            decoration: const BoxDecoration(
                              color: RawanaColors.outline,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: RawanaColors.dropoffPin,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: RawanaColors.dropoffPin.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Label(context.l10n.fromLabel),
                          const Spacer(),
                          TextButton(
                            onPressed: _editPickup,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(44, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(context.l10n.edit),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _pickupAddress.isEmpty
                            ? context.l10n.gettingLocation
                            : _pickupAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        height: 1,
                        color: RawanaColors.divider,
                      ),
                      _Label(context.l10n.toLabel),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        heightFactor: 0.8,
                        child: TextButton.icon(
                          onPressed: _chooseDropoffOnMap,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(44, 24),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(LucideIcons.mapPinned, size: 14),
                          label: Text(context.l10n.map),
                        ),
                      ),
                      const SizedBox(height: 2),
                      TextField(
                        controller: _destController,
                        focusNode: _destFocusNode,
                        autofocus: true,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: context.l10n.searchDestination,
                          hintStyle: const TextStyle(
                            color: RawanaColors.onSurfaceFaint,
                            fontWeight: FontWeight.w500,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          suffixIcon: _loading
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : (_destController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          LucideIcons.x,
                                          size: 16,
                                        ),
                                        color: RawanaColors.onSurfaceMuted,
                                        onPressed: () =>
                                            _destController.clear(),
                                      )
                                    : null),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_suggestions.isNotEmpty || _destController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                context.l10n.suggestions,
                style: const TextStyle(
                  color: RawanaColors.onSurfaceMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          Expanded(
            child: _suggestions.isEmpty && _destController.text.isEmpty
                ? _QuickPlaces(
                    saved: ref.watch(savedAddressesProvider).valueOrNull ??
                        const [],
                    recent: ref.watch(recentPlacesProvider).valueOrNull ??
                        const [],
                    onPick: _selectKnownPlace,
                    onChooseMap: _chooseDropoffOnMap,
                  )
                : ListView.separated(
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, _) => Padding(
                      padding: const EdgeInsets.only(left: 76),
                      child: Container(height: 1, color: RawanaColors.divider),
                    ),
                    itemBuilder: (context, index) {
                      final s = _suggestions[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: RawanaColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            LucideIcons.mapPin,
                            size: 18,
                            color: RawanaColors.primary,
                          ),
                        ),
                        title: Text(
                          s.mainText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            s.secondaryText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: RawanaColors.onSurfaceMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        trailing: const Icon(
                          LucideIcons.arrowUpRight,
                          size: 16,
                          color: RawanaColors.onSurfaceFaint,
                        ),
                        onTap: () => _selectDestination(s),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EditPickupSheet extends ConsumerStatefulWidget {
  const _EditPickupSheet({
    required this.initialAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.onPickupSelected,
    required this.onChooseMap,
  });

  final String initialAddress;
  final double? pickupLat;
  final double? pickupLng;
  final void Function(double lat, double lng, String address) onPickupSelected;
  final VoidCallback onChooseMap;

  @override
  ConsumerState<_EditPickupSheet> createState() => _EditPickupSheetState();
}

class _EditPickupSheetState extends ConsumerState<_EditPickupSheet> {
  late final TextEditingController _controller;
  Timer? _debounce;
  bool _loading = false;
  List<PlaceSuggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAddress);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      final q = value.trim();
      if (q.length < 2) {
        setState(() => _suggestions = []);
        return;
      }
      setState(() => _loading = true);
      try {
        final results = await ref
            .read(mapsServiceProvider)
            .autocomplete(q, lat: widget.pickupLat, lng: widget.pickupLng);
        if (mounted && _controller.text.trim() == q) {
          setState(() => _suggestions = results);
        }
      } catch (_) {
        if (mounted) setState(() => _suggestions = []);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  Future<void> _useCurrentLocation() async {
    _debounce?.cancel();
    final pos = await LocationService.getCurrentPosition();
    if (!mounted) return;
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.locationUnavailableEnableGps)),
      );
      return;
    }
    String address = '';
    try {
      final place = await ref
          .read(mapsServiceProvider)
          .reverseGeocode(pos.lat, pos.lng);
      address = place.address;
    } catch (_) {}
    if (!mounted) return;
    widget.onPickupSelected(
      pos.lat,
      pos.lng,
      address.isNotEmpty ? address : context.l10n.currentLocation,
    );
    Navigator.pop(context);
  }

  Future<void> _selectPickup(PlaceSuggestion suggestion) async {
    _debounce?.cancel();
    final PlaceDetails details;
    try {
      details = await ref.read(mapsServiceProvider).getPlace(suggestion.placeId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSelectPlace)),
        );
      }
      return;
    }
    if (!mounted) return;
    widget.onPickupSelected(
      details.lat,
      details.lng,
      details.address.isNotEmpty ? details.address : suggestion.description,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RawanaSheetHandle(),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                context.l10n.editPickup,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.search),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                hintText: context.l10n.searchPickupLocation,
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                LucideIcons.locateFixed,
                color: RawanaColors.primary,
              ),
              title: Text(context.l10n.useCurrentLocation),
              onTap: _useCurrentLocation,
            ),
            ListTile(
              leading: const Icon(
                LucideIcons.mapPinned,
                color: RawanaColors.primary,
              ),
              title: Text(context.l10n.chooseOnMap),
              subtitle: Text(context.l10n.movePinToPickup),
              onTap: widget.onChooseMap,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (_, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    leading: const Icon(
                      LucideIcons.mapPin,
                      color: RawanaColors.onSurfaceMuted,
                    ),
                    title: Text(
                      suggestion.mainText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      suggestion.secondaryText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectPickup(suggestion),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: RawanaColors.onSurfaceMuted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _QuickPlaces extends StatelessWidget {
  const _QuickPlaces({
    required this.saved,
    required this.recent,
    required this.onPick,
    required this.onChooseMap,
  });

  final List<Map<String, dynamic>> saved;
  final List<RecentPlace> recent;
  final void Function(String address, double lat, double lng) onPick;
  final VoidCallback onChooseMap;

  static IconData _savedIcon(String label) => switch (label.toLowerCase()) {
        'home' => LucideIcons.house,
        'work' => LucideIcons.briefcase,
        _ => LucideIcons.bookmark,
      };

  static String _savedTitle(BuildContext context, String label) =>
      switch (label.toLowerCase()) {
        'home' => context.l10n.quickHome,
        'work' => context.l10n.quickWork,
        _ => label,
      };

  @override
  Widget build(BuildContext context) {
    final savedPlaces = [
      for (final item in saved)
        if ((parseWktLat(item['location'] as String?) ??
                    (item['lat'] as num?)?.toDouble()) !=
                null &&
            (parseWktLng(item['location'] as String?) ??
                    (item['lng'] as num?)?.toDouble()) !=
                null)
          (
            label: item['label'] as String? ?? '',
            address: item['address'] as String? ?? '',
            lat: parseWktLat(item['location'] as String?) ??
                (item['lat'] as num).toDouble(),
            lng: parseWktLng(item['location'] as String?) ??
                (item['lng'] as num).toDouble(),
          ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        if (savedPlaces.isNotEmpty) ...[
          _SectionHeader(context.l10n.savedPlacesHeader),
          for (final place in savedPlaces)
            _PlaceTile(
              icon: _savedIcon(place.label),
              title: place.label.isEmpty
                  ? place.address
                  : _savedTitle(context, place.label),
              subtitle: place.label.isEmpty ? null : place.address,
              onTap: () => onPick(
                place.address.isNotEmpty ? place.address : place.label,
                place.lat,
                place.lng,
              ),
            ),
        ],
        if (recent.isNotEmpty) ...[
          _SectionHeader(context.l10n.recentPlacesHeader),
          for (final place in recent)
            _PlaceTile(
              icon: LucideIcons.clock,
              title: place.address.split(',').first,
              subtitle: place.address.contains(',')
                  ? place.address.substring(place.address.indexOf(',') + 1).trim()
                  : null,
              onTap: () => onPick(place.address, place.lat, place.lng),
            ),
        ],
        if (savedPlaces.isEmpty && recent.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: _emptyTile(
              LucideIcons.compass,
              context.l10n.startTyping,
              context.l10n.weWillSuggestPlaces,
            ),
          ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _mapTile(context),
        ),
      ],
    );
  }

  Widget _emptyTile(IconData icon, String title, String sub) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: RawanaColors.surfaceAlt,
      borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: RawanaColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: const TextStyle(
                  color: RawanaColors.onSurfaceMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _mapTile(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
      onTap: onChooseMap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RawanaColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
          border: Border.all(
            color: RawanaColors.primary.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.mapPinned, color: RawanaColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.chooseOnMap,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.dropPinDestination,
                    style: const TextStyle(
                      color: RawanaColors.onSurfaceMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.arrowRight, color: RawanaColors.primary, size: 18),
          ],
        ),
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        text,
        style: const TextStyle(
          color: RawanaColors.onSurfaceMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: RawanaColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: RawanaColors.onSurface),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      subtitle: subtitle == null || subtitle!.isEmpty
          ? null
          : Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: RawanaColors.onSurfaceMuted,
                fontSize: 13,
              ),
            ),
      onTap: onTap,
    );
  }
}
