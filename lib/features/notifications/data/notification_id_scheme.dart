/// Central registry for every notification ID range the app owns.
///
/// The reconciliation engine uses [isOurs] to scope cancellation: it must
/// never cancel an ID that doesn't belong to this app. Each scheme below
/// matches the constants that previously lived inline in
/// `routine_notification_service.dart` and `RoutineBlock.notificationId`.
class NotificationIdScheme {
  NotificationIdScheme._();

  /// Diagnostic test notification ID (mirrors the constant used by
  /// [`notification_settings_screen.dart`]).
  static const int kDiagnosticTestId = 9999;

  // ── Legacy plan/series ranges ───────────────────────────────────────────
  // Plan and series reminders are delivered via server push (FCM) now and are
  // no longer scheduled locally. These ranges are retained ONLY so [isOurs]
  // still recognises leftover notifications scheduled by older app versions,
  // letting the reconcile pass cancel them on the first sync after upgrade.
  // No generators remain — nothing issues new IDs in these ranges.

  // Special-plan notifications (immediate one-shots + daily series both fell in
  // this band). Retained so [isOurs] can cancel leftovers from older versions.
  static const int specialPlanOneShotBase = 800;
  static const int specialPlanOneShotMax = 899;

  // Routine block hash (FNV-1a in [RoutineBlock.notificationId]).
  static const int routineBlockMin = 1000;
  static const int routineBlockMax = 999999;

  // General-plan immediate one-shot.
  static const int planOneShotBase = 9000000;
  static const int planOneShotMax = 9009999;

  // General-plan daily series.
  static const int planSeriesBase = 10000000;
  static const int planSeriesMax = 15004999;

  // Routine block accumulator (mala) daily-repeat. A block may hold both a
  // recitation and a mala; the recitation keeps [RoutineBlock.notificationId]
  // (routineBlock* range) while the mala maps into this parallel range so the
  // two daily-repeats never collide on one ID.
  static const int accumulatorBlockBase = 20000000;
  static const int accumulatorBlockMax = 20999999;

  // Routine block timer daily-repeat. A timer block fires ONE daily reminder at
  // block time ("timer started"), in its own parallel range so it never
  // collides with the recitation/mala daily-repeats a block may also hold.
  static const int timerStartBase = 21000000;
  static const int timerStartMax = 21999999;

  // Routine block group-recitation-collection (chants list) daily-repeat. A
  // block may hold a group collection alongside a single recitation and/or a
  // mala/timer item, so this lives in its own parallel range to avoid
  // colliding with any of them.
  static const int groupCollectionBase = 23000000;
  static const int groupCollectionMax = 23999999;

  // Routine block personal recitation-collection (chants list) daily-repeat.
  // Kept separate from group collections because a block can contain both
  // collection kinds.
  static const int myCollectionBase = 24000000;
  static const int myCollectionMax = 24999999;

  // Routine block group-accumulator daily-repeat, separate from the mala range.
  static const int groupAccumulatorBase = 25000000;
  static const int groupAccumulatorMax = 25999999;

  /// Stable daily-repeat ID for a mala/accumulator block. Derived from the
  /// block's own notification ID so it survives restarts, but lives in a
  /// range separate from the recitation daily-repeat
  /// ([RoutineBlock.notificationId]) so a block holding both never collides.
  static int accumulatorBlockId(int blockNotificationId) =>
      accumulatorBlockBase + (blockNotificationId - routineBlockMin);

  /// Stable daily-repeat ID for a timer block's "started" reminder, fired at
  /// block time. Derived from the block's own notification ID (like
  /// [accumulatorBlockId]) but in a separate range so a block holding a timer
  /// plus other item types never collides.
  static int timerStartId(int blockNotificationId) =>
      timerStartBase + (blockNotificationId - routineBlockMin);

  /// Stable daily-repeat ID for a group-recitation-collection (chants list)
  /// block reminder. Derived from the block's own notification ID (like
  /// [accumulatorBlockId] / [timerStartId]) but in a separate range so a block
  /// holding a collection plus other item types never collides.
  static int groupCollectionId(int blockNotificationId) =>
      groupCollectionBase + (blockNotificationId - routineBlockMin);

  /// Stable daily-repeat ID for a personal recitation collection block.
  static int myCollectionId(int blockNotificationId) =>
      myCollectionBase + (blockNotificationId - routineBlockMin);

  /// Stable daily-repeat ID for a group-accumulator block.
  static int groupAccumulatorId(int blockNotificationId) =>
      groupAccumulatorBase + (blockNotificationId - routineBlockMin);

  // ── Meditation timer session ────────────────────────────────────────────
  // A running timer session posts an ongoing status notification and, while the
  // app is backgrounded, schedules its completion bell. Only one session can be
  // active at a time, so these are fixed IDs rather than a derived range.
  //
  // These are deliberately NOT reported by [isOurs]: the reconcile pass cancels
  // every "ours" ID it doesn't expect to be scheduled, and a routine sync firing
  // mid-session would silently kill the user's running meditation timer. The
  // timer screen owns these two IDs end to end and cancels them itself.
  static const int timerSessionOngoingId = 22000001;
  static const int timerSessionCompleteId = 22000002;

  /// True when [id] is a routine daily-repeat: recitation/chants via
  /// [routineBlockMin]–[routineBlockMax], mala via the accumulator range, a
  /// timer start reminder via the timer range, or a recitation-collection
  /// reminder via the collection ranges. These are the only notification kinds
  /// the engine schedules locally.
  static bool isRoutineDailyRepeat(int id) =>
      (id >= routineBlockMin && id <= routineBlockMax) ||
      (id >= accumulatorBlockBase && id <= accumulatorBlockMax) ||
      (id >= timerStartBase && id <= timerStartMax) ||
      (id >= groupCollectionBase && id <= groupCollectionMax) ||
      (id >= myCollectionBase && id <= myCollectionMax) ||
      (id >= groupAccumulatorBase && id <= groupAccumulatorMax);

  /// True when [id] was issued by any of the schemes registered here.
  /// Used by the engine to scope reconciliation: it must NEVER cancel an
  /// ID that doesn't belong to this app (e.g. another plugin's IDs).
  static bool isOurs(int id) {
    if (id == kDiagnosticTestId) return true;
    if (id >= specialPlanOneShotBase && id <= specialPlanOneShotMax) return true;
    if (id >= routineBlockMin && id <= routineBlockMax) return true;
    if (id >= planOneShotBase && id <= planOneShotMax) return true;
    if (id >= planSeriesBase && id <= planSeriesMax) return true;
    if (id >= accumulatorBlockBase && id <= accumulatorBlockMax) return true;
    if (id >= timerStartBase && id <= timerStartMax) return true;
    if (id >= groupCollectionBase && id <= groupCollectionMax) return true;
    if (id >= myCollectionBase && id <= myCollectionMax) return true;
    if (id >= groupAccumulatorBase && id <= groupAccumulatorMax) return true;
    return false;
  }
}
