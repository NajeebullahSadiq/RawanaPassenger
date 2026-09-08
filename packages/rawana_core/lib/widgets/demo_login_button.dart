import 'package:flutter/material.dart';
import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';

/// One-tap demo login for testing builds.
class DemoLoginButton extends StatelessWidget {
  const DemoLoginButton({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.label,
  });

  final VoidCallback? onPressed;
  final bool loading;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.bolt_rounded, color: RawanaColors.accentDeep),
      label: Text(loading ? context.l10n.signingIn : (label ?? context.l10n.quickDemoAccess)),
      style: OutlinedButton.styleFrom(
        backgroundColor: RawanaColors.accent.withValues(alpha: 0.12),
        foregroundColor: RawanaColors.onSurface,
        side: BorderSide.none,
        minimumSize: const Size(double.infinity, RawanaSpacing.buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd)),
      ),
    );
  }
}
