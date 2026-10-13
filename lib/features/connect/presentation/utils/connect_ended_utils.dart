import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';

/// A card is finished only when the backend sent an [endDate] and that
/// instant has been reached. A missing end date leaves the card unchanged.
bool isPastEndDate(DateTime? endDate, DateTime now) {
  if (endDate == null) return false;
  return !now.isBefore(endDate);
}

/// Joined accumulations that can still take counts. A missing end date stays.
List<AccumulatorGroup> contributableAccumulatorGroups(
  List<AccumulatorGroup> groups,
  DateTime now,
) {
  return [
    for (final group in groups)
      if (!isPastEndDate(group.endDate, now)) group,
  ];
}
