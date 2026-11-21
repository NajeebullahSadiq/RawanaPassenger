import 'package:flutter/material.dart';

import '../../l10n/l10n_extensions.dart';
import '../../theme/rawana_theme.dart';
import 'rawana_error_state.dart';
import 'rawana_skeleton.dart';

/// One way to show loading, failure, empty and loaded content on a page.
///
/// [data] null with no [error] shows [skeleton]; null with an [error] shows a
/// retry. Data that [isEmpty] shows [empty]. Keeps showing stale [data] while
/// a refresh fails. With [onRefresh] every state supports pull-to-refresh, so
/// the [builder] should return a scrollable.
class RawanaAsyncBody<T> extends StatelessWidget {
  const RawanaAsyncBody({
    super.key,
    required this.data,
    required this.builder,
    this.error,
    this.isEmpty,
    this.empty,
    this.skeleton,
    this.onRetry,
    this.onRefresh,
    this.errorTitle,
  });

  final T? data;
  final Object? error;
  final Widget Function(BuildContext context, T data) builder;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final Widget? skeleton;
  final VoidCallback? onRetry;
  final Future<void> Function()? onRefresh;
  final String? errorTitle;

  @override
  Widget build(BuildContext context) {
    final value = data;
    final String stateKey;
    Widget child;
    if (value == null && error != null) {
      stateKey = 'error';
      child = _Fill(
        child: RawanaErrorState(
          title: errorTitle ?? context.l10n.somethingWentWrong,
          message: context.l10n.friendlyApiError(error!),
          retryLabel: context.l10n.tryAgain,
          onRetry: onRetry ?? (onRefresh == null ? null : () => onRefresh!()),
        ),
      );
    } else if (value == null) {
      stateKey = 'loading';
      child = skeleton ?? const RawanaSkeletonList();
    } else if (isEmpty?.call(value) ?? false) {
      stateKey = 'empty';
      child = _Fill(child: empty ?? const SizedBox.shrink());
    } else {
      stateKey = 'data';
      child = builder(context, value);
    }
    if (onRefresh != null && stateKey != 'loading') {
      child = RefreshIndicator(onRefresh: onRefresh!, color: RawanaColors.primary, child: child);
    }
    return AnimatedSwitcher(
      duration: RawanaMotion.fast,
      child: KeyedSubtree(key: ValueKey(stateKey), child: child),
    );
  }
}

/// Centers a non-scrolling state but keeps it scrollable for pull-to-refresh.
class _Fill extends StatelessWidget {
  const _Fill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}
