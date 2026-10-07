import 'dart:math';

import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';

/// Display rules for [GroupAccumulationsSheet], kept free of widgets so they
/// can be tested directly.

/// True when an event links this accumulation, which puts it under "Events".
bool isEventAccumulation(AccumulatorGroup group) =>
    _clean(group.eventTitle) != null;

/// Splits the joined accumulations into the sheet's two sections, keeping the
/// order the API returned within each.
({List<AccumulatorGroup> events, List<AccumulatorGroup> groups})
splitAccumulationSections(List<AccumulatorGroup> all) {
  final events = <AccumulatorGroup>[];
  final groups = <AccumulatorGroup>[];
  for (final group in all) {
    (isEventAccumulation(group) ? events : groups).add(group);
  }
  return (events: events, groups: groups);
}

/// The event's title for an event-linked row, otherwise the accumulation's own
/// title. Null when neither is set, so the caller can show its placeholder.
String? accumulationRowTitle(AccumulatorGroup group) =>
    _clean(group.eventTitle) ?? _clean(group.title);

/// The owning group's name, shown under the title.
String? accumulationRowSubtitle(AccumulatorGroup group) =>
    _clean(group.groupName);

/// Header total: personal practice plus the user's total in every listed
/// accumulation. The two are stored separately, so nothing is counted twice.
int allTimeAccumulation({
  required int personalLifetime,
  required Iterable<int> myGroupLifetimes,
}) => myGroupLifetimes.fold(personalLifetime, (sum, count) => sum + count);

/// [apiGroupTotal] already holds the user's synced [apiMyTotal]. The sheet
/// shows [displayMyTotal], which adds taps not yet synced, so the same tail is
/// added here to keep "My total" and "Group total" moving together.
int groupTotalWithUnsynced({
  required int apiGroupTotal,
  required int apiMyTotal,
  required int displayMyTotal,
}) {
  final unsynced = max(0, displayMyTotal - apiMyTotal);
  return max(apiGroupTotal + unsynced, displayMyTotal);
}

String? _clean(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
