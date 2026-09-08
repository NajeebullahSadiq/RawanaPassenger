import 'package:flutter/material.dart';
import '../theme/rawana_theme.dart';

/// Uppercase section header used above grouped lists, e.g. "PREFERENCES".
class RawanaSectionLabel extends StatelessWidget {
  const RawanaSectionLabel(this.label, {super.key, this.padding});

  final String label;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: RawanaColors.onSurfaceMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
