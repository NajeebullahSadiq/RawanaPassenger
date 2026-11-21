import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/rawana_theme.dart';

/// Swipe-to-confirm control for actions that must not be triggered by an
/// accidental tap while driving (Arrived, Start trip, Complete, Cash collected).
///
/// Slides toward the end edge, so it mirrors automatically in RTL. When
/// [onConfirmed] completes (or throws) the thumb returns to the start; the
/// parent normally swaps the label for the next step.
class RawanaSlideToConfirm extends StatefulWidget {
  const RawanaSlideToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.gradient = RawanaColors.primaryGradient,
    this.icon = LucideIcons.chevronsRight,
    this.height = RawanaSpacing.driveTarget,
  });

  final String label;

  /// Null disables the control.
  final Future<void> Function()? onConfirmed;
  final Gradient gradient;
  final IconData icon;
  final double height;

  @override
  State<RawanaSlideToConfirm> createState() => _RawanaSlideToConfirmState();
}

class _RawanaSlideToConfirmState extends State<RawanaSlideToConfirm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: RawanaMotion.medium,
  );
  bool _busy = false;
  double _travel = 1;

  bool get _enabled => widget.onConfirmed != null && !_busy;

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails _) {
    if (_enabled) HapticFeedback.selectionClick();
  }

  void _onDragUpdate(DragUpdateDetails d, bool rtl) {
    if (!_enabled) return;
    final dx = (d.primaryDelta ?? 0) * (rtl ? -1 : 1);
    _progress.value = (_progress.value + dx / _travel).clamp(0.0, 1.0);
  }

  Future<void> _onDragEnd(DragEndDetails _) async {
    if (!_enabled) return;
    if (_progress.value < 0.82) {
      await _progress.animateTo(0, curve: RawanaMotion.curve);
      return;
    }
    await _confirm();
  }

  Future<void> _confirm() async {
    final action = widget.onConfirmed;
    if (action == null || _busy) return;
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    await _progress.animateTo(1, duration: RawanaMotion.fast);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _progress.animateTo(0, curve: RawanaMotion.curve);
      }
    }
  }

  Future<void> _nudge() async {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
    await _progress.animateTo(0.18, duration: RawanaMotion.fast, curve: Curves.easeOut);
    await _progress.animateTo(0, duration: RawanaMotion.medium, curve: Curves.elasticOut);
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final h = widget.height;
    const inset = 5.0;
    final thumb = h - inset * 2;
    final disabled = widget.onConfirmed == null;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.label,
      onTap: disabled ? null : _confirm,
      child: AnimatedOpacity(
        duration: RawanaMotion.fast,
        opacity: disabled ? 0.5 : 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _travel = (constraints.maxWidth - thumb - inset * 2).clamp(1.0, double.infinity);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _nudge,
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: (d) => _onDragUpdate(d, rtl),
              onHorizontalDragEnd: _onDragEnd,
              child: AnimatedBuilder(
                animation: _progress,
                builder: (context, _) {
                  final p = _progress.value;
                  return Container(
                    height: h,
                    decoration: BoxDecoration(
                      gradient: widget.gradient,
                      borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
                      boxShadow: disabled ? null : RawanaShadows.ctaGlow,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.only(start: thumb + inset * 2, end: 16),
                          child: Opacity(
                            opacity: (1 - p * 1.6).clamp(0.0, 1.0),
                            child: Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: context.text.button.copyWith(fontSize: 17),
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          start: inset + p * _travel,
                          top: inset,
                          child: Container(
                            width: thumb,
                            height: thumb,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: _busy
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(strokeWidth: 2.4),
                                  )
                                : Transform.flip(
                                    flipX: rtl,
                                    child: Icon(
                                      widget.icon,
                                      size: 26,
                                      color: RawanaColors.primaryDeep,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
