import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/rawana_theme.dart';
import '../rawana_gradient_button.dart';
import 'rawana_map_sheet.dart';

/// One choice in [RawanaActionSheet.choose].
class RawanaSheetOption<T> {
  const RawanaSheetOption({required this.value, required this.label, this.icon, this.subtitle});

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
}

/// Bottom-sheet replacement for `AlertDialog`: confirmations, info notices and
/// reason pickers all slide up from the bottom with large tap targets.
class RawanaActionSheet {
  RawanaActionSheet._();

  static Future<T?> _show<T>(BuildContext context, Widget child, {bool dismissible = true}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: RawanaSheetPanel(child: child),
      ),
    );
  }

  /// Yes / no question. Resolves to `true` only when confirmed.
  /// Any content in the standard sheet panel (forms, menus).
  static Future<T?> custom<T>(BuildContext context, Widget child, {bool dismissible = true}) => _show<T>(
        context,
        Flexible(child: SingleChildScrollView(padding: const EdgeInsets.only(top: 8), child: child)),
        dismissible: dismissible,
      );

  /// Tap-to-pick list of actions; resolves to the tapped value or `null`.
  static Future<T?> menu<T>(
    BuildContext context, {
    required String title,
    required List<RawanaSheetOption<T>> options,
  }) {
    return _show<T>(
      context,
      Builder(
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: ctx.text.headline),
            const SizedBox(height: 12),
            for (final o in options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: o.icon == null ? null : Icon(o.icon, color: RawanaColors.primary),
                title: Text(o.label, style: ctx.text.bodyStrong),
                subtitle: o.subtitle == null ? null : Text(o.subtitle!, style: ctx.text.caption),
                onTap: () => Navigator.of(ctx).pop(o.value),
              ),
          ],
        ),
      ),
    );
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? message,
    required String confirmLabel,
    required String cancelLabel,
    bool destructive = false,
    IconData? icon,
  }) async {
    final result = await _show<bool>(
      context,
      Builder(
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(
              title: title,
              message: message,
              icon: icon,
              tone: destructive ? RawanaColors.error : RawanaColors.primary,
            ),
            const SizedBox(height: 20),
            RawanaGradientButton(
              label: confirmLabel,
              gradient: destructive
                  ? const LinearGradient(colors: [RawanaColors.error, RawanaColors.error])
                  : null,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: 8),
            _SecondaryButton(label: cancelLabel, onPressed: () => Navigator.of(ctx).pop(false)),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  /// Notice with a single acknowledge button.
  static Future<void> info(
    BuildContext context, {
    required String title,
    String? message,
    required String actionLabel,
    IconData? icon,
    Color tone = RawanaColors.primary,
    bool dismissible = true,
  }) async {
    await _show<void>(
      context,
      Builder(
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(title: title, message: message, icon: icon, tone: tone),
            const SizedBox(height: 20),
            RawanaGradientButton(label: actionLabel, onPressed: () => Navigator.of(ctx).pop()),
          ],
        ),
      ),
      dismissible: dismissible,
    );
  }

  /// Pick one option from large tiles, then confirm. Resolves to `null`
  /// when dismissed.
  static Future<T?> choose<T>(
    BuildContext context, {
    required String title,
    String? message,
    required List<RawanaSheetOption<T>> options,
    required String confirmLabel,
    required String cancelLabel,
    bool destructive = false,
    T? initial,
  }) {
    return _show<T>(
      context,
      _ChooseBody<T>(
        title: title,
        message: message,
        options: options,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
        initial: initial,
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, this.message, this.icon, required this.tone});

  final String title;
  final String? message;
  final IconData? icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: tone, size: 26),
          ),
          const SizedBox(height: 14),
        ],
        Text(title, style: text.headline),
        if (message != null && message!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(message!, style: text.body.copyWith(color: RawanaColors.onSurfaceMuted)),
        ],
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: RawanaSpacing.buttonHeight,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: RawanaColors.onSurface,
          backgroundColor: RawanaColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
          ),
        ),
        child: Text(label, style: context.text.subtitle),
      ),
    );
  }
}

class _ChooseBody<T> extends StatefulWidget {
  const _ChooseBody({
    required this.title,
    this.message,
    required this.options,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
    this.initial,
  });

  final String title;
  final String? message;
  final List<RawanaSheetOption<T>> options;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final T? initial;

  @override
  State<_ChooseBody<T>> createState() => _ChooseBodyState<T>();
}

class _ChooseBodyState<T> extends State<_ChooseBody<T>> {
  late T? _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    final tone = widget.destructive ? RawanaColors.error : RawanaColors.primary;
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.5;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetHeader(title: widget.title, message: widget.message, tone: tone),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxListHeight),
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final o in widget.options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _OptionTile(
                      label: o.label,
                      subtitle: o.subtitle,
                      icon: o.icon,
                      selected: o.value == _selected,
                      tone: tone,
                      onTap: () => setState(() => _selected = o.value),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        RawanaGradientButton(
          label: widget.confirmLabel,
          gradient: widget.destructive
              ? const LinearGradient(colors: [RawanaColors.error, RawanaColors.error])
              : null,
          onPressed: _selected == null ? null : () => Navigator.of(context).pop(_selected),
        ),
        const SizedBox(height: 8),
        _SecondaryButton(label: widget.cancelLabel, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    this.subtitle,
    this.icon,
    required this.selected,
    required this.tone,
    required this.onTap,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(RawanaSpacing.radiusMd);
    return Material(
      color: selected ? tone.withValues(alpha: 0.06) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: selected ? tone : RawanaColors.divider, width: selected ? 2 : 1.4),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 22, color: selected ? tone : RawanaColors.onSurfaceMuted),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: context.text.subtitle),
                      if (subtitle != null) Text(subtitle!, style: context.text.caption),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: RawanaMotion.fast,
                  child: selected
                      ? Icon(LucideIcons.circleCheck, key: const ValueKey(true), color: tone)
                      : const Icon(LucideIcons.circle, key: ValueKey(false), color: RawanaColors.outline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
