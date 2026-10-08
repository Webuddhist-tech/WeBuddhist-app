import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_intention_dto.dart';

/// Server orderings of a room's prayer requests (`sort` on the messages
/// endpoint). The server's `random` is not offered in the app.
enum PrayerSort {
  newest('newest'),
  oldest('oldest'),
  mostPrayed('most_prayed'),
  needsPrayers('needs_prayers');

  const PrayerSort(this.apiValue);

  final String apiValue;
}

/// What the list is narrowed to: an ordering, or one intention.
class PrayerRequestsFilter extends Equatable {
  const PrayerRequestsFilter({this.sort = PrayerSort.newest, this.intention});

  /// Ignored by the server when [intention] is set; it then orders newest.
  final PrayerSort sort;

  /// Only requests with this intention; null lists them all.
  final ChatPrayerIntentionDTO? intention;

  static const PrayerRequestsFilter initial = PrayerRequestsFilter();

  bool get byIntention => intention != null;

  String? get sortParam => byIntention ? null : sort.apiValue;

  String? get intentionParam => intention?.slug;

  /// Whether a request belongs in a list under this filter.
  bool matches(ChatPrayerIntentionDTO? requestIntention) {
    final slug = intention?.slug;
    return slug == null || requestIntention?.slug == slug;
  }

  PrayerRequestsFilter withSort(PrayerSort sort) =>
      PrayerRequestsFilter(sort: sort);

  PrayerRequestsFilter withIntention(ChatPrayerIntentionDTO intention) =>
      PrayerRequestsFilter(sort: sort, intention: intention);

  PrayerRequestsFilter withoutIntention() => PrayerRequestsFilter(sort: sort);

  @override
  List<Object?> get props => [sort, intention?.slug];
}
