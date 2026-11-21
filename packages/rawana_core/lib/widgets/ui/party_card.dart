import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/rawana_theme.dart';
import 'rawana_avatar.dart';
import 'ride_vehicle_art.dart';
import 'star_rating.dart';

/// Round contact button used on driver / passenger cards (call, chat).
class PartyActionButton extends StatelessWidget {
  const PartyActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badgeCount = 0,
    this.size = 48,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final int badgeCount;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: RawanaColors.surfaceAlt,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, size: size * 0.42, color: RawanaColors.primaryDeep),
        ),
      ),
    );
    return Tooltip(
      message: tooltip,
      child: badgeCount <= 0
          ? button
          : Badge(
              label: Text(badgeCount > 9 ? '9+' : '$badgeCount'),
              backgroundColor: RawanaColors.error,
              child: button,
            ),
    );
  }
}

/// Driver card shown to the passenger once matched: photo, name, rating,
/// large plate, car model / colour and contact buttons.
class DriverCard extends StatelessWidget {
  const DriverCard({
    super.key,
    required this.name,
    this.photoUrl,
    this.rating,
    this.vehicleLabel,
    this.plate,
    this.vehicleImageKey,
    this.onCall,
    this.onChat,
    this.chatUnread = 0,
    required this.callLabel,
    required this.chatLabel,
  });

  final String name;
  final String? photoUrl;
  final double? rating;

  /// e.g. "White Toyota Corolla".
  final String? vehicleLabel;
  final String? plate;
  final String? vehicleImageKey;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final int chatUnread;
  final String callLabel;
  final String chatLabel;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final hasPlate = plate != null && plate!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasPlate) PlateBadge(plate: plate!),
                  if (vehicleLabel != null && vehicleLabel!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      vehicleLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.caption.copyWith(color: RawanaColors.onSurface),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              width: 104,
              height: 56,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  PositionedDirectional(
                    start: 0,
                    top: 8,
                    child: RideVehicleArt(imageKey: vehicleImageKey, width: 72),
                  ),
                  PositionedDirectional(
                    end: 0,
                    top: 0,
                    child: RawanaAvatar(name: name, photoUrl: photoUrl, size: 52, ring: true),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.title),
                  if (rating != null) ...[
                    const SizedBox(height: 2),
                    RatingBadge(rating: rating!, dense: true),
                  ],
                ],
              ),
            ),
            if (onChat != null) ...[
              PartyActionButton(
                icon: LucideIcons.messageCircle,
                tooltip: chatLabel,
                onPressed: onChat,
                badgeCount: chatUnread,
              ),
              const SizedBox(width: 10),
            ],
            if (onCall != null)
              PartyActionButton(icon: LucideIcons.phone, tooltip: callLabel, onPressed: onCall),
          ],
        ),
      ],
    );
  }
}

/// Licence plate styled like a physical plate so it is easy to match.
class PlateBadge extends StatelessWidget {
  const PlateBadge({super.key, required this.plate});

  final String plate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: RawanaColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RawanaColors.onSurface, width: 1.6),
      ),
      child: Text(
        plate.toUpperCase(),
        style: context.text.headline.copyWith(fontSize: 20, letterSpacing: 1.2),
        textDirection: TextDirection.ltr,
      ),
    );
  }
}

/// Passenger row shown to the driver: photo, name, rating, contact buttons.
class PassengerCard extends StatelessWidget {
  const PassengerCard({
    super.key,
    required this.name,
    this.photoUrl,
    this.rating,
    this.subtitle,
    this.onCall,
    this.onChat,
    this.chatUnread = 0,
    required this.callLabel,
    required this.chatLabel,
  });

  final String name;
  final String? photoUrl;
  final double? rating;
  final String? subtitle;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final int chatUnread;
  final String callLabel;
  final String chatLabel;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Row(
      children: [
        RawanaAvatar(name: name, photoUrl: photoUrl, size: 52),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.title),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (rating != null) ...[
                    RatingBadge(rating: rating!, dense: true),
                    if (subtitle != null) const SizedBox(width: 8),
                  ],
                  if (subtitle != null)
                    Flexible(
                      child: Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.caption,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (onChat != null) ...[
          PartyActionButton(
            icon: LucideIcons.messageCircle,
            tooltip: chatLabel,
            onPressed: onChat,
            badgeCount: chatUnread,
            size: 52,
          ),
          const SizedBox(width: 10),
        ],
        if (onCall != null)
          PartyActionButton(
            icon: LucideIcons.phone,
            tooltip: callLabel,
            onPressed: onCall,
            size: 52,
          ),
      ],
    );
  }
}
