import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/rawana_theme.dart';
import '../rawana_circle_icon_button.dart';
import 'rawana_icons.dart';

/// Standard top bar: directional back button, start-aligned title.
/// The back button only shows when there is somewhere to go back to.
class RawanaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const RawanaAppBar({
    super.key,
    this.title,
    this.actions,
    this.onBack,
    this.showBack = true,
    this.backgroundColor = RawanaColors.surface,
    this.bottom,
  });

  final String? title;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool showBack;
  final Color backgroundColor;
  final PreferredSizeWidget? bottom;

  static const double _toolbarHeight = 64;

  @override
  Size get preferredSize => Size.fromHeight(_toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final canPop = GoRouter.maybeOf(context)?.canPop() ?? Navigator.canPop(context);
    final back = showBack && (onBack != null || canPop);
    return AppBar(
      backgroundColor: backgroundColor,
      toolbarHeight: _toolbarHeight,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: back ? 4 : RawanaSpacing.lg,
      leadingWidth: 68,
      leading: back
          ? Padding(
              padding: const EdgeInsetsDirectional.only(start: 16),
              child: Center(
                child: RawanaCircleIconButton(
                  icon: RawanaIcons.back,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  elevated: false,
                  background: Colors.white,
                  onPressed: onBack ?? () => Navigator.maybePop(context),
                ),
              ),
            )
          : null,
      title: title == null
          ? null
          : Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.headline),
      actions: [...?actions, const SizedBox(width: 12)],
      bottom: bottom,
    );
  }
}

/// Page shell for every non-map screen: surface background, [RawanaAppBar]
/// and an optional pinned bottom action.
class RawanaScaffold extends StatelessWidget {
  const RawanaScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.onBack,
    this.showBack = true,
    this.showAppBar = true,
    this.bottomBar,
    this.floatingActionButton,
    this.appBarBottom,
    this.backgroundColor = RawanaColors.surface,
  });

  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool showBack;
  final bool showAppBar;

  /// Pinned under the body (e.g. the primary button of a form).
  final Widget? bottomBar;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBarBottom;
  final Color backgroundColor;

  /// Default padding for scrolling page content.
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(16, 8, 16, 32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: showAppBar
          ? RawanaAppBar(
              title: title,
              actions: actions,
              onBack: onBack,
              showBack: showBack,
              backgroundColor: backgroundColor,
              bottom: appBarBottom,
            )
          : null,
      body: showAppBar ? body : SafeArea(bottom: false, child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomBar == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: bottomBar),
            ),
    );
  }
}

/// Large page heading used by sign-in, onboarding and form screens.
class RawanaPageHeader extends StatelessWidget {
  const RawanaPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor = RawanaColors.primary,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 20),
        ],
        Text(title, style: context.text.display),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: context.text.body.copyWith(color: RawanaColors.onSurfaceMuted)),
        ],
      ],
    );
  }
}
