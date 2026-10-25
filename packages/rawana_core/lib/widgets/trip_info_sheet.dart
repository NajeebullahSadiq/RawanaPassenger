import 'package:flutter/material.dart';
import '../currency/afn_formatter.dart';
import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';
import 'rawana_sheet_handle.dart';
import 'rawana_surface_card.dart';
import 'trip_route_addresses.dart';

/// Uber/Ola-style bottom trip panel: status, ETA, party, route, navigate, actions.
///
/// Swipe down (or tap the header) to minimise it so the route on the map is
/// visible; swipe up to bring the details back.
class TripInfoSheet extends StatefulWidget {
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
    this.onChat,
    this.chatLabel,
    this.chatUnread = 0,
    this.onWhatsApp,
    this.whatsAppLabel,
    this.onShare,
    this.shareLabel,
    this.hintText,
    this.onCancel,
    this.cancelLoading = false,
    this.cancelLabel,
    this.initiallyExpanded = true,
    this.onExpandedChanged,
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

  /// Opens the in-app conversation with the other party.
  final VoidCallback? onChat;
  final String? chatLabel;
  final int chatUnread;

  /// Opens WhatsApp — kept separate from the in-app chat.
  final VoidCallback? onWhatsApp;
  final String? whatsAppLabel;
  final VoidCallback? onShare;
  final String? shareLabel;
  final String? hintText;
  final Widget? primaryAction;
  final VoidCallback? onCancel;
  final bool cancelLoading;
  final String? cancelLabel;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpandedChanged;

  @override
  State<TripInfoSheet> createState() => _TripInfoSheetState();
}

class _TripInfoSheetState extends State<TripInfoSheet> {
  late bool _expanded = widget.initiallyExpanded;
  double _dragDy = 0;

  bool get _hasParty =>
      widget.partyName != null && widget.partyName!.trim().isNotEmpty;

