import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';

String? vehicleLabelOf(TripParty? driver) {
  if (driver == null) return null;
  final label = [driver.vehicleColour, driver.vehicleMake, driver.vehicleModel]
      .where((e) => e != null && e.isNotEmpty)
      .join(' ');
  return label.isEmpty ? null : label;
}

/// Driver card for a matched trip, shared by the searching and live-trip sheets.
class TripDriverCard extends StatelessWidget {
  const TripDriverCard({super.key, required this.trip, this.onCall, this.onChat, this.chatUnread = 0});

  final Trip trip;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final int chatUnread;

  @override
  Widget build(BuildContext context) {
    final driver = trip.driver;
    return DriverCard(
      name: driver?.name ?? context.l10n.yourDriver,
      photoUrl: driver?.profilePhotoUrl,
      rating: driver?.ratingAverage,
      vehicleLabel: vehicleLabelOf(driver) ?? trip.rideTypeName,
      plate: driver?.plateNumber,
      vehicleImageKey: trip.rideArtKey,
      onCall: onCall,
      onChat: onChat,
      chatUnread: chatUnread,
      callLabel: context.l10n.call,
      chatLabel: context.l10n.openChat,
    );
  }
}

/// The 4-digit start PIN the passenger reads out to the driver.
class TripPinBadge extends StatelessWidget {
  const TripPinBadge({super.key, required this.pin});

  final String pin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: RawanaColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.keyRound, size: 18, color: RawanaColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.tripPinLabel, style: context.text.bodyStrong),
                Text(context.l10n.tripPinHint, style: context.text.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Digits stay left-to-right in RTL locales.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final d in pin.split(''))
                  Container(
                    width: 30,
                    height: 38,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: RawanaColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(d, style: context.text.headline.copyWith(color: RawanaColors.primary)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Cancel without fee in 45s" — ticks on its own so the sheet does not rebuild every second.
class FreeCancelCountdown extends StatefulWidget {
  const FreeCancelCountdown({super.key, required this.trip, required this.policy, required this.fetchedAt});

  final Trip trip;
  final CancellationPolicy? policy;
  final DateTime fetchedAt;

  @override
  State<FreeCancelCountdown> createState() => _FreeCancelCountdownState();
}

class _FreeCancelCountdownState extends State<FreeCancelCountdown> {
  Timer? _timer;

  int get _remaining => freeCancelSecondsRemaining(widget.trip, widget.policy, widget.fetchedAt);

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(FreeCancelCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.policy != widget.policy || oldWidget.trip.status != widget.trip.status) _start();
  }

  void _start() {
    _timer?.cancel();
    if (_remaining <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 0) _timer?.cancel();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = _remaining;
    if (left <= 0) return const SizedBox.shrink();
    return Text(
      context.l10n.cancelWithoutFeeIn('${left}s'),
      textAlign: TextAlign.center,
      style: context.text.caption,
    );
  }
}
