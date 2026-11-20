import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/rawana_theme.dart';

/// Bottom sheet that floats over a full-screen map and snaps between sizes,
/// the way Uber / Careem booking sheets do.
///
/// [onSettledHeight] reports the sheet height in logical pixels once a drag
/// settles (debounced), capped at [maxPaddingFraction] of the available
/// height, so the parent can use it as map padding without the camera
/// following every frame.
class RawanaMapSheet extends StatefulWidget {
  const RawanaMapSheet({
    super.key,
    required this.child,
    this.snapSizes = const [0.32, 0.6],
    this.initialSize,
    this.controller,
    this.onSettledHeight,
    this.maxPaddingFraction = 0.55,
    this.footer,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 12),
  });

  final Widget child;

  /// Fractions of the available height the sheet snaps to (ascending).
  /// The first value is the minimum, the last value the maximum.
  final List<double> snapSizes;
  final double? initialSize;
  final DraggableScrollableController? controller;
  final ValueChanged<double>? onSettledHeight;
  final double maxPaddingFraction;

  /// Pinned below the scrollable body; stays visible at every snap size.
  final Widget? footer;
  final EdgeInsetsGeometry padding;

  @override
  State<RawanaMapSheet> createState() => _RawanaMapSheetState();
}

class _RawanaMapSheetState extends State<RawanaMapSheet> {
  Timer? _settle;
  double _lastReported = -1;
  double _fullHeight = 0;

  double get _min => widget.snapSizes.first;
  double get _max => widget.snapSizes.last;
  double get _initial => (widget.initialSize ?? _min).clamp(_min, _max);

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  void _report(double extent) {
    final cb = widget.onSettledHeight;
    if (cb == null || _fullHeight <= 0) return;
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 140), () {
      if (!mounted) return;
      final capped = extent.clamp(0.0, widget.maxPaddingFraction) * _fullHeight;
      if ((capped - _lastReported).abs() < 2) return;
      _lastReported = capped;
      cb(capped);
    });
  }

  @override
  Widget build(BuildContext context) {
    final inner = [
      for (final s in widget.snapSizes)
        if (s > _min && s < _max) s,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final first = _fullHeight <= 0;
        _fullHeight = constraints.maxHeight;
        if (first) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _report(_initial));
        }
        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (n) {
            _report(n.extent);
            return false;
          },
          child: DraggableScrollableSheet(
            controller: widget.controller,
            initialChildSize: _initial,
            minChildSize: _min,
            maxChildSize: _max,
            snap: widget.snapSizes.length > 1,
            snapSizes: inner.isEmpty ? null : inner,
            snapAnimationDuration: RawanaMotion.medium,
            builder: (context, scrollController) {
              return _SheetSurface(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        child: Padding(
                          padding: widget.padding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const RawanaGrabber(),
                              widget.child,
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (widget.footer != null)
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          child: widget.footer,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SheetSurface extends StatelessWidget {
  const _SheetSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(top: Radius.circular(RawanaSpacing.radiusLg));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: RawanaShadows.sheet,
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}

/// 36x4 drag handle (DESIGN.md "Grabber").
class RawanaGrabber extends StatelessWidget {
  const RawanaGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 12),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: RawanaColors.outline,
          borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
        ),
      ),
    );
  }
}

/// Fixed (non-draggable) panel with the same look as [RawanaMapSheet].
/// Used where the content must always be fully visible, e.g. driving actions.
/// Reports its height through [onHeight] for map padding.
class RawanaSheetPanel extends StatelessWidget {
  const RawanaSheetPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 12),
    this.showGrabber = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showGrabber;

  @override
  Widget build(BuildContext context) {
    return _SheetSurface(
      child: Material(
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showGrabber) const RawanaGrabber() else const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
