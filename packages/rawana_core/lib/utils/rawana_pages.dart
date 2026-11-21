import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/rawana_theme.dart';

/// Fade-through transition for go_router routes: the new page fades in while
/// scaling up slightly, instead of the default horizontal slide.
CustomTransitionPage<T> fadeThroughPage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: RawanaMotion.medium,
    reverseTransitionDuration: RawanaMotion.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: RawanaMotion.curve);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.97, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Rises from the bottom, for full-screen pages that continue a sheet
/// (destination search, chat, receipts).
CustomTransitionPage<T> sheetUpPage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: RawanaMotion.medium,
    reverseTransitionDuration: RawanaMotion.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: RawanaMotion.curve);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Shows [child] (usually a Scaffold such as the trip chat) as a tall sheet
/// over the current screen so the map stays in place underneath.
Future<T?> showTallSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => FractionallySizedBox(
      heightFactor: 0.94,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(RawanaSpacing.radiusLg)),
        child: child,
      ),
    ),
  );
}
