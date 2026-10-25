import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// "Fri, Oct 30 · 8:15 AM" in the app language, in the device's local time.
String formatScheduledTime(BuildContext context, DateTime time) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final local = time.toLocal();
  return '${DateFormat.MMMEd(locale).format(local)} · ${DateFormat.jm(locale).format(local)}';
}

/// Earliest selectable pickup for a scheduled ride, rounded up to [step] minutes.
DateTime earliestScheduledPickup({int leadMinutes = 30, int step = 5}) {
  final min = DateTime.now().add(Duration(minutes: leadMinutes + 1));
  final roundedMinute = ((min.minute + step - 1) ~/ step) * step;
  return DateTime(min.year, min.month, min.day, min.hour).add(Duration(minutes: roundedMinute));
}
