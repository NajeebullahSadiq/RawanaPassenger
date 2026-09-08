import 'package:flutter/material.dart';
import '../currency/afn_formatter.dart';
import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';
import 'rawana_sheet_handle.dart';
import 'rawana_surface_card.dart';
import 'trip_route_addresses.dart';

/// Uber/Ola-style bottom trip panel: status, ETA, party, route, navigate, actions.
class TripInfoSheet extends StatelessWidget {
  const TripInfoSheet({
    super.key,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.primaryAction,
    this.etaMinutes,
    this.distanceKm,
    this.partyName,
    this.partySubtitle,
    this.plateNumber,
    this.vehicleColour,
    this.profilePhotoUrl,
    this.partyPhone,
    this.rating,
    this.currentLabel,
    this.fareFormatted,
    this.fareLabel,
    this.onNavigate,
    this.navigateLabel,
    this.onOpenExternalMaps,
    this.openExternalMapsLabel,
    this.onCall,
    this.callLabel,
    this.onMessage,
    this.messageLabel,
    this.onShare,
    this.shareLabel,
    this.hintText,
    this.onCancel,
    this.cancelLoading = false,
    this.cancelLabel,
  });

  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final int? etaMinutes;
  final double? distanceKm;
  final String? partyName;
  final String? partySubtitle;
  final String? plateNumber;
  final String? vehicleColour;
  final String? profilePhotoUrl;
  final String? partyPhone;
  final double? rating;
  final String pickupAddress;
  final String dropoffAddress;
  final String? currentLabel;
  final String? fareFormatted;
  final String? fareLabel;
  final VoidCallback? onNavigate;
  final String? navigateLabel;
  final VoidCallback? onOpenExternalMaps;
  final String? openExternalMapsLabel;
  final VoidCallback? onCall;
  final String? callLabel;
  final VoidCallback? onMessage;
  final String? messageLabel;
  final VoidCallback? onShare;
  final String? shareLabel;
  final String? hintText;
  final Widget? primaryAction;
  final VoidCallback? onCancel;
  final bool cancelLoading;
  final String? cancelLabel;

  bool get _hasParty =>
      partyName != null && partyName!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final resolvedNavigate = navigateLabel ?? l10n.navigate;
    final resolvedCall = callLabel ?? l10n.call;
    final resolvedMessage = messageLabel ?? l10n.message;
    final resolvedShare = shareLabel ?? l10n.shareTrip;
    final resolvedCancel = cancelLabel ?? l10n.cancelRide;

