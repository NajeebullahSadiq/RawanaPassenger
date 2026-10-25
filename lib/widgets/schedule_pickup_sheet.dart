import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';

/// Result of the pickup-time sheet. [at] is null when the passenger picked "Now".
class PickupTimeChoice {
  const PickupTimeChoice(this.at);
  final DateTime? at;
}

/// Uber-style "Now / Later" pickup-time picker. Returns null when dismissed.
Future<PickupTimeChoice?> showPickupTimeSheet(
  BuildContext context, {
  DateTime? initial,
  int maxDaysAhead = 30,
}) {
  return showModalBottomSheet<PickupTimeChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(RawanaSpacing.radiusXl)),
    ),
    builder: (_) => _PickupTimeSheet(initial: initial, maxDaysAhead: maxDaysAhead),
  );
}

class _PickupTimeSheet extends StatefulWidget {
  const _PickupTimeSheet({this.initial, required this.maxDaysAhead});

  final DateTime? initial;
  final int maxDaysAhead;

  @override
  State<_PickupTimeSheet> createState() => _PickupTimeSheetState();
}

class _PickupTimeSheetState extends State<_PickupTimeSheet> {
  late final DateTime _earliest = earliestScheduledPickup();
  late DateTime _selected =
      widget.initial != null && widget.initial!.isAfter(_earliest) ? widget.initial! : _earliest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RawanaSheetHandle(),
            Text(
              l10n.choosePickupTime,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4),
            ),
            const SizedBox(height: 6),
            Text(
              formatScheduledTime(context, _selected),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: RawanaColors.primary,
              ),
            ),
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                minuteInterval: 5,
                initialDateTime: _selected,
                minimumDate: _earliest,
                maximumDate: _earliest.add(Duration(days: widget.maxDaysAhead)),
                use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
                onDateTimeChanged: (value) => setState(() => _selected = value),
              ),
            ),
            Row(
              children: [
                const Icon(LucideIcons.lock, size: 14, color: RawanaColors.onSurfaceMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.priceLockedNote,
                    style: const TextStyle(
                      color: RawanaColors.onSurfaceMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, const PickupTimeChoice(null)),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: Text(l10n.pickupNow),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: RawanaPrimaryButton(
                    label: l10n.confirm,
                    icon: LucideIcons.calendarCheck,
                    onPressed: () => Navigator.pop(context, PickupTimeChoice(_selected)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
