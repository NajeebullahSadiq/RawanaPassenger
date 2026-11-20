import 'package:flutter/material.dart';

import '../../theme/rawana_theme.dart';
import 'rawana_icons.dart';

/// Grouped white card of [RawanaSettingsTile]s with an optional heading.
class RawanaSettingsSection extends StatelessWidget {
  const RawanaSettingsSection({super.key, this.title, required this.children, this.footer});

  final String? title;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 8),
            child: Text(title!, style: context.text.label.copyWith(color: RawanaColors.onSurfaceMuted)),
          ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
            border: Border.all(color: RawanaColors.divider),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 66),
                children[i],
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 4, 0),
            child: Text(footer!, style: context.text.caption),
          ),
      ],
    );
  }
}

/// A settings / menu row: tinted icon, title, optional subtitle and value.
class RawanaSettingsTile extends StatelessWidget {
  const RawanaSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.iconColor,
    this.showChevron,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Short current value shown before the chevron (e.g. "English").
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final Color? iconColor;

  /// Defaults to true when the tile is tappable and has no [trailing].
  final bool? showChevron;

  @override
  Widget build(BuildContext context) {
    final tone = destructive ? RawanaColors.error : (iconColor ?? RawanaColors.primary);
    final chevron = showChevron ?? (onTap != null && trailing == null);
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(RawanaSpacing.radiusSm),
                  ),
                  child: Icon(icon, size: 18, color: tone),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: context.text.bodyStrong.copyWith(color: destructive ? RawanaColors.error : null),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: context.text.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(width: 8),
                  Text(value!, style: context.text.caption),
                ],
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                if (chevron) ...[
                  const SizedBox(width: 4),
                  const Icon(RawanaIcons.chevronForward, size: 18, color: RawanaColors.onSurfaceFaint),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
