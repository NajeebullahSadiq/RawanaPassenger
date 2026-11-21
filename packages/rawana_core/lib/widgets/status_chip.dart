import 'package:flutter/material.dart';
import '../theme/rawana_theme.dart';
import 'ui/status_pill.dart';

/// Kept for existing call sites; renders the same pill as [StatusPill].
class StatusChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const StatusChip({super.key, required this.label, this.color, this.icon});

  @override
  Widget build(BuildContext context) =>
      StatusPill(label: label, color: color ?? RawanaColors.primary, icon: icon);
}
