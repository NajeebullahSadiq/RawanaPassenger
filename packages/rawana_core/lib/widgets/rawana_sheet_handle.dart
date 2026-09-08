import 'package:flutter/material.dart';
import '../theme/rawana_theme.dart';

/// Drag-handle for bottom sheets and pull-up panels.
class RawanaSheetHandle extends StatelessWidget {
  const RawanaSheetHandle({super.key, this.padding = const EdgeInsets.only(top: 12, bottom: 8)});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: RawanaColors.divider,
            borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
          ),
        ),
      ),
    );
  }
}
