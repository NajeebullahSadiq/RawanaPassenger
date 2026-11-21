import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/booking_l10n.dart';
import '../l10n/l10n_extensions.dart';
import '../models/trip.dart';
import '../theme/rawana_theme.dart';
import '../currency/afn_formatter.dart';
import '../widgets/trip_route_addresses.dart';
import '../widgets/ui/rawana_async_body.dart';
import '../widgets/ui/rawana_avatar.dart';
import '../widgets/ui/rawana_scaffold.dart';
import '../widgets/ui/rawana_skeleton.dart';
import '../widgets/ui/rawana_trip_row.dart';

/// Past-trip page shared by both apps: route map, summary, fare, the other
/// party and app-specific actions (receipt, report, navigation).
class RawanaTripDetailView extends StatelessWidget {
  const RawanaTripDetailView({
    super.key,
    required this.tripId,
    required this.trip,
    required this.error,
    required this.onRefresh,
    required this.partyLabel,
    required this.partyOf,
    this.mapBuilder,
    this.partyActionsBuilder,
    this.actionsBuilder,
  });

  final String tripId;
  final Trip? trip;
  final Object? error;
  final Future<void> Function() onRefresh;

  /// "Driver" in the rider app, "Passenger" in the driver app.
  final String partyLabel;
  final TripParty? Function(Trip trip) partyOf;
  final Widget? Function(BuildContext context, Trip trip)? mapBuilder;
  final List<Widget> Function(BuildContext context, Trip trip)? partyActionsBuilder;
  final List<Widget> Function(BuildContext context, Trip trip)? actionsBuilder;

  @override
  Widget build(BuildContext context) {
    final shortId = tripId.length >= 6 ? tripId.substring(0, 6).toUpperCase() : tripId.toUpperCase();
    return RawanaScaffold(
      title: context.l10n.tripTitleWithId(shortId),
      body: RawanaAsyncBody<Trip>(
        data: trip,
        error: error,
        onRefresh: onRefresh,
        skeleton: const _DetailSkeleton(),
        builder: (context, t) => _DetailBody(view: this, trip: t),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.view, required this.trip});

  final RawanaTripDetailView view;
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final party = view.partyOf(trip);
    final when = trip.createdAt?.toLocal();
    final map = view.mapBuilder?.call(context, trip);
    final actions = view.actionsBuilder?.call(context, trip) ?? const [];
    final partyActions = view.partyActionsBuilder?.call(context, trip) ?? const [];
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: RawanaScaffold.pagePadding,
      children: [
        if (map != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
            child: SizedBox(height: 200, child: map),
          ),
          const SizedBox(height: 16),
        ],
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      when == null ? l10n.tripSummary : intl.DateFormat.yMMMd(l10n.localeName).add_jm().format(when),
                      style: context.text.subtitle,
                    ),
                  ),
                  TripStatusPill(status: trip.status),
                ],
              ),
              const SizedBox(height: 16),
              TripRouteAddresses(
                pickupAddress: trip.pickupAddress.isEmpty ? l10n.unknownPickup : trip.pickupAddress,
                dropoffAddress: trip.dropoffAddress.isEmpty ? l10n.unknownDestination : trip.dropoffAddress,
              ),
              if (trip.distanceKm != null || trip.durationMinutes != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (trip.distanceKm != null)
                      Expanded(
                        child: _Metric(
                          icon: LucideIcons.route,
                          label: l10n.distanceKm(trip.distanceKm!.toStringAsFixed(1)),
                        ),
                      ),
                    if (trip.distanceKm != null && trip.durationMinutes != null) const SizedBox(width: 8),
                    if (trip.durationMinutes != null)
                      Expanded(
                        child: _Metric(icon: LucideIcons.clock, label: l10n.durationMin('${trip.durationMinutes}')),
                      ),
                  ],
                ),
              ],
              if (trip.status == TripStatus.cancelled && (trip.cancellationReason ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(trip.cancellationReason!, style: context.text.caption),
              ],
              const Divider(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.totalFare, style: context.text.bodyStrong),
                        const SizedBox(height: 2),
                        Text(
                          trip.tipAmount > 0
                              ? '${l10n.cashLabel} · ${l10n.includesTip(AfnFormatter.format(trip.tipAmount))}'
                              : l10n.cashLabel,
                          style: context.text.caption,
                        ),
                      ],
                    ),
                  ),
                  Text(AfnFormatter.format(trip.cashToCollect), style: context.text.priceLarge),
                ],
              ),
            ],
          ),
        ),
        if (party?.name != null) ...[
          const SizedBox(height: 12),
          _Card(
            child: Row(
              children: [
                RawanaAvatar(name: party!.name!, photoUrl: party.profilePhotoUrl, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(view.partyLabel, style: context.text.label.copyWith(color: RawanaColors.onSurfaceMuted)),
                      const SizedBox(height: 2),
                      Text(party.name!, style: context.text.bodyStrong),
                      if (_vehicle(party) != null) ...[
                        const SizedBox(height: 2),
                        Text(_vehicle(party)!, style: context.text.caption),
                      ],
                    ],
                  ),
                ),
                if (party.ratingAverage != null && party.ratingAverage! > 0) ...[
                  const Icon(LucideIcons.star, size: 14, color: RawanaColors.warning),
                  const SizedBox(width: 4),
                  Text(party.ratingAverage!.toStringAsFixed(1), style: context.text.bodyStrong),
                ],
                ...partyActions,
              ],
            ),
          ),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            actions[i],
          ],
        ],
      ],
    );
  }

  static String? _vehicle(TripParty p) {
    final parts = [p.vehicleColour, p.vehicleMake, p.vehicleModel].whereType<String>().where((s) => s.isNotEmpty);
    final car = parts.join(' ');
    final plate = p.plateNumber ?? '';
    if (car.isEmpty && plate.isEmpty) return null;
    return [car, plate].where((s) => s.isNotEmpty).join(' · ');
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
        border: Border.all(color: RawanaColors.divider),
      ),
      child: child,
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: RawanaColors.surfaceAlt,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: RawanaColors.primary),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: context.text.label.copyWith(color: RawanaColors.onSurface))),
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: RawanaScaffold.pagePadding,
      children: const [
        RawanaSkeleton(height: 200, radius: RawanaSpacing.radiusLg),
        SizedBox(height: 16),
        RawanaSkeleton(height: 220, radius: RawanaSpacing.radiusLg),
        SizedBox(height: 12),
        RawanaSkeletonRow(),
      ],
    );
  }
}
