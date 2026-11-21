import 'package:flutter/material.dart';

import '../../theme/rawana_theme.dart';

/// Compact pill for live status ("Finding trips", "Arriving in 3 min").
/// [pulse] adds a breathing dot for states that are actively changing.
class StatusPill extends StatefulWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.color = RawanaColors.primary,
    this.icon,
    this.pulse = false,
    this.filled = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool pulse;

  /// Solid background with white text, for pills floating over the map.
  final bool filled;

  @override
  State<StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<StatusPill> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(StatusPill old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_ctrl.isAnimating) _ctrl.repeat(reverse: true);
    if (!widget.pulse && _ctrl.isAnimating) _ctrl.stop();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.filled ? Colors.white : widget.color;
    final bg = widget.filled ? widget.color : widget.color.withValues(alpha: 0.1);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 7, 14, 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
        boxShadow: widget.filled ? RawanaShadows.low : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.pulse)
            FadeTransition(
              opacity: Tween(begin: 0.35, end: 1.0).animate(_ctrl),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
              ),
            )
          else if (widget.icon != null)
            Icon(widget.icon, size: 15, color: fg),
          if (widget.pulse || widget.icon != null) const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.label.copyWith(color: fg, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
