import 'package:flutter/material.dart';

import '../../theme/rawana_theme.dart';

/// Pulsing placeholder block shown while content loads, instead of a spinner.
class RawanaSkeleton extends StatefulWidget {
  const RawanaSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = RawanaSpacing.radiusSm,
    this.circle = false,
  });

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  State<RawanaSkeleton> createState() => _RawanaSkeletonState();
}

class _RawanaSkeletonState extends State<RawanaSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_pulse),
      child: Container(
        width: widget.circle ? widget.height : widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: RawanaColors.surfaceAlt,
          shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: widget.circle ? null : BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Page-level loading placeholder: a column of skeleton rows.
class RawanaSkeletonList extends StatelessWidget {
  const RawanaSkeletonList({
    super.key,
    this.count = 6,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 16),
    this.trailing = true,
  });

  final int count;
  final EdgeInsetsGeometry padding;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, _) => RawanaSkeletonRow(trailing: trailing),
    );
  }
}

/// Skeleton for a list row: leading circle, two text lines, optional trailing.
class RawanaSkeletonRow extends StatelessWidget {
  const RawanaSkeletonRow({super.key, this.leadingSize = 44, this.trailing = false});

  final double leadingSize;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          RawanaSkeleton(height: leadingSize, circle: true),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RawanaSkeleton(width: 140, height: 14),
                SizedBox(height: 8),
                RawanaSkeleton(width: 90, height: 11),
              ],
            ),
          ),
          if (trailing) const RawanaSkeleton(width: 56, height: 16),
        ],
      ),
    );
  }
}
