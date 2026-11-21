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
  int _nextPage = 2;
  bool _loadingMore = false;
  Object? _loadMoreError;

  void _resetPaging() {
    _extra.clear();
    _nextPage = 2;
    _loadMoreError = null;
  }

  void _setFilter(HistoryFilter next) {
    setState(_resetPaging);
    ref.read(historyFilterProvider.notifier).state = next;
  }

  Future<void> _refresh() {
    setState(_resetPaging);
    return ref.refresh(tripHistoryProvider.future);
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    final filter = ref.read(historyFilterProvider);
    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });
    try {
      final next = await ref.read(passengerServiceProvider).getTripHistory(
            page: _nextPage,
            status: filter.status,
            from: filter.from,
            to: filter.to,
          );
      if (!mounted || !identical(filter, ref.read(historyFilterProvider))) return;
      setState(() {
        _extra.addAll(next.trips);
        _nextPage++;
      });
    } catch (e) {
      if (mounted) setState(() => _loadMoreError = e);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final filter = ref.read(historyFilterProvider);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? filter.from : filter.to) ?? now,
      firstDate: isFrom ? DateTime(2024) : (filter.from ?? DateTime(2024)),
      lastDate: isFrom ? (filter.to ?? now) : now,
    );
    if (picked == null) return;
    _setFilter(isFrom ? filter.copyWith(from: picked) : filter.copyWith(to: picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final historyAsync = ref.watch(tripHistoryProvider);
    final filter = ref.watch(historyFilterProvider);
    final dateFormat = DateFormat.yMMMd(l10n.localeName);
    final hasFilters = filter.status != null || filter.from != null || filter.to != null;
    return RawanaScaffold(
      title: l10n.rideHistory,
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                _FilterChip(
                  label: l10n.allTrips,
                  selected: filter.status == null,
                  onTap: () => _setFilter(filter.copyWith(clearStatus: true)),
                ),
                _FilterChip(
                  label: l10n.statusCompleted,
                  selected: filter.status == 'completed',
                  onTap: () => _setFilter(filter.copyWith(status: 'completed')),
                ),
                _FilterChip(
                  label: l10n.statusCancelled,
                  selected: filter.status == 'cancelled',
                  onTap: () => _setFilter(filter.copyWith(status: 'cancelled')),
                ),
                _FilterChip(
                  icon: LucideIcons.calendar,
                  label: filter.from == null ? l10n.filterFrom : dateFormat.format(filter.from!),
                  selected: filter.from != null,
                  onTap: () => _pickDate(isFrom: true),
                ),
                _FilterChip(
                  icon: LucideIcons.calendar,
                  label: filter.to == null ? l10n.filterTo : dateFormat.format(filter.to!),
                  selected: filter.to != null,
                  onTap: () => _pickDate(isFrom: false),
                ),
                if (hasFilters)
                  _FilterChip(
                    icon: LucideIcons.x,
                    label: l10n.clearFilters,
                    selected: false,
                    onTap: () => _setFilter(const HistoryFilter()),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RawanaAsyncBody<({List<Trip> trips, int total})>(
              data: historyAsync.isLoading && !historyAsync.isRefreshing ? null : historyAsync.valueOrNull,
              error: historyAsync.error,
              onRetry: () => ref.invalidate(tripHistoryProvider),
              onRefresh: _refresh,
              isEmpty: (page) => page.trips.isEmpty,
              empty: RawanaEmptyState(
                icon: LucideIcons.history,
                title: l10n.noTripsYet,
                message: l10n.pastRidesHint,
                action: hasFilters
                    ? OutlinedButton(onPressed: () => _setFilter(const HistoryFilter()), child: Text(l10n.clearFilters))
                    : null,
              ),
              builder: (context, page) {
                final trips = [...page.trips, ..._extra];
                final hasMore = trips.length < page.total;
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: trips.length + (hasMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    if (i >= trips.length) {
                      return _LoadMore(loading: _loadingMore, error: _loadMoreError, onLoad: _loadMore);
                    }
                    final trip = trips[i];
                    final when = trip.createdAt?.toLocal();
                    return RawanaTripRow(
                      pickup: trip.pickupAddress,
                      dropoff: trip.dropoffAddress,
                      when: when == null ? null : '${dateFormat.format(when)} · ${DateFormat.jm(l10n.localeName).format(when)}',
                      amount: AfnFormatter.format(trip.cashToCollect),
                      status: TripStatusPill(status: trip.status),
                      onTap: () => context.push('/trip/${trip.id}'),
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

class _LoadMore extends StatelessWidget {
  const _LoadMore({required this.loading, required this.error, required this.onLoad});

  final bool loading;
  final Object? error;
  final VoidCallback onLoad;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (error != null) {
      return RawanaBanner.error(
        message: l10n.friendlyApiError(error!),
        action: TextButton(onPressed: onLoad, child: Text(l10n.tryAgain)),
      );
    }
    return Center(
      child: TextButton.icon(
        onPressed: onLoad,
        icon: const Icon(LucideIcons.chevronDown, size: 18),
        label: Text(l10n.loadMore),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = selected ? RawanaColors.primary : RawanaColors.onSurfaceMuted;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: FilterChip(
        avatar: icon == null ? null : Icon(icon, size: 16, color: color),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: RawanaColors.primary.withValues(alpha: 0.14),
        labelStyle: context.text.label.copyWith(color: color),
      ),
    );
  }
}
