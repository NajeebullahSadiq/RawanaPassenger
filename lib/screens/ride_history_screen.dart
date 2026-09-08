import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/history_providers.dart';
import '../providers/trip_providers.dart';

class RideHistoryScreen extends ConsumerStatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  ConsumerState<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends ConsumerState<RideHistoryScreen> {
  final List<Trip> _extra = [];
  bool _loadingMore = false;

  Color _statusColor(TripStatus s) => switch (s) {
        TripStatus.completed => RawanaColors.success,
        TripStatus.cancelled => RawanaColors.error,
        _ => RawanaColors.warning,
      };

  IconData _statusIcon(TripStatus s) => switch (s) {
        TripStatus.completed => LucideIcons.check,
        TripStatus.cancelled => LucideIcons.x,
        _ => LucideIcons.timer,
      };

  Future<void> _pickDate(BuildContext context, WidgetRef ref, {required bool isFrom}) async {
    final filter = ref.read(historyFilterProvider);
    final initial = (isFrom ? filter.from : filter.to) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    ref.read(historyFilterProvider.notifier).state = isFrom
        ? filter.copyWith(from: picked)
        : filter.copyWith(to: picked);
  }

  String _dateLabel(DateTime? value, String fallback) {
    if (value == null) return fallback;
    return DateFormat.yMMMd().format(value);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(historyFilterProvider, (_, _) {
      _extra.clear();
    });
    final historyAsync = ref.watch(tripHistoryProvider);
    final filter = ref.watch(historyFilterProvider);
    return Scaffold(
      backgroundColor: RawanaColors.surface,
      appBar: AppBar(title: Text(context.l10n.rideHistory)),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _FilterChip(
                  label: context.l10n.allTrips,
                  selected: filter.status == null,
                  onTap: () => ref.read(historyFilterProvider.notifier).state =
                      filter.copyWith(clearStatus: true),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: context.l10n.statusCompleted,
                  selected: filter.status == 'completed',
                  onTap: () => ref.read(historyFilterProvider.notifier).state =
                      filter.copyWith(status: 'completed'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: context.l10n.statusCancelled,
                  selected: filter.status == 'cancelled',
                  onTap: () => ref.read(historyFilterProvider.notifier).state =
                      filter.copyWith(status: 'cancelled'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _dateLabel(filter.from, context.l10n.filterFrom),
                  selected: filter.from != null,
                  onTap: () => _pickDate(context, ref, isFrom: true),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _dateLabel(filter.to, context.l10n.filterTo),
                  selected: filter.to != null,
                  onTap: () => _pickDate(context, ref, isFrom: false),
                ),
                if (filter.status != null || filter.from != null || filter.to != null) ...[
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: context.l10n.clearFilters,
                    selected: false,
                    onTap: () => ref.read(historyFilterProvider.notifier).state =
                        const HistoryFilter(),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(context.l10n.failedToLoadHistory('$e'))),
              data: (page) {
                final trips = [...page.trips, ..._extra];
                if (trips.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: RawanaColors.primary.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.clock, color: RawanaColors.primary, size: 38),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.l10n.noTripsYet,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.l10n.pastRidesHint,
                            style: const TextStyle(color: RawanaColors.onSurfaceMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final hasMore = trips.length < page.total;
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: trips.length + (hasMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    if (i >= trips.length) {
                      return TextButton(
                        onPressed: _loadingMore
                            ? null
                            : () async {
                                setState(() => _loadingMore = true);
                                try {
                                  final filter = ref.read(historyFilterProvider);
                                  final next = await ref.read(passengerServiceProvider).getTripHistory(
                                        page: (trips.length ~/ 20) + 1,
                                        status: filter.status,
                                        from: filter.from,
                                        to: filter.to,
                                      );
                                  if (mounted) {
                                    setState(() => _extra.addAll(next.trips));
                                  }
                                } finally {
                                  if (mounted) setState(() => _loadingMore = false);
                                }
                              },
                        child: Text(_loadingMore ? '…' : context.l10n.loadMore),
                      );
                    }
                    final trip = trips[i];
                    final fare = trip.cashToCollect;
                    final color = _statusColor(trip.status);
                    final when = trip.createdAt;
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
                        onTap: () => context.push('/trip/${trip.id}'),
                        child: Ink(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
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
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(_statusIcon(trip.status), color: color, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          trip.dropoffAddress,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                        ),
                                        Text(
                                          context.l10n.fromAddress(trip.pickupAddress),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: RawanaColors.onSurfaceMuted, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    AfnFormatter.format(fare),
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  StatusChip(
                                    label: context.l10n.tripStatusLabel(trip.status.apiValue),
                                    color: color,
                                    icon: _statusIcon(trip.status),
                                  ),
                                  if (when != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat.yMMMd().format(when.toLocal()),
                                      style: const TextStyle(
                                        color: RawanaColors.onSurfaceMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  const Icon(LucideIcons.arrowRight, size: 16, color: RawanaColors.onSurfaceFaint),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: RawanaColors.primary.withValues(alpha: 0.14),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: selected ? RawanaColors.primary : RawanaColors.onSurfaceMuted,
      ),
    );
  }
}
