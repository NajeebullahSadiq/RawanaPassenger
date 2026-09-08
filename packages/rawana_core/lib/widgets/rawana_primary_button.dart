import 'package:flutter/material.dart';
import '../theme/rawana_theme.dart';
import 'rawana_gradient_button.dart';

/// Project-wide primary CTA. Re-implemented on top of
/// [RawanaGradientButton] so every "primary" action across both apps now
/// uses the same elevated gradient pill.
class RawanaPrimaryButton extends StatelessWidget {
  const RawanaPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: RawanaSpacing.buttonHeight,
      child: RawanaGradientButton(
        label: label,
        loading: loading,
        onPressed: onPressed,
        icon: icon,
      ),
    );
  }
}
