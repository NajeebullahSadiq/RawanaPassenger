import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/trip_providers.dart';

class TripCompleteScreen extends ConsumerStatefulWidget {
  const TripCompleteScreen({super.key});

  @override
  ConsumerState<TripCompleteScreen> createState() => _TripCompleteScreenState();
}

class _TripCompleteScreenState extends ConsumerState<TripCompleteScreen> {
  static const _tagKeys = ['Clean car', 'Safe driving', 'Friendly driver', 'On time', 'Good navigation'];
  static const _tipOptions = [20, 50, 100];

  int _stars = 0;
  final _comment = TextEditingController();
  final _selectedTags = <String>{};
  bool _submitting = false;
  int? _tip;
  bool _tipSaving = false;
  int _tipToken = 0;

  String _tagLabel(AppLocalizations l10n, String key) => switch (key) {
        'Clean car' => l10n.ratingTagCleanCar,
        'Safe driving' => l10n.ratingTagSafeDriving,
        'Friendly driver' => l10n.ratingTagFriendlyDriver,
        'On time' => l10n.ratingTagOnTime,
        'Good navigation' => l10n.ratingTagGoodNavigation,
        _ => key,
      };

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _goHome({bool skipped = false}) {
    final trip = ref.read(activeTripProvider).valueOrNull;
    // Respect the skip: Home must not re-prompt for this trip.
    if (skipped && trip != null) {
      ref.read(dismissedRatingPromptsProvider.notifier).update((s) => {...s, trip.id});
    }
    ref.read(activeTripProvider.notifier).clearLocalTripState();
    context.go('/home');
  }

