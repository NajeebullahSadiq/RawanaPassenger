import 'package:flutter/material.dart';
import '../theme/rawana_theme.dart';
import 'rawana_sheet_handle.dart';

class RawanaBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;

  const RawanaBottomSheet({super.key, required this.child, this.title});

  static Future<T?> show<T>(BuildContext context, {required Widget child, String? title}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(RawanaSpacing.radiusXl)),
      ),
      builder: (_) => RawanaBottomSheet(title: title, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RawanaSheetHandle(),
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: RawanaColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Flexible(child: child),
        ],
      ),
    );
  }
}
