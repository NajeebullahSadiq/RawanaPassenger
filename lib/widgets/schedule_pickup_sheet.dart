import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';

/// Result of the pickup-time sheet. [at] is null when the passenger picked "Now".
class PickupTimeChoice {
  const PickupTimeChoice(this.at);
  final DateTime? at;
}

/// "Now / Later" pickup-time picker: day chips plus a Material time picker.
/// Returns null when dismissed.
Future<PickupTimeChoice?> showPickupTimeSheet(
  BuildContext context, {
  DateTime? initial,
  int maxDaysAhead = 30,
}) {
  return showModalBottomSheet<PickupTimeChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
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
  static const _chipDays = 7;

  late final DateTime _earliest = earliestScheduledPickup();
  late final DateTime _latest = _earliest.add(Duration(days: widget.maxDaysAhead));
  late DateTime _selected =
      widget.initial != null && widget.initial!.isAfter(_earliest) ? widget.initial! : _earliest;

  DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  /// Keeps the time of day when switching days, clamped to the allowed window.
  void _apply(DateTime day, TimeOfDay time) {
    var next = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    if (next.isBefore(_earliest)) next = _earliest;
    if (next.isAfter(_latest)) next = _latest;
    setState(() => _selected = next);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selected),
      helpText: context.l10n.pickTime,
    );
    if (picked == null || !mounted) return;
    final minute = (picked.minute / 5).round() * 5;
    _apply(
      _selected,
      minute == 60 ? TimeOfDay(hour: (picked.hour + 1) % 24, minute: 0) : TimeOfDay(hour: picked.hour, minute: minute),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day(_selected),
      firstDate: _day(_earliest),
      lastDate: _day(_latest),
    );
    if (picked == null || !mounted) return;
    _apply(picked, TimeOfDay.fromDateTime(_selected));
  }

  String _dayLabel(BuildContext context, DateTime day, int index) {
    final l10n = context.l10n;
    if (index == 0 && _day(DateTime.now()) == day) return l10n.todayLabel;
    if (_day(DateTime.now()).add(const Duration(days: 1)) == day) return l10n.tomorrowLabel;
    return intl.DateFormat.MMMEd(l10n.localeName).format(day);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final first = _day(_earliest);
    final days = [
      for (var i = 0; i < _chipDays; i++)
        if (!first.add(Duration(days: i)).isAfter(_day(_latest))) first.add(Duration(days: i)),
    ];
    final selectedDay = _day(_selected);
    final offChips = !days.contains(selectedDay);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RawanaGrabber(),
            Text(l10n.choosePickupTime, style: context.text.headline),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var i = 0; i < days.length; i++)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: _DayChip(
                        label: _dayLabel(context, days[i], i),
                        selected: days[i] == selectedDay,
                        onTap: () => _apply(days[i], TimeOfDay.fromDateTime(_selected)),
                      ),
                    ),
                  _DayChip(
                    label: offChips ? intl.DateFormat.MMMEd(l10n.localeName).format(selectedDay) : null,
                    icon: LucideIcons.calendar,
                    selected: offChips,
                    onTap: _pickDate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: RawanaColors.surfaceAlt,
              borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
              child: InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.clock, color: RawanaColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          TimeOfDay.fromDateTime(_selected).format(context),
                          style: context.text.display.copyWith(fontSize: 28),
                        ),
                      ),
                      Text(l10n.changeLabel, style: context.text.label.copyWith(color: RawanaColors.primary)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(formatScheduledTime(context, _selected), style: context.text.bodyStrong),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(LucideIcons.lock, size: 14, color: RawanaColors.onSurfaceMuted),
                const SizedBox(width: 6),
                Expanded(child: Text(l10n.priceLockedNote, style: context.text.caption)),
              ],
            ),
            const SizedBox(height: 18),
            RawanaPrimaryButton(
              label: l10n.confirm,
              icon: LucideIcons.calendarCheck,
              onPressed: () => Navigator.pop(context, PickupTimeChoice(_selected)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, const PickupTimeChoice(null)),
              style: TextButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              child: Text(l10n.pickupNow),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({this.label, this.icon, required this.selected, required this.onTap});

  final String? label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : RawanaColors.onSurface;
    return Material(
      color: selected ? RawanaColors.primary : RawanaColors.surfaceAlt,
      borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 16, color: fg),
              if (icon != null && label != null) const SizedBox(width: 6),
              if (label != null) Text(label!, style: context.text.label.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
