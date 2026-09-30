import 'package:intl/intl.dart';

/// Formats an event time in [locale]'s own clock, dropping on-the-hour minutes
/// only where the clock has a day period: "3 pm", "下午3", but "15:00" rather
/// than a bare "15" that reads as a count.
///
/// Edits the locale's pattern rather than the formatted string, so only the
/// minutes field goes and native digits (०, ༠) are never pattern-matched.
String formatGroupEventTime(DateTime value, String locale) {
  final pattern = DateFormat.jm(locale).pattern!;
  final literalsRemoved = pattern.replaceAll(RegExp(r"'[^']*'"), '');
  final hasDayPeriod = literalsRemoved.contains('a');
  final format =
      hasDayPeriod && value.minute == 0
          ? DateFormat(pattern.replaceFirst(RegExp(r'[:.]mm'), ''), locale)
          : DateFormat(pattern, locale);
  return format.format(value).toLowerCase();
}