  Future<void> _submit() async {
    final trip = ref.read(activeTripProvider).valueOrNull;
    if (trip == null || _stars == 0) return;
    setState(() => _submitting = true);
    try {
      await ref.read(passengerServiceProvider).submitRating(
            tripId: trip.id,
            stars: _stars,
            comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
            tags: _stars >= 4 ? _selectedTags.toList() : const [],
          );
      if (mounted) _goHome();
    } catch (e) {
      if (mounted) showRawanaError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _setTip(Trip trip, int amount) async {
    final previous = _tip ?? trip.tipAmount;
    if (amount == previous) return;
    HapticFeedback.selectionClick();
    final token = ++_tipToken;
    setState(() {
      _tip = amount;
      _tipSaving = true;
    });
    try {
      final saved = await ref.read(tripServiceProvider).setTip(trip.id, amount);
      if (!mounted || token != _tipToken) return;
      setState(() {
        _tip = saved;
        _tipSaving = false;
      });
    } catch (e) {
      if (!mounted || token != _tipToken) return;
      setState(() {
        _tip = previous;
        _tipSaving = false;
      });
      final key = apiErrorKey(e);
      showRawanaMessage(context, key == 'tip_locked' ? context.l10n.tipLocked : context.l10n.tipFailed);
    }
  }

  Future<void> _customTip(Trip trip) async {
    final controller = TextEditingController();
    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const RawanaGrabber(),
                Text(ctx.l10n.addATip, style: ctx.text.headline),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
                  decoration: InputDecoration(suffixText: ctx.l10n.currencyAfn),
                  onSubmitted: (v) => Navigator.pop(ctx, int.tryParse(v)),
                ),
                const SizedBox(height: 16),
                RawanaPrimaryButton(
                  label: ctx.l10n.addATip,
                  onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    controller.dispose();
    if (amount == null || !mounted) return;
    await _setTip(trip, amount);
  }

  void _openReceipt(Trip trip, int tip) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ReceiptSheet(
        trip: trip,
        tip: tip,
        onShare: () async {
          final url = await ref.read(passengerServiceProvider).getTripReceiptUrl(trip.id);
          if (!mounted) return;
          if (url == null) {
            showRawanaMessage(context, context.l10n.tripReceipt);
            return;
          }
          await Share.share(url, subject: context.l10n.tripReceipt);
        },
        onReport: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ReportIssueScreen(
                supportService: ref.read(supportServiceProvider),
                tripId: trip.id,
                initialCategory: 'driver_behaviour',
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(activeTripProvider);
    final trip = tripAsync.valueOrNull;
    if (trip == null) {
      if (!tripAsync.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/home');
        });
      }
      return const Scaffold(backgroundColor: Colors.white, body: SizedBox.shrink());
    }
    final l10n = context.l10n;
    final driverName = trip.driver?.name ?? l10n.yourDriver;
    final tip = _tip ?? trip.tipAmount;
    final total = trip.cashToCollect + tip;
    final rated = _stars > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _RouteHeader(trip: trip, driverName: driverName),
                    const SizedBox(height: 16),
                    Text(l10n.youArrived, textAlign: TextAlign.center, style: context.text.caption),
                    const SizedBox(height: 4),
                    Text(l10n.howWasTripWith(driverName), textAlign: TextAlign.center, style: context.text.headline),
                    const SizedBox(height: 16),
                    Center(
                      child: StarRating(
                        value: _stars,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _stars = v);
                        },
                      ),
                    ),
                    AnimatedSize(
                      duration: RawanaMotion.medium,
                      curve: RawanaMotion.curve,
                      alignment: Alignment.topCenter,
                      child: !rated
                          ? const SizedBox(width: double.infinity)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 20),
                                Text(
                                  _stars >= 4 ? l10n.whatWentWell : l10n.whatCouldBeBetter,
                                  textAlign: TextAlign.center,
                                  style: context.text.title,
                                ),
                                const SizedBox(height: 12),
                                if (_stars >= 4)
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final t in _tagKeys)
                                        FilterChip(
                                          label: Text(_tagLabel(l10n, t)),
                                          selected: _selectedTags.contains(t),
                                          showCheckmark: false,
                                          labelStyle: context.text.label.copyWith(
                                            color: _selectedTags.contains(t)
                                                ? RawanaColors.primary
                                                : RawanaColors.onSurface,
                                          ),
                                          selectedColor: RawanaColors.primary.withValues(alpha: 0.1),
                                          backgroundColor: RawanaColors.surfaceAlt,
                                          side: BorderSide(
                                            color: _selectedTags.contains(t) ? RawanaColors.primary : Colors.transparent,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
                                          ),
                                          onSelected: (on) => setState(() {
                                            on ? _selectedTags.add(t) : _selectedTags.remove(t);
                                          }),
                                        ),
                                    ],
                                  ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _comment,
                                  maxLength: 280,
                                  maxLines: 3,
                                  minLines: 1,
                                  decoration: InputDecoration(hintText: l10n.ratingCommentHint),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Text(l10n.addATip, style: context.text.title)),
                        if (_tipSaving)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.tipHint, style: context.text.caption),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TipChip(label: l10n.noTip, selected: tip == 0, onTap: () => _setTip(trip, 0)),
                        for (final a in _tipOptions)
                          _TipChip(label: AfnFormatter.format(a), selected: tip == a, onTap: () => _setTip(trip, a)),
                        _TipChip(
                          label: tip > 0 && !_tipOptions.contains(tip) ? AfnFormatter.format(tip) : l10n.customTip,
                          selected: tip > 0 && !_tipOptions.contains(tip),
                          onTap: () => _customTip(trip),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _openReceipt(trip, tip),
                      borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: RawanaColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.banknote, color: RawanaColors.success, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.totalPaidCash, style: context.text.bodyStrong),
                                  Text(l10n.viewReceipt, style: context.text.caption.copyWith(color: RawanaColors.primary)),
                                ],
                              ),
                            ),
                            Text(AfnFormatter.format(total), style: context.text.priceLarge),
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.chevronRight, size: 18, color: RawanaColors.onSurfaceMuted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RawanaPrimaryButton(
                    label: rated ? l10n.submitRating : l10n.doneLabel,
                    loading: _submitting,
                    onPressed: _submitting ? null : (rated ? _submit : () => _goHome(skipped: true)),
                  ),
                  if (rated)
                    TextButton(
                      onPressed: _submitting ? null : () => _goHome(skipped: true),
                      child: Text(l10n.skipRating, style: const TextStyle(color: RawanaColors.onSurfaceMuted)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Route thumbnail with the driver's photo overlapping its bottom edge.
class _RouteHeader extends StatelessWidget {
  const _RouteHeader({required this.trip, required this.driverName});

  final Trip trip;
  final String driverName;

  @override
  Widget build(BuildContext context) {
    final url = trip.routeSnapshotUrl;
    const avatar = 72.0;
    return SizedBox(
      height: 150 + avatar / 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 150,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
              child: url != null && url.isNotEmpty
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _RouteFallback(trip: trip),
                    )
                  : _RouteFallback(trip: trip),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: RawanaAvatar(name: driverName, photoUrl: trip.driver?.profilePhotoUrl, size: avatar, ring: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteFallback extends StatelessWidget {
  const _RouteFallback({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: RawanaColors.surfaceAlt,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      alignment: Alignment.topCenter,
      child: TripRouteAddresses(pickupAddress: trip.pickupAddress, dropoffAddress: trip.dropoffAddress, dense: true),
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: context.text.label.copyWith(color: selected ? Colors.white : RawanaColors.onSurface),
      selectedColor: RawanaColors.primary,
      backgroundColor: RawanaColors.surfaceAlt,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill)),
    );
  }
}

class _ReceiptSheet extends StatelessWidget {
  const _ReceiptSheet({required this.trip, required this.tip, required this.onShare, required this.onReport});

  final Trip trip;
  final int tip;
  final Future<void> Function() onShare;
  final VoidCallback onReport;

  Widget _row(BuildContext context, String label, String value, {bool bold = false}) {
    final style = bold ? context.text.title : context.text.body;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: bold ? style : style.copyWith(color: RawanaColors.onSurfaceMuted))),
          Text(value, style: style),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tax = trip.taxAmount ?? 0;
    final discount = trip.discountAmount ?? 0;
    final credit = trip.creditApplied ?? 0;
    final fee = trip.outstandingFeeApplied;
    final fareLine = (trip.rideFare - tax + credit + discount).clamp(0, 1 << 31);
    final meta = [
      if (trip.rideTypeName != null) trip.rideTypeName!,
      if (trip.distanceKm != null) '${trip.distanceKm!.toStringAsFixed(1)} km',
      if (trip.durationMinutes != null) '${trip.durationMinutes} min',
    ].join(' · ');
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RawanaGrabber(),
            Text(l10n.tripReceipt, style: context.text.headline),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(meta, style: context.text.caption),
            ],
            const SizedBox(height: 14),
            TripRouteAddresses(pickupAddress: trip.pickupAddress, dropoffAddress: trip.dropoffAddress, dense: true),
            const Divider(height: 28),
            _row(context, l10n.fareLabel, AfnFormatter.format(fareLine)),
            if (tax > 0) _row(context, l10n.taxLabel, AfnFormatter.format(tax)),
            if (discount > 0) _row(context, l10n.discount, '−${AfnFormatter.format(discount)}'),
            if (credit > 0) _row(context, l10n.creditFromRawana, '−${AfnFormatter.format(credit)}'),
            if (fee > 0) _row(context, l10n.txFeeCollected, '+${AfnFormatter.format(fee)}'),
            if (tip > 0) _row(context, l10n.tipLabel, '+${AfnFormatter.format(tip)}'),
            const Divider(height: 20),
            _row(context, l10n.totalPaidCash, AfnFormatter.format(trip.cashToCollect + tip), bold: true),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onShare,
              icon: const Icon(LucideIcons.share2, size: 18),
              label: Text(l10n.shareReceipt),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            TextButton.icon(
              onPressed: onReport,
              icon: const Icon(LucideIcons.flag, size: 16),
              label: Text(l10n.reportAnIssue),
            ),
          ],
        ),
      ),
    );
  }
}
