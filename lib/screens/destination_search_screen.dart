import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/trip_providers.dart';
import '../providers/live_location_providers.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(passengerLiveLocationProvider.notifier).refresh();
      final loc = ref.read(passengerLiveLocationProvider);
      if (loc != null) {
        unawaited(_applyPickup(loc.lat, loc.lng));
      }
    });
    _destController.addListener(_onSearchChanged);
  }

  Future<void> _applyPickup(double lat, double lng) async {
    try {
      final place = await ref.read(mapsServiceProvider).reverseGeocode(lat, lng);
      if (!mounted) return;
      setState(() {
        _pickupLat = lat;
        _pickupLng = lng;
        _pickupAddress = place.address.isNotEmpty
            ? place.address
            : context.l10n.currentLocation;
      });
    } catch (_) {
      if (!mounted) return;
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
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      final q = _destController.text.trim();
      if (q.length < 2) {
        setState(() => _suggestions = []);
        return;
      }
      setState(() => _loading = true);
      try {
        final results = await ref
            .read(mapsServiceProvider)
            .autocomplete(q, lat: _pickupLat, lng: _pickupLng);
        if (mounted) setState(() => _suggestions = results);
      } catch (_) {
        if (mounted) setState(() => _suggestions = []);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  Future<void> _selectDestination(PlaceSuggestion suggestion) async {
    try {
      await _ensurePickupReady();
      if (!mounted) return;
      if (_pickupLat == null || _pickupLng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.choosePickupFirst)),
        );
        return;
      }
      final details =
          await ref.read(mapsServiceProvider).getPlace(suggestion.placeId);
      if (!mounted) return;
      ref.read(bookingDraftProvider.notifier).state = TripBookingDraft(
        pickupLat: _pickupLat!,
        pickupLng: _pickupLng!,
        pickupAddress: _pickupAddress,
        dropoffLat: details.lat,
        dropoffLng: details.lng,
        dropoffAddress: details.address.isNotEmpty
            ? details.address
            : suggestion.description,
      );
      context.push('/ride-selection');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotSelectPlace)),
      );
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
    setState(() {
      _pickupLat = result.lat;
      _pickupLng = result.lng;
      _pickupAddress = result.address.isNotEmpty
          ? result.address
          : context.l10n.selectedPickup;
    });
  }

  Future<void> _chooseDropoffOnMap() async {
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
        onPickupSelected: (lat, lng, address) {
          setState(() {
            _pickupLat = lat;
            _pickupLng = lng;
            _pickupAddress = address;
          });
        },
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
        unawaited(_applyPickup(next.lat, next.lng));
      } else if (mounted) {
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
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(context.l10n.planYourTrip),
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
          if (_suggestions.isEmpty && _destController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                context.l10n.popularPlaces,
                style: const TextStyle(
                  color: RawanaColors.onSurfaceMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            )
          else
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
                ? _EmptyState(onChooseMap: _chooseDropoffOnMap)
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
        if (mounted) setState(() => _suggestions = results);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  Future<void> _useCurrentLocation() async {
    _debounce?.cancel();
    final pos = await LocationService.getCurrentPosition();
    if (pos == null || !mounted) return;
    final place = await ref
        .read(mapsServiceProvider)
        .reverseGeocode(pos.lat, pos.lng);
    if (!mounted) return;
    widget.onPickupSelected(
      pos.lat,
      pos.lng,
      place.address.isNotEmpty ? place.address : context.l10n.currentLocation,
    );
    Navigator.pop(context);
  }

  Future<void> _selectPickup(PlaceSuggestion suggestion) async {
    _debounce?.cancel();
    final details = await ref
        .read(mapsServiceProvider)
        .getPlace(suggestion.placeId);
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onChooseMap});

  final VoidCallback onChooseMap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        _emptyTile(
          LucideIcons.compass,
          context.l10n.startTyping,
          context.l10n.weWillSuggestPlaces,
        ),
        const SizedBox(height: 10),
        _mapTile(context),
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
