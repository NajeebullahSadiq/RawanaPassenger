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
  ConsumerState<ScheduledRidesScreen> createState() =>
      _ScheduledRidesScreenState();
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
    final choice = await showPickupTimeSheet(
      context,
      initial: earliestScheduledPickup(),
    );
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
      final freeUntil = policy.freeCancelUntil;
      final message = policy.feeApplies
          ? context.l10n.scheduledCancelFee(
              AfnFormatter.format(policy.cancellationFee),
            )
          : freeUntil != null && freeUntil.isAfter(DateTime.now())
          ? context.l10n.freeCancelUntil(formatScheduledTime(context, freeUntil))
          : context.l10n.noCancellationFee;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.l10n.cancelScheduledRideTitle),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.l10n.keepRide),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: RawanaColors.error),
              child: Text(ctx.l10n.cancelRide),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await service.cancelRide(trip.id, reason: 'passenger_cancelled_scheduled');
      ref.invalidate(scheduledRidesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.scheduledRideCancelled)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
      ref.invalidate(scheduledRidesProvider);
    } finally {
      if (mounted) setState(() => _cancellingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ridesAsync = ref.watch(scheduledRidesProvider);
    return Scaffold(
      backgroundColor: RawanaColors.surface,
      appBar: AppBar(
        title: Text(context.l10n.scheduledRides),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: _back,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scheduleNew,
        icon: const Icon(LucideIcons.calendarPlus),
        label: Text(context.l10n.scheduleRideCta),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(scheduledRidesProvider.future),
        child: ridesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 80),
              RawanaEmptyState.error(
                message: apiErrorMessage(e),
                action: OutlinedButton(
                  onPressed: () => ref.invalidate(scheduledRidesProvider),
                  child: Text(context.l10n.retry),
                ),
              ),
            ],
          ),
          data: (rides) {
            if (rides.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  RawanaEmptyState(
                    icon: LucideIcons.calendarClock,
                    title: context.l10n.noScheduledRides,
                    message: context.l10n.noScheduledRidesHint,
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: rides.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _ScheduledRideCard(
                trip: rides[i],
                cancelling: _cancellingId == rides[i].id,
                onCancel: () => _cancel(rides[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ScheduledRideCard extends StatelessWidget {
  const _ScheduledRideCard({
    required this.trip,
    required this.cancelling,
    required this.onCancel,
  });

  final Trip trip;
  final bool cancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final driver = trip.driver;
    final confirmed = trip.hasReservedDriver;
    final statusColor = confirmed ? RawanaColors.success : RawanaColors.warning;
    final vehicle = [
      driver?.vehicleColour,
      driver?.vehicleMake,
      driver?.vehicleModel,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
        border: Border.all(color: RawanaColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: RawanaColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.calendarClock,
                  color: RawanaColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.scheduledAt != null
                          ? formatScheduledTime(context, trip.scheduledAt!)
                          : '—',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (trip.rideTypeName != null)
                      Text(
                        trip.rideTypeName!,
                        style: const TextStyle(
                          color: RawanaColors.onSurfaceMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                AfnFormatter.format(trip.cashToCollect),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _AddressLine(
            icon: LucideIcons.circleDot,
            color: RawanaColors.primary,
            text: trip.pickupAddress,
          ),
          const SizedBox(height: 6),
          _AddressLine(
            icon: LucideIcons.mapPin,
            color: RawanaColors.error,
            text: trip.dropoffAddress,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  confirmed ? LucideIcons.badgeCheck : LucideIcons.hourglass,
                  color: statusColor,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        confirmed
                            ? context.l10n.driverConfirmed
                            : context.l10n.driverAssignedBeforePickup,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          fontSize: 13,
                        ),
                      ),
                      if (confirmed && driver?.name != null)
                        Text(
                          [
                            driver!.name!,
                            if (vehicle.isNotEmpty) vehicle,
                            if (driver.plateNumber != null) driver.plateNumber!,
                          ].join(' · '),
                          style: const TextStyle(
                            fontSize: 12,
                            color: RawanaColors.onSurfaceMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: cancelling ? null : onCancel,
              style: TextButton.styleFrom(foregroundColor: RawanaColors.error),
              icon: cancelling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.x, size: 16),
              label: Text(context.l10n.cancelRide),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressLine extends StatelessWidget {
  const _AddressLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
