import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_providers.dart';
import '../providers/history_providers.dart';
import '../providers/trip_providers.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  Future<void> _receipt(BuildContext context, WidgetRef ref, Trip trip) async {
    final l10n = context.l10n;
    final String? url;
    try {
      url = await ref.read(passengerServiceProvider).getTripReceiptUrl(trip.id);
    } catch (e) {
      if (context.mounted) showRawanaError(context, e);
      return;
    }
    if (!context.mounted) return;
    if (url == null) {
      showRawanaToast(context, l10n.receiptNotReady, error: true);
      return;
    }
    final choice = await RawanaActionSheet.menu<String>(
      context,
      title: l10n.tripReceipt,
      options: [
        RawanaSheetOption(value: 'open', label: l10n.openReceipt, icon: LucideIcons.externalLink),
        RawanaSheetOption(value: 'share', label: l10n.shareReceipt, icon: LucideIcons.share2),
      ],
    );
    if (choice == 'open') {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else if (choice == 'share') {
      await Share.share(url, subject: l10n.tripReceipt);
    }
  }

  Widget? _map(BuildContext context, WidgetRef ref, Trip trip) {
    final hasRoute =
        trip.pickupLat != null && trip.pickupLng != null && trip.dropoffLat != null && trip.dropoffLng != null;
    Widget liveMap() => TripRouteMap(
          mapsService: ref.read(mapsServiceProvider),
          originLat: trip.pickupLat!,
          originLng: trip.pickupLng!,
          destLat: trip.dropoffLat!,
          destLng: trip.dropoffLng!,
          markers: [
            RawanaMapMarker.passenger(lat: trip.pickupLat!, lng: trip.pickupLng!, label: context.l10n.pickup),
            RawanaMapMarker.dropoff(lat: trip.dropoffLat!, lng: trip.dropoffLng!),
          ],
        );
    final snapshot = trip.routeSnapshotUrl;
    if (snapshot != null && snapshot.isNotEmpty) {
      final api = ref.read(apiClientProvider);
      // Served by the API behind auth so the Maps key never reaches the client.
      return Image.network(
        api.absoluteUrl(snapshot),
        headers: api.authHeaders(),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => hasRoute ? liveMap() : const ColoredBox(color: RawanaColors.surfaceAlt),
      );
    }
    return hasRoute ? liveMap() : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripDetailProvider(tripId));
    return RawanaTripDetailView(
      tripId: tripId,
      trip: tripAsync.valueOrNull,
      error: tripAsync.hasError ? tripAsync.error : null,
      onRefresh: () => ref.refresh(tripDetailProvider(tripId).future),
      partyLabel: context.l10n.driverLabel,
      partyOf: (t) => t.driver,
      mapBuilder: (context, t) => _map(context, ref, t),
      partyActionsBuilder: (context, t) => [
        if (t.status.isActive) ...[
          IconButton(
            tooltip: context.l10n.whatsAppDriver,
            icon: const Icon(LucideIcons.messageCircle, color: RawanaColors.primary),
            onPressed: () async {
              final ok = await messageTripParty(ref.read(apiClientProvider), t.id);
              if (!ok && context.mounted) {
                showRawanaToast(context, context.l10n.couldNotOpenWhatsAppMessages, error: true);
              }
            },
          ),
          IconButton(
            tooltip: context.l10n.whatsAppCallDriver,
            icon: const Icon(LucideIcons.phone, color: RawanaColors.primary),
            onPressed: () async {
              final ok = await callTripParty(ref.read(apiClientProvider), t.id);
              if (!ok && context.mounted) {
                showRawanaToast(context, context.l10n.couldNotOpenWhatsAppCall, error: true);
              }
            },
          ),
        ],
      ],
      actionsBuilder: (context, t) => [
        if (t.status == TripStatus.completed)
          OutlinedButton.icon(
            onPressed: () => _receipt(context, ref, t),
            icon: const Icon(LucideIcons.receipt, size: 18),
            label: Text(context.l10n.viewReceipt),
          ),
        if (t.status == TripStatus.completed || t.status == TripStatus.cancelled)
          OutlinedButton.icon(
            onPressed: () => showReportIssueSheet(
              context,
              supportService: ref.read(supportServiceProvider),
              tripId: t.id,
            ),
            icon: const Icon(LucideIcons.flag, size: 18),
            label: Text(context.l10n.reportAnIssue),
          ),
      ],
    );
  }
}
