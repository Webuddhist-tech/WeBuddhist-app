import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';

/// Where the reader was opened from, as far as language defaults go.
///
/// Each context seeds its own initial layout (see `resolveInitialLayout`) and
/// remembers the user's changes separately, so turning the original off at an
/// event never changes how a text reads in the library.
enum ReaderLayoutContext {
  /// The text library, search results and deep links: the app-wide reader
  /// settings, unchanged.
  library,

  /// A group event's puja: any reader opened with an event id, whether it is
  /// a plan subtask or the event's group accumulation chant.
  event,

  /// The chant list, a routine, a recitation collection or a group chant
  /// outside an event.
  chant,

  /// A plan subtask outside an event.
  plan,
}

/// The [ReaderLayoutContext] a reader opened with [context] belongs to.
///
/// An event id wins over the source: the same plan subtask is an event when
/// entered from the event page and a plan otherwise.
ReaderLayoutContext readerLayoutContextOf(NavigationContext? context) {
  if (context == null) return ReaderLayoutContext.library;
  if (context.isFromEvent) return ReaderLayoutContext.event;
  return switch (context.source) {
    NavigationSource.plan => ReaderLayoutContext.plan,
    NavigationSource.recitationList ||
    NavigationSource.routine ||
    NavigationSource.groupAccumulatorChant ||
    NavigationSource.groupRecitationCollection ||
    NavigationSource.myRecitationCollection => ReaderLayoutContext.chant,
    NavigationSource.normal ||
    NavigationSource.search ||
    NavigationSource.deepLink => ReaderLayoutContext.library,
  };
}