  void _setExpanded(bool expanded) {
    if (_expanded == expanded) return;
    setState(() => _expanded = expanded);
    widget.onExpandedChanged?.call(expanded);
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 250 || _dragDy > 36) {
      _setExpanded(false);
    } else if (velocity < -250 || _dragDy < -36) {
      _setExpanded(true);
    }
    _dragDy = 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return RawanaSurfaceCard(
      padding: EdgeInsets.zero,
      borderRadius: const BorderRadius.all(Radius.circular(RawanaSpacing.radiusXl)),
      shadows: RawanaShadows.sheet,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _setExpanded(!_expanded),
            onVerticalDragStart: (_) => _dragDy = 0,
            onVerticalDragUpdate: (d) => _dragDy += d.delta.dy,
            onVerticalDragEnd: _onDragEnd,
            child: Semantics(
              button: true,
              label: _expanded ? l10n.hideTripDetails : l10n.showTripDetails,
              child: Column(
                children: [
                  const RawanaSheetHandle(),
                  _StatusHeader(
                    label: widget.statusLabel,
                    color: widget.statusColor,
                    icon: widget.statusIcon,
                    expanded: _expanded,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded ? _buildExpanded(context) : _buildCollapsed(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsed(BuildContext context) {
    final l10n = context.l10n;
    final eta = widget.etaMinutes;
    final km = widget.distanceKm;
    final etaText = [
      if (eta != null) '$eta ${l10n.minutesShort}',
      if (km != null) l10n.distanceKm(km.toStringAsFixed(1)),
    ].join(' · ');
    final partyLine = [
      if (_hasParty) widget.partyName!.trim(),
      if (widget.plateNumber != null && widget.plateNumber!.isNotEmpty)
        widget.plateNumber!,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (etaText.isNotEmpty)
                      Text(
                        etaText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: -0.3,
                        ),
                      ),
                    if (partyLine.isNotEmpty)
                      Text(
                        partyLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: RawanaColors.onSurfaceMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.onChat != null)
                _CompactIconAction(
                  icon: Icons.chat_bubble_rounded,
                  tooltip: widget.chatLabel ?? l10n.chat,
                  badge: widget.chatUnread,
                  onPressed: widget.onChat!,
                ),
              if (widget.onCall != null)
                _CompactIconAction(
                  icon: Icons.phone_rounded,
                  tooltip: widget.callLabel ?? l10n.call,
                  onPressed: widget.onCall!,
                ),
            ],
          ),
          if (widget.primaryAction != null) ...[
            const SizedBox(height: 12),
            widget.primaryAction!,
          ],
        ],
      ),
    );
  }

  Widget _buildExpanded(BuildContext context) {
    final l10n = context.l10n;
    final resolvedNavigate = widget.navigateLabel ?? l10n.navigate;
    final resolvedCancel = widget.cancelLabel ?? l10n.cancelRide;
    final hasActions = widget.onCall != null ||
        widget.onChat != null ||
        widget.onWhatsApp != null ||
        widget.onShare != null;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.55,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.etaMinutes != null || widget.distanceKm != null) ...[
              _EtaRow(
                etaMinutes: widget.etaMinutes,
                distanceKm: widget.distanceKm,
              ),
              const SizedBox(height: 16),
            ],
            if (_hasParty) ...[
              _PartyRow(
                name: widget.partyName!,
                subtitle: widget.partySubtitle,
                plateNumber: widget.plateNumber,
                vehicleColour: widget.vehicleColour,
                profilePhotoUrl: widget.profilePhotoUrl,
                partyPhone: widget.partyPhone,
                rating: widget.rating,
                onPhoneTap: widget.onCall,
              ),
              if (hasActions) ...[
                const SizedBox(height: 12),
                _QuickActions(
                  onCall: widget.onCall,
                  callLabel: widget.callLabel ?? l10n.call,
                  onChat: widget.onChat,
                  chatLabel: widget.chatLabel ?? l10n.chat,
                  chatUnread: widget.chatUnread,
                  onWhatsApp: widget.onWhatsApp,
                  whatsAppLabel: widget.whatsAppLabel ?? l10n.whatsApp,
                  onShare: widget.onShare,
                  shareLabel: widget.shareLabel ?? l10n.shareTrip,
                ),
              ],
              const SizedBox(height: 16),
              const Divider(height: 1, color: RawanaColors.divider),
              const SizedBox(height: 14),
            ],
            TripRouteAddresses(
              pickupAddress: widget.pickupAddress,
              dropoffAddress: widget.dropoffAddress,
              currentLabel: widget.currentLabel,
              dense: true,
            ),
            if (widget.hintText != null && widget.hintText!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _HintBanner(text: widget.hintText!),
            ],
            if (widget.fareFormatted != null &&
                widget.fareFormatted!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    widget.fareLabel ?? l10n.cashFare,
                    style: const TextStyle(
                      color: RawanaColors.onSurfaceMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.fareFormatted!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ],
            if (widget.onNavigate != null) ...[
              const SizedBox(height: 16),
              _NavigateButton(
                label: resolvedNavigate,
                onPressed: widget.onNavigate!,
              ),
            ],
            if (widget.onOpenExternalMaps != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: widget.onOpenExternalMaps,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text(
                  widget.openExternalMapsLabel ?? l10n.openInGoogleMaps,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: RawanaColors.primary,
                  side: const BorderSide(color: RawanaColors.primary),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
            if (widget.primaryAction != null) ...[
              const SizedBox(height: 14),
              widget.primaryAction!,
            ],
            if (widget.onCancel != null) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: widget.cancelLoading ? null : widget.onCancel,
                icon: widget.cancelLoading
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
    );
  }
}

class _CompactIconAction extends StatelessWidget {
  const _CompactIconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8),
      child: _Badge(
        count: badge,
        child: IconButton.filledTonal(
          onPressed: onPressed,
          tooltip: tooltip,
          style: IconButton.styleFrom(
            backgroundColor: RawanaColors.primary.withValues(alpha: 0.10),
            foregroundColor: RawanaColors.primary,
          ),
          icon: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        PositionedDirectional(
          top: -2,
          end: -2,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: RawanaColors.error,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              count > 9 ? '9+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}



class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.label,
    required this.color,
    required this.icon,
    required this.expanded,
  });

  final String label;
  final Color color;
  final IconData icon;
  final bool expanded;

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
          AnimatedRotation(
            turns: expanded ? 0 : 0.5,
            duration: const Duration(milliseconds: 220),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 24,
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
    this.onChat,
    required this.chatLabel,
    this.chatUnread = 0,
    this.onWhatsApp,
    required this.whatsAppLabel,
    this.onShare,
    required this.shareLabel,
  });

  final VoidCallback? onCall;
  final String callLabel;
  final VoidCallback? onChat;
  final String chatLabel;
  final int chatUnread;
  final VoidCallback? onWhatsApp;
  final String whatsAppLabel;
  final VoidCallback? onShare;
  final String shareLabel;

  static const _whatsAppGreen = Color(0xFF128C4A);

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      if (onChat != null)
        _QuickActionTile(
          icon: Icons.chat_bubble_rounded,
          label: chatLabel,
          onPressed: onChat!,
          filled: true,
          badge: chatUnread,
        ),
      if (onCall != null)
        _QuickActionTile(
          icon: Icons.phone_rounded,
          label: callLabel,
          onPressed: onCall!,
          filled: true,
        ),
      if (onWhatsApp != null)
        _QuickActionTile(
          icon: Icons.chat_rounded,
          label: whatsAppLabel,
          onPressed: onWhatsApp!,
          color: _whatsAppGreen,
        ),
      if (onShare != null)
        _QuickActionTile(
          icon: Icons.share_rounded,
          label: shareLabel,
          onPressed: onShare!,
        ),
    ];
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.color,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final Color? color;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(RawanaSpacing.radiusMd);
    final accent = color ?? (filled ? RawanaColors.primary : RawanaColors.onSurface);
    final background = color != null
        ? color!.withValues(alpha: 0.10)
        : filled
            ? RawanaColors.primary.withValues(alpha: 0.08)
            : RawanaColors.surfaceAlt;
    return Material(
      color: background,
      borderRadius: radius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Badge(count: badge, child: Icon(icon, size: 20, color: accent)),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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
