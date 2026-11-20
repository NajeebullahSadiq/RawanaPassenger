import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/trip_providers.dart';
import '../widgets/schedule_pickup_sheet.dart';

class ScheduledRidesScreen extends ConsumerStatefulWidget {
  const ScheduledRidesScreen({super.key});

  @override
  ConsumerState<ScheduledRidesScreen> createState() => _ScheduledRidesScreenState();
}

class _ScheduledRidesScreenState extends ConsumerState<ScheduledRidesScreen> {
  String? _cancellingId;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _scheduleNew() async {
    final choice = await showPickupTimeSheet(context, initial: earliestScheduledPickup());
    if (choice == null || !mounted) return;
    ref.read(scheduledPickupProvider.notifier).state = choice.at;
    context.push('/destination');
  }

  Future<void> _cancel(Trip trip) async {
    if (_cancellingId != null) return;
    setState(() => _cancellingId = trip.id);
    try {
      final service = ref.read(tripServiceProvider);
      final policy = await service.getCancellationPolicy(trip.id);
      if (!mounted) return;
      final l10n = context.l10n;
      final freeUntil = policy.freeCancelUntil;
      final message = policy.feeApplies
          ? l10n.scheduledCancelFee(AfnFormatter.format(policy.cancellationFee))
          : freeUntil != null && freeUntil.isAfter(DateTime.now())
              ? l10n.freeCancelUntil(formatScheduledTime(context, freeUntil))
              : l10n.noCancellationFee;
      final confirmed = await RawanaActionSheet.confirm(
        context,
        title: l10n.cancelScheduledRideTitle,
        message: message,
        confirmLabel: l10n.cancelRide,
        cancelLabel: l10n.keepRide,
        destructive: true,
        icon: LucideIcons.calendarX,
      );
      if (!confirmed || !mounted) return;
      await service.cancelRide(trip.id, reason: 'passenger_cancelled_scheduled');
      ref.invalidate(scheduledRidesProvider);
      if (mounted) showRawanaToast(context, context.l10n.scheduledRideCancelled, icon: LucideIcons.circleCheck);
    } catch (e) {
      if (mounted) showRawanaError(context, e);
      ref.invalidate(scheduledRidesProvider);
    } finally {
      if (mounted) setState(() => _cancellingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ridesAsync = ref.watch(scheduledRidesProvider);
    return RawanaScaffold(
      title: l10n.scheduledRides,
      onBack: _back,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scheduleNew,
        icon: const Icon(LucideIcons.calendarPlus),
        label: Text(l10n.scheduleRideCta),
        backgroundColor: RawanaColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RawanaAsyncBody<List<Trip>>(
        data: ridesAsync.valueOrNull,
        error: ridesAsync.error,
        onRetry: () => ref.invalidate(scheduledRidesProvider),
        onRefresh: () => ref.refresh(scheduledRidesProvider.future),
        isEmpty: (rides) => rides.isEmpty,
        empty: RawanaEmptyState(
          icon: LucideIcons.calendarClock,
          title: l10n.noScheduledRides,
          message: l10n.noScheduledRidesHint,
        ),
        builder: (context, rides) => ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: rides.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _ScheduledRideCard(
            trip: rides[i],
            cancelling: _cancellingId == rides[i].id,
            onCancel: () => _cancel(rides[i]),
          ),
        ),
      ),
    );
  }
}

class _ScheduledRideCard extends StatelessWidget {
  const _ScheduledRideCard({required this.trip, required this.cancelling, required this.onCancel});

  final Trip trip;
  final bool cancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final driver = trip.driver;
    final confirmed = trip.hasReservedDriver;
    final vehicle = [driver?.vehicleColour, driver?.vehicleMake, driver?.vehicleModel]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' ');
    final driverLine = confirmed && driver?.name != null
        ? [driver!.name!, if (vehicle.isNotEmpty) vehicle, ?driver.plateNumber].join(' · ')
        : null;
    return RawanaSurfaceCard(
      padding: const EdgeInsets.all(16),
      shadows: const [],
      border: Border.all(color: RawanaColors.divider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: RawanaColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(RawanaSpacing.radiusSm),
                ),
                child: const Icon(LucideIcons.calendarClock, color: RawanaColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.scheduledAt != null ? formatScheduledTime(context, trip.scheduledAt!) : '—',
                      style: context.text.title,
                    ),
                    if (trip.rideTypeName != null) Text(trip.rideTypeName!, style: context.text.caption),
                  ],
                ),
              ),
              Text(AfnFormatter.format(trip.cashToCollect), style: context.text.price),
            ],
          ),
          const SizedBox(height: 14),
          TripRouteAddresses(pickupAddress: trip.pickupAddress, dropoffAddress: trip.dropoffAddress, dense: true),
          const SizedBox(height: 14),
          RawanaBanner(
            tone: confirmed ? RawanaBannerTone.success : RawanaBannerTone.warning,
            icon: confirmed ? LucideIcons.badgeCheck : LucideIcons.hourglass,
            message: driverLine == null
                ? (confirmed ? l10n.driverConfirmed : l10n.driverAssignedBeforePickup)
                : '${l10n.driverConfirmed}\n$driverLine',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: cancelling ? null : onCancel,
              style: TextButton.styleFrom(foregroundColor: RawanaColors.error),
              icon: cancelling
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.x, size: 16),
              label: Text(l10n.cancelRide),
            ),
          ),
        ],
      ),
    );
  }
}
