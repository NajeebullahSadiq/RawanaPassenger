import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/history_providers.dart';
import '../providers/trip_providers.dart';
import '../providers/app_providers.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripDetailProvider(tripId));
    return Scaffold(
      backgroundColor: RawanaColors.surface,
      appBar: AppBar(title: Text(context.l10n.tripTitleWithId(tripId.substring(0, 6).toUpperCase()))),
      body: tripAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.errorWithDetail('$e'))),
        data: (trip) {
          final fare = trip.cashToCollect;
          final hasRoute = trip.pickupLat != null &&
              trip.pickupLng != null &&
              trip.dropoffLat != null &&
              trip.dropoffLng != null;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (trip.routeSnapshotUrl != null && trip.routeSnapshotUrl!.isNotEmpty)
                Container(
                  height: 220,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
                    boxShadow: RawanaShadows.floating,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
                    child: Image.network(
                      // Snapshot is served by the API behind auth so the Maps key
                      // never reaches the client.
                      ref.read(apiClientProvider).absoluteUrl(trip.routeSnapshotUrl!),
                      headers: ref.read(apiClientProvider).authHeaders(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => hasRoute
                          ? TripRouteMap(
                              mapsService: ref.read(mapsServiceProvider),
                              originLat: trip.pickupLat!,
                              originLng: trip.pickupLng!,
                              destLat: trip.dropoffLat!,
                              destLng: trip.dropoffLng!,
                              markers: [
                                RawanaMapMarker.passenger(
                                  lat: trip.pickupLat!,
                                  lng: trip.pickupLng!,
                                  label: context.l10n.pickup,
                                ),
                                RawanaMapMarker.dropoff(
                                  lat: trip.dropoffLat!,
                                  lng: trip.dropoffLng!,
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                )
              else if (hasRoute)
                Container(
                  height: 220,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
                    boxShadow: RawanaShadows.floating,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
                    child: TripRouteMap(
                      mapsService: ref.read(mapsServiceProvider),
                      originLat: trip.pickupLat!,
                      originLng: trip.pickupLng!,
                      destLat: trip.dropoffLat!,
                      destLng: trip.dropoffLng!,
                      markers: [
                        RawanaMapMarker.passenger(
                          lat: trip.pickupLat!,
                          lng: trip.pickupLng!,
                          label: context.l10n.pickup,
                        ),
                        RawanaMapMarker.dropoff(
                          lat: trip.dropoffLat!,
                          lng: trip.dropoffLng!,
                        ),
                      ],
                    ),
                  ),
                ),
              RawanaSurfaceCard(
                padding: const EdgeInsets.all(20),
                shadows: const [],
                border: Border.all(color: RawanaColors.divider),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          context.l10n.tripSummary,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3),
                        ),
                        const Spacer(),
                        StatusChip(
                          label: context.l10n.tripStatusLabel(trip.status.apiValue),
                          color: trip.status == TripStatus.completed ? RawanaColors.success : RawanaColors.error,
                          icon: trip.status == TripStatus.completed ? LucideIcons.check : LucideIcons.x,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _routeRow(LucideIcons.mapPin, context.l10n.pickup, trip.pickupAddress, RawanaColors.success),
                    const SizedBox(height: 10),
                    _routeRow(LucideIcons.flag, context.l10n.dropoff, trip.dropoffAddress, RawanaColors.dropoffPin),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      height: 1,
                      color: RawanaColors.divider,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.l10n.totalFare, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Text(
                          AfnFormatter.format(fare),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trip.driver?.name != null) ...[
                const SizedBox(height: 14),
                RawanaSurfaceCard(
                  padding: const EdgeInsets.all(16),
                  shadows: const [],
                  border: Border.all(color: RawanaColors.divider),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: RawanaColors.primary.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.user, color: RawanaColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.driverLabel,
                              style: const TextStyle(
                                color: RawanaColors.onSurfaceMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(trip.driver!.name!, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      if (trip.status.isActive) ...[
                        IconButton(
                          onPressed: () async {
                            final ok = await messageTripParty(
                              ref.read(apiClientProvider),
                              trip.id,
                            );
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.l10n.couldNotOpenWhatsAppMessages),
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            LucideIcons.messageCircle,
                            color: RawanaColors.primary,
                          ),
                          tooltip: context.l10n.whatsAppDriver,
                        ),
                        IconButton(
                          onPressed: () async {
                            final ok = await callTripParty(
                              ref.read(apiClientProvider),
                              trip.id,
                            );
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.l10n.couldNotOpenWhatsAppCall),
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            LucideIcons.phone,
                            color: RawanaColors.primary,
                          ),
                          tooltip: context.l10n.whatsAppCallDriver,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (trip.status == TripStatus.completed) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () async {
                    final url = await ref.read(passengerServiceProvider).getTripReceiptUrl(trip.id);
                    if (!context.mounted) return;
                    if (url == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.l10n.tripReceipt)),
                      );
                      return;
                    }
                    await Share.share(url, subject: context.l10n.tripReceipt);
                  },
                  icon: const Icon(LucideIcons.receipt, size: 18),
                  label: Text(context.l10n.viewReceipt),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReportIssueScreen(
                          supportService: ref.read(supportServiceProvider),
                          tripId: trip.id,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.flag, size: 18),
                  label: Text(context.l10n.reportAnIssue),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _routeRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: RawanaColors.onSurfaceMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
