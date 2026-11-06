import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_tracking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What was tapped, carried as `item` on `me_item_tapped`. Edit profile sits in
/// Settings, one step away from the Me page.
enum MeItem {
  streak,
  practiceDays,
  accumulation,
  prayerRequests,
  settings,
  editProfile;

  String get key => switch (this) {
    MeItem.streak => 'streak',
    MeItem.practiceDays => 'practice_days',
    MeItem.accumulation => 'accumulation',
    MeItem.prayerRequests => 'prayer_requests',
    MeItem.settings => 'settings',
    MeItem.editProfile => 'edit_profile',
  };
}

/// Product analytics for the Me page: one method per tracked action, so the
/// event names and their property keys live in one place. Every call fires and
/// forgets.
class MeAnalytics {
  const MeAnalytics(this._analytics);

  final AnalyticsService _analytics;

  void itemTapped(MeItem item) {
    _analytics.trackInBackground(AnalyticsEvents.meItemTapped, {
      AnalyticsProperties.item: item.key,
    });
  }
}

final meAnalyticsProvider = Provider<MeAnalytics>((ref) {
  return MeAnalytics(ref.watch(analyticsServiceProvider));
});
