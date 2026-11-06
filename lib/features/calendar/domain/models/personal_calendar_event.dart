/// How a personal event repeats. Each option is worked out by the server from
/// the event's first date.
enum PersonalRepeat {
  none('NONE'),
  weekly('WEEKLY'),
  monthlyGregorian('MONTHLY_GREGORIAN'),
  monthlyLunar('MONTHLY_LUNAR'),
  yearlyGregorian('YEARLY_GREGORIAN'),
  yearlyLunar('YEARLY_LUNAR');

  const PersonalRepeat(this.apiValue);

  final String apiValue;

  /// Null for a value this app doesn't know, or none sent.
  static PersonalRepeat? fromApi(String? value) {
    for (final repeat in values) {
      if (repeat.apiValue == value) return repeat;
    }
    return null;
  }
}

/// An event the user added to their own calendar.
class PersonalCalendarEvent {
  final String id;
  final String title;

  /// The first date. Repeat options are always derived from it.
  final DateTime startDate;
  final PersonalRepeat repeat;

  /// The repeating day of the month, lunar or Gregorian; null otherwise.
  final int? day;

  const PersonalCalendarEvent({
    required this.id,
    required this.title,
    required this.startDate,
    this.repeat = PersonalRepeat.none,
    this.day,
  });

  bool get isRepeating => repeat != PersonalRepeat.none;
}

/// One choice in the Repeats sheet.
class PersonalRepeatOption {
  final PersonalRepeat repeat;
  final int? day;
  final int? month;

  /// 0 = Monday.
  final int? dayOfWeek;
  final List<DateTime> nextDates;

  const PersonalRepeatOption({
    required this.repeat,
    this.day,
    this.month,
    this.dayOfWeek,
    this.nextDates = const [],
  });

  static const noRepeat = PersonalRepeatOption(repeat: PersonalRepeat.none);
}
