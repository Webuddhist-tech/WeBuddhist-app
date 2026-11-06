/// How a calendar event repeats, as the Personal Calendar API sends it.
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

/// An all-day event the user added to their own calendar.
class PersonalCalendarEvent {
  final String id;
  final String title;
  final DateTime startDate;

  const PersonalCalendarEvent({
    required this.id,
    required this.title,
    required this.startDate,
  });
}
