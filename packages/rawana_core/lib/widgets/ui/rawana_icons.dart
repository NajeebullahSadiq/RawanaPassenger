import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Icons that point "back" or "forward" and must mirror in Dari and Pashto.
/// Lucide's `...Dir` variants set `matchTextDirection`.
abstract final class RawanaIcons {
  static const IconData back = LucideIcons.arrowLeftDir;
  static const IconData forward = LucideIcons.arrowRightDir;
  static const IconData chevronForward = LucideIcons.chevronRightDir;
  static const IconData chevronBack = LucideIcons.chevronLeftDir;
}