    return RawanaSurfaceCard(
      padding: EdgeInsets.zero,
      borderRadius: const BorderRadius.all(Radius.circular(RawanaSpacing.radiusXl)),
      shadows: RawanaShadows.sheet,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RawanaSheetHandle(),
          _StatusHeader(
            label: statusLabel,
            color: statusColor,
            icon: statusIcon,
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.58,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                if (etaMinutes != null || distanceKm != null)
                  _EtaRow(
                    etaMinutes: etaMinutes,
                    distanceKm: distanceKm,
                  ),
                if (etaMinutes != null || distanceKm != null)
                  const SizedBox(height: 16),
                if (_hasParty) ...[
                  _PartyRow(
                    name: partyName!,
                    subtitle: partySubtitle,
                    plateNumber: plateNumber,
                    vehicleColour: vehicleColour,
                    profilePhotoUrl: profilePhotoUrl,
                    partyPhone: partyPhone,
                    rating: rating,
                    onPhoneTap: onCall,
                  ),
                  if ((onCall != null && partyPhone == null) ||
                      onMessage != null ||
                      onShare != null) ...[
                    const SizedBox(height: 12),
                    _QuickActions(
                      onCall: onCall,
                      callLabel: resolvedCall,
                      onMessage: onMessage,
                      messageLabel: resolvedMessage,
                      onShare: onShare,
                      shareLabel: resolvedShare,
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: RawanaColors.divider),
                  const SizedBox(height: 14),
                ],
                TripRouteAddresses(
                  pickupAddress: pickupAddress,
                  dropoffAddress: dropoffAddress,
                  currentLabel: currentLabel,
                  dense: true,
                ),
                if (hintText != null) ...[
                  const SizedBox(height: 10),
                  _HintBanner(text: hintText!),
                ],
                if (fareFormatted != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        fareLabel ?? l10n.cashFare,
                        style: const TextStyle(
                          color: RawanaColors.onSurfaceMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        fareFormatted!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ],
                if (onNavigate != null) ...[
                  const SizedBox(height: 16),
                  _NavigateButton(
                    label: resolvedNavigate,
                    onPressed: onNavigate!,
                  ),
                ],
                if (onOpenExternalMaps != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: onOpenExternalMaps,
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: Text(
                      openExternalMapsLabel ?? l10n.openInGoogleMaps,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: RawanaColors.primary,
                      side: const BorderSide(color: RawanaColors.primary),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
                if (primaryAction != null) ...[
                  const SizedBox(height: 14),
                  primaryAction!,
                ],
                if (onCancel != null) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: cancelLoading ? null : onCancel,
                    icon: cancelLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: RawanaColors.error,
                          ),
                    label: Text(
                      resolvedCancel,
                      style: const TextStyle(color: RawanaColors.error),
                    ),
                  ),
                ],
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.88)],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(RawanaSpacing.radiusXl),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EtaRow extends StatelessWidget {
  const _EtaRow({this.etaMinutes, this.distanceKm});

  final int? etaMinutes;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (etaMinutes != null)
          Text(
            '$etaMinutes',
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -1.5,
              color: RawanaColors.onSurface,
            ),
          ),
        if (etaMinutes != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              context.l10n.minutesShort,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: RawanaColors.onSurfaceMuted,
              ),
            ),
          ),
        const Spacer(),
        if (distanceKm != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                context.l10n.distanceKm(distanceKm!.toStringAsFixed(1)),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: RawanaColors.onSurface,
                ),
              ),
              Text(
                context.l10n.routeDistance,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: RawanaColors.onSurfaceMuted,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _PartyRow extends StatelessWidget {
  const _PartyRow({
    required this.name,
    this.subtitle,
    this.plateNumber,
    this.vehicleColour,
    this.profilePhotoUrl,
    this.partyPhone,
    this.rating,
    this.onPhoneTap,
  });

  final String name;
  final String? subtitle;
  final String? plateNumber;
  final String? vehicleColour;
  final String? profilePhotoUrl;
  final String? partyPhone;
  final double? rating;
  final VoidCallback? onPhoneTap;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join()
        : '?';
    final hasPhoto =
        profilePhotoUrl != null && profilePhotoUrl!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasPhoto ? null : RawanaColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: RawanaColors.primary.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  image: hasPhoto
                      ? DecorationImage(
                          image: NetworkImage(profilePhotoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: hasPhoto
                    ? null
                    : Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: RawanaColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: RawanaColors.onSurfaceMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (vehicleColour != null && vehicleColour!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      vehicleColour!,
                      style: const TextStyle(
                        color: RawanaColors.onSurfaceMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: RawanaColors.accent,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: RawanaColors.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (plateNumber != null && plateNumber!.isNotEmpty)
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: RawanaColors.surfaceAlt,
                    borderRadius:
                        BorderRadius.circular(RawanaSpacing.radiusSm),
                    border: Border.all(color: RawanaColors.divider),
                  ),
                  child: Text(
                    plateNumber!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (partyPhone != null && partyPhone!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Material(
            color: RawanaColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
            child: InkWell(
              onTap: onPhoneTap,
              borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone_rounded,
                      size: 18,
                      color: RawanaColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.whatsApp,
                            style: const TextStyle(
                              color: RawanaColors.onSurfaceMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            partyPhone!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: RawanaColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: RawanaColors.onSurfaceMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    this.onCall,
    required this.callLabel,
    this.onMessage,
    required this.messageLabel,
    this.onShare,
    required this.shareLabel,
  });

  final VoidCallback? onCall;
  final String callLabel;
  final VoidCallback? onMessage;
  final String messageLabel;
  final VoidCallback? onShare;
  final String shareLabel;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];
    if (onCall != null) {
      actions.add(
        Expanded(
          child: _QuickActionTile(
            icon: Icons.phone_rounded,
            label: callLabel,
            onPressed: onCall!,
            filled: true,
          ),
        ),
      );
    }
    if (onMessage != null) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 10));
      actions.add(
        Expanded(
          child: _QuickActionTile(
            icon: Icons.chat_bubble_outline_rounded,
            label: messageLabel,
            onPressed: onMessage!,
            filled: true,
          ),
        ),
      );
    }
    if (onShare != null) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 10));
      actions.add(
        Expanded(
          child: _QuickActionTile(
            icon: Icons.share_rounded,
            label: shareLabel,
            onPressed: onShare!,
          ),
        ),
      );
    }
    return Row(children: actions);
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(RawanaSpacing.radiusMd);
    return Material(
      color: filled
          ? RawanaColors.primary.withValues(alpha: 0.08)
          : RawanaColors.surfaceAlt,
      borderRadius: radius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: filled ? RawanaColors.primary : RawanaColors.onSurface,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: filled
                          ? RawanaColors.primary
                          : RawanaColors.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigateButton extends StatelessWidget {
  const _NavigateButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RawanaColors.primary,
      borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.navigation_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintBanner extends StatelessWidget {
  const _HintBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: RawanaColors.successSoft,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
        border: Border.all(color: RawanaColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_rounded, color: RawanaColors.success, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: RawanaColors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats trip fare for display in [TripInfoSheet].
String formatTripFare(int? amount, {String currency = 'AFN'}) {
  if (amount == null) return '';
  if (currency == 'AFN') return AfnFormatter.format(amount);
  return '$currency $amount';
}
