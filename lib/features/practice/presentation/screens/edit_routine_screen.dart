import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/domain/usecases/get_series_by_id_usecase.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/home/presentation/providers/routine_info_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_enrollment_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart'
    show getSeriesByIdUseCaseProvider;
import 'package:flutter_pecha/features/plans/plans.dart';
import 'package:flutter_pecha/features/practice/data/models/my_recitation_collection_models.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/models/session_selection.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/features/practice/data/utils/routine_api_mapper.dart';
import 'package:flutter_pecha/features/practice/data/utils/routine_time_utils.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/select_session_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_time_block.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
final _logger = AppLogger('EditRoutineScreen');

ResponsiveImage? _accumulatorCoverImage(Mantra mantra) {
  final url = mantra.beadImageUrl ?? mantra.mantra?.beadImageUrl;
  if (url == null || url.trim().isEmpty) return null;
  return ResponsiveImage.uniform(url);
}

ResponsiveImage? _collectionCoverImage(GroupRecitationCollection collection) {
  final url = collection.imageUrl;
  if (url == null || url.trim().isEmpty) return null;
  return ResponsiveImage.uniform(url);
}

ResponsiveImage? _myCollectionCoverImage(
  MyRecitationCollectionDetailModel collection,
) {
  final url = collection.imgUrl;
  if (url == null || url.trim().isEmpty) return null;
  return ResponsiveImage.uniform(url);
}

class _EditableBlock {
  String id;
  String? apiTimeBlockId;
  TimeOfDay time;
  String? title;

  /// Title last sent to or received from the server; drives change detection.
  String? syncedTitle;
  bool notificationEnabled;
  List<RoutineItem> items;

  _EditableBlock({
    String? id,
    this.apiTimeBlockId,
    required this.time,
    this.title,
    required this.notificationEnabled,
    List<RoutineItem>? items,
  }) : id = id ?? _uuid.v4(),
       syncedTitle = title,
       items = items ?? [];
}

class EditRoutineScreen extends ConsumerStatefulWidget {
  final Plan? initialPlan;
  final RecitationModel? initialRecitation;
  final PresetTimer? initialTimer;

  /// When provided, the preset mala/accumulator is injected into the routine
  /// after hydration as an ACCUMULATOR session.
  final Mantra? initialMantra;

  /// When provided, the already-loaded series is injected into the routine
  /// after hydration. Preferred over [enrollSeriesId] when the caller already
  /// holds the [Series] (e.g. the series detail screen), as it avoids a
  /// redundant `GET /series/{id}`. Adding the SERIES session enrolls the user
  /// server-side, so no separate enroll call is needed.
  final Series? initialSeries;

  /// When provided, after hydration the screen fetches and adds the series to
  /// the routine by id. Used by the Enroll button, which only has the id.
  final String? enrollSeriesId;

  /// When provided, the group chant collection is injected into the routine
  /// after hydration as a GROUP_RECITATION_COLLECTION session.
  final GroupRecitationCollection? initialGroupCollection;

  /// When provided, the personal chant collection is injected into the routine
  /// after hydration as a RECITATION_COLLECTION session.
  final MyRecitationCollectionDetailModel? initialMyCollection;

  /// Injected after hydration as a GROUP_ACCUMULATOR session (must be joined).
  final GroupAccumulator? initialGroupAccumulator;

  const EditRoutineScreen({
    super.key,
    this.initialPlan,
    this.initialRecitation,
    this.initialTimer,
    this.initialMantra,
    this.initialSeries,
    this.enrollSeriesId,
    this.initialGroupCollection,
    this.initialMyCollection,
    this.initialGroupAccumulator,
  });

  @override
  ConsumerState<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends ConsumerState<EditRoutineScreen> {
  late List<_EditableBlock> _blocks;

  /// Server routine id once loaded or after first create.
  String? _apiRoutineId;

  bool _hydratedFromApi = false;

  /// Guard so series-enrollment prefill runs exactly once after hydration.
  bool _seriesEnrollmentHydrated = false;

  /// Sequential queue so API calls never overlap or race.
  Future<void> _opQueue = Future.value();

  bool get _hasEmptyBlocks => _blocks.any((b) => b.items.isEmpty);

  @override
  void initState() {
    super.initState();
    _blocks = [
      _EditableBlock(time: TimeOfDay.now(), notificationEnabled: true),
    ];
  }

  // ─── Hydration ───

  void _applyInitialData(RoutineData? routineData) {
    _apiRoutineId = routineData?.apiRoutineId;

    if (routineData != null && routineData.blocks.isNotEmpty) {
      _blocks =
          routineData.blocks
              .map(
                (b) => _EditableBlock(
                  id: b.id,
                  apiTimeBlockId: b.apiTimeBlockId,
                  time: b.time,
                  title: b.title,
                  notificationEnabled: b.notificationEnabled,
                  items: List.from(b.items),
                ),
              )
              .toList();
    } else {
      _blocks = [
        _EditableBlock(time: TimeOfDay.now(), notificationEnabled: true),
      ];
    }
  }

  /// Resolves where to place auto-injected items (plan deep-link or series
  /// enrollment prefill). Prefers the earliest existing empty block, re-timed
  /// to the user's current local time (with the standard 10-minute gap from
  /// other blocks). Falls back to a brand-new block at the current local
  /// time, and finally to `_blocks.first` if no valid slot is available.
  ///
  /// Mutates `block.time` and reorders `_blocks` (via `_sortBlocks`), so the
  /// caller must wrap this in `setState` when called outside the build phase.
  ({_EditableBlock target, bool isNewBlock}) _resolveInjectionTarget() {
    _sortBlocks();

    for (final block in _blocks) {
      if (block.items.isEmpty) {
        final otherTimes =
            _blocks
                .where((b) => !identical(b, block))
                .map((b) => b.time)
                .toList();
        final adjusted = adjustTimeForMinimumGap(TimeOfDay.now(), otherTimes);
        if (adjusted != null) {
          block.time = adjusted;
        }
        return (target: block, isNewBlock: false);
      }
    }

    final allTimes = _blocks.map((b) => b.time).toList();
    final adjusted = adjustTimeForMinimumGap(TimeOfDay.now(), allTimes);
    if (adjusted == null) {
      return (target: _blocks.first, isNewBlock: false);
    }
    final newBlock = _EditableBlock(time: adjusted, notificationEnabled: true);
    return (target: newBlock, isNewBlock: true);
  }

  void _injectInitialPlan(Plan plan) {
    final alreadyExists = _blocks.any(
      (b) => b.items.any((item) => item.representsStandalonePlan(plan.id)),
    );
    if (alreadyExists) return;

    final newItem = _routineItemFromPlan(plan);

    final resolved = _resolveInjectionTarget();
    resolved.target.items.add(newItem);
    if (resolved.isNewBlock) {
      _blocks.add(resolved.target);
    }
    _sortBlocks();
  }

  _EditableBlock? _injectInitialRecitation(RecitationModel recitation) {
    final newItem = RoutineItem(
      id: recitation.textId,
      title: recitation.title,
      type: RoutineItemType.recitation,
      language: recitation.language,
      firstSegment: recitation.firstSegment,
    );

    final resolved = _resolveInjectionTarget();
    resolved.target.items.add(newItem);
    if (resolved.isNewBlock) {
      _blocks.add(resolved.target);
    }
    _sortBlocks();
    return resolved.target;
  }

  RoutineItem _routineItemFromTimer(PresetTimer timer) => RoutineItem(
    id: _uuid.v4(),
    title: '',
    type: RoutineItemType.timer,
    durationMs: timer.durationMs,
  );

  _EditableBlock? _injectInitialTimer(PresetTimer timer) {
    final newItem = _routineItemFromTimer(timer);

    final resolved = _resolveInjectionTarget();
    resolved.target.items.add(newItem);
    if (resolved.isNewBlock) {
      _blocks.add(resolved.target);
    }
    _sortBlocks();
    return resolved.target;
  }

  /// Adds the preset mala/accumulator into the routine as an ACCUMULATOR
  /// session (accumulator_id = preset id). Like series, a mala may live in
  /// multiple time blocks, so the duplicate guard is scoped to the target block only.
  _EditableBlock? _injectInitialAccumulator(Mantra mantra) {
    final resolved = _resolveInjectionTarget();

    final duplicateInTarget = resolved.target.items.any(
      (item) =>
          item.id == mantra.presetId &&
          item.type == RoutineItemType.accumulator,
    );
    if (duplicateInTarget) return null;

    final language = ref.read(contentLanguageProvider);
    resolved.target.items.add(
      RoutineItem(
        id: mantra.presetId,
        title: mantra.displayTitle(language),
        coverImage: _accumulatorCoverImage(mantra),
        type: RoutineItemType.accumulator,
        enrolledAt: DateTime.now(),
      ),
    );
    if (resolved.isNewBlock) {
      _blocks.add(resolved.target);
    }
    _sortBlocks();
    return resolved.target;
  }

  /// Adds [collection] into the routine as a chant-collection session.
  ///
  /// The backend allows a collection only once per routine — across every time
  /// block, not just the target one — so the duplicate guard is global here and
  /// returns null rather than letting the sync fail with a 422.
  _EditableBlock? _injectInitialGroupCollection(
    GroupRecitationCollection collection,
  ) {
    final alreadyInRoutine = _blocks.any(
      (b) => b.items.any(
        (item) =>
            item.id == collection.id &&
            item.type == RoutineItemType.groupRecitationCollection,
      ),
    );
    if (alreadyInRoutine) return null;

    final resolved = _resolveInjectionTarget();
    resolved.target.items.add(
      RoutineItem(
        id: collection.id,
        title: collection.name,
        coverImage: _collectionCoverImage(collection),
        type: RoutineItemType.groupRecitationCollection,
        itemCount:
            collection.itemCount > 0
                ? collection.itemCount
                : collection.items.length,
        enrolledAt: DateTime.now(),
      ),
    );
    if (resolved.isNewBlock) {
      _blocks.add(resolved.target);
    }
    _sortBlocks();
    return resolved.target;
  }

  /// Adds [collection] into the routine as a personal chant-collection session.
  ///
  /// Personal and group chant collections are distinct client-side because
  /// they serialize to different backend session types and navigate to
  /// different detail screens.
  _EditableBlock? _injectInitialMyCollection(
    MyRecitationCollectionDetailModel collection,
  ) {
    final alreadyInRoutine = _blocks.any(
      (b) => b.items.any(
        (item) =>
            item.id == collection.id &&
            item.type == RoutineItemType.myRecitationCollection,
      ),
    );
    if (alreadyInRoutine) return null;

    final resolved = _resolveInjectionTarget();
    resolved.target.items.add(
      RoutineItem(
        id: collection.id,
        title: collection.name,
        coverImage: _myCollectionCoverImage(collection),
        type: RoutineItemType.myRecitationCollection,
        itemCount: collection.items.length,
        enrolledAt: DateTime.now(),
      ),
    );
    if (resolved.isNewBlock) {
      _blocks.add(resolved.target);
    }
    _sortBlocks();
    return resolved.target;
  }

  /// Adds a GROUP_ACCUMULATOR session. A group accumulation is scheduled at
  /// most once per routine — across every time block, like collections — so
  /// the duplicate guard is global and returns null instead of syncing a second
  /// session (and a second daily reminder) for the same accumulation.
  _EditableBlock? _injectInitialGroupAccumulator(GroupAccumulator accumulator) {
    final alreadyInRoutine = _blocks.any(
      (b) => b.items.any(
        (item) =>
            item.id == accumulator.id &&
            item.type == RoutineItemType.groupAccumulator,
      ),
    );
    if (alreadyInRoutine) return null;

    final resolved = _resolveInjectionTarget();
    resolved.target.items.add(
      RoutineItem(
        id: accumulator.id,
        title: accumulator.title,
        coverImage: accumulator.image,
        type: RoutineItemType.groupAccumulator,
        enrolledAt: DateTime.now(),
      ),
    );
    if (resolved.isNewBlock) {
      _blocks.add(resolved.target);
    }
    _sortBlocks();
    return resolved.target;
  }

  /// Tells the user the collection they arrived with is already scheduled,
  /// so nothing was added. Shared by both collection kinds.
  void _showCollectionAlreadyAddedSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.practice_collection_already_added),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Same as [_showCollectionAlreadyAddedSnackBar] for a group accumulation.
  void _showGroupAccumulatorAlreadyAddedSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.practice_group_accumulator_already_added),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Syncs the block that contains [plan] after deep-link injection.
  void _syncInjectedPlan(Plan plan) {
    for (final block in _blocks) {
      if (block.items.any((i) => i.representsStandalonePlan(plan.id))) {
        _syncBlock(block)
            .then((_) {
              if (mounted) _refreshPracticeEnrollments();
            })
            .catchError((e) {
              if (mounted) _showErrorSnackBar(_mapError(e));
            });
        break;
      }
    }
  }

  /// Loads [seriesId] and injects the series into the routine if it is not
  /// already present in any block.
  Future<void> _hydrateSeriesEnrollment(String seriesId) async {
    final language = ref.read(contentLanguageProvider);
    final result = await ref.read(getSeriesByIdUseCaseProvider)(
      GetSeriesByIdParams(id: seriesId, language: language),
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        _logger.warning(
          '[SERIES-ENROLL-PREFILL] failed to fetch series $seriesId: '
          '${failure.message}',
        );
        _showErrorSnackBar(failure.message);
      },
      (series) {
        final injectedBlock = _injectSeries(series);
        if (injectedBlock != null) {
          _syncBlock(injectedBlock)
              .then((_) {
                if (mounted) _refreshPracticeEnrollments();
              })
              .catchError((e) {
                if (mounted) _showErrorSnackBar(_mapError(e));
              });
        }
      },
    );
  }

  /// Adds [series] into the routine. Returns the affected block (to drive a
  /// follow-up server sync) or null if it would duplicate the series within the
  /// resolved block.
  ///
  /// A series may live in multiple time blocks (e.g. a morning and an evening
  /// session), so the duplicate guard is scoped to the target block only — not
  /// the whole routine.
  ///
  /// No-`setState` core, designed to be called inside the build-phase
  /// hydration `setState` (like the other `_injectInitial*` methods).
  _EditableBlock? _injectInitialSeries(Series series) {
    final resolved = _resolveInjectionTarget();

    final duplicateInTarget = resolved.target.items.any(
      (item) => item.id == series.id && item.type == RoutineItemType.series,
    );
    if (duplicateInTarget) return null;

    resolved.target.items.add(
      RoutineItem(
        id: series.id,
        title: series.title,
        coverImage: series.coverImage,
        type: RoutineItemType.series,
        enrolledAt: DateTime.now(),
      ),
    );
    if (resolved.isNewBlock) {
      _blocks.add(resolved.target);
    }
    _sortBlocks();
    return resolved.target;
  }

  /// `setState`-wrapped variant for async callers (the [enrollSeriesId] path,
  /// which injects after an `await`).
  _EditableBlock? _injectSeries(Series series) {
    _EditableBlock? target;
    setState(() {
      target = _injectInitialSeries(series);
    });
    return target;
  }

  RoutineBlock _toRoutineBlock(_EditableBlock b) {
    return RoutineBlock(
      id: b.id,
      time: b.time,
      title: b.title,
      notificationEnabled: b.notificationEnabled,
      apiTimeBlockId: b.apiTimeBlockId,
      items: b.items,
    );
  }

  // ─── Operation queue ───

  /// Enqueues [fn] so API calls run sequentially.
  /// Errors propagate to callers but never break the chain for subsequent ops.
  Future<void> _enqueue(Future<void> Function() fn) async {
    final prev = _opQueue;
    final completer = Completer<void>();
    _opQueue = completer.future;

    try {
      await prev;
    } catch (_) {}

    try {
      await fn();
    } finally {
      // Always release the queue slot, whether fn() succeeded or threw.
      completer.complete();
    }
  }

  // ─── Server sync ───

  /// Syncs a single block's current local state to the server.
  ///
  /// Empty block with a server ID → DELETE (block becomes local-only).
  /// Block with items but no server ID → CREATE (routine or time block).
  /// Block with items and a server ID → UPDATE (full replacement).
  Future<void> _syncBlock(_EditableBlock block) {
    // Read use cases now: the queued closure can run after this widget is
    // disposed (e.g. a title sync queued from Done), when `ref` is gone.
    final deleteTimeBlock = ref.read(deleteTimeBlockUseCaseProvider);
    final createRoutineWithTimeBlock = ref.read(
      createRoutineWithTimeBlockUseCaseProvider,
    );
    final createTimeBlock = ref.read(createTimeBlockUseCaseProvider);
    final updateTimeBlock = ref.read(updateTimeBlockUseCaseProvider);

    return _enqueue(() async {
      if (block.items.isEmpty) {
        if (block.apiTimeBlockId != null && _apiRoutineId != null) {
          final result = await deleteTimeBlock(
            _apiRoutineId!,
            block.apiTimeBlockId!,
          );
          result.fold((f) => throw f, (_) {
            if (mounted) setState(() => block.apiTimeBlockId = null);
          });
        }
        return;
      }

      final request = routineBlockToRequest(_toRoutineBlock(block));

      if (_apiRoutineId == null) {
        // First block ever: creates the routine + block together.
        final result = await createRoutineWithTimeBlock(request);
        result.fold((f) => throw f, (created) {
          block.syncedTitle = request.title;
          if (mounted) {
            setState(() {
              _apiRoutineId = created.routineId;
              block.apiTimeBlockId = created.timeBlockId;
              block.id = created.timeBlockId;
            });
          }
        });
      } else if (block.apiTimeBlockId == null) {
        // Routine exists but this block is new.
        final result = await createTimeBlock(_apiRoutineId!, request);
        result.fold((f) => throw f, (timeBlockId) {
          block.syncedTitle = request.title;
          if (mounted) {
            setState(() {
              block.apiTimeBlockId = timeBlockId;
              block.id = timeBlockId;
            });
          }
        });
      } else {
        // Both exist — full replacement update.
        final result = await updateTimeBlock(
          _apiRoutineId!,
          block.apiTimeBlockId!,
          request,
        );
        result.fold((f) => throw f, (_) => block.syncedTitle = request.title);
      }
    });
  }

  void _onTitleChanged(_EditableBlock block, String raw) {
    block.title = RoutineBlock.normalizeTitle(raw);
  }

  /// Pushes a title edit to the server once the field loses focus. Local-only
  /// blocks skip this; their title rides along when the first session syncs.
  Future<void> _syncTitleIfChanged(_EditableBlock block) async {
    if (block.apiTimeBlockId == null || block.title == block.syncedTitle) {
      return;
    }
    final previous = block.syncedTitle;
    block.syncedTitle = block.title;
    try {
      await _syncBlock(block);
    } catch (e) {
      block.syncedTitle = previous;
      if (mounted) _showErrorSnackBar(_mapError(e));
    }
  }

  /// Deletes a persisted time block from the server.
  Future<void> _deletePersistedBlock(String apiTimeBlockId) =>
      _enqueue(() async {
        if (_apiRoutineId == null) return;
        final result = await ref.read(deleteTimeBlockUseCaseProvider)(
          _apiRoutineId!,
          apiTimeBlockId,
        );
        result.fold((f) => throw f, (_) {});
      });

  // ─── Error handling ───

  String _mapError(Object e) {
    if (e is Failure) return e.message;
    if (e is Exception) return e.toString().replaceFirst('Exception: ', '');
    return AppLocalizations.of(context)!.something_went_wrong;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ─── Save flow ───

  /// Optimistic save: persists local state synchronously, then pops and
  /// defers slow work (notification reschedule, paginated plans refetch,
  /// in-flight API drain) to the background.
  ///
  /// Why: the previous serial flow could block the user for 3–4s because
  /// (1) `_opQueue` waited for every in-flight `_syncBlock` to finish,
  /// (2) notification sync issues 60+ platform-channel calls per plan
  /// block, and (3) `myPlansPaginatedProvider.refresh()` is a network
  /// round-trip. None of those need to complete before the user leaves
  /// the screen — Hive is the source of truth for the next render, and
  /// the startup bootstrap re-syncs notifications on the next launch if
  /// the background work fails.
  Future<void> _saveAndPop() async {
    // 1. Empty-block confirmation must run synchronously — it depends on
    //    the user's input and changes what we persist below.
    if (_hasEmptyBlocks) {
      final shouldDelete = await _showEmptyBlockDialog();
      if (!mounted) return;
      if (shouldDelete == true) {
        setState(() => _blocks.removeWhere((b) => b.items.isEmpty));
      } else {
        return;
      }
    }

    // 2. A title still focused has not hit the server yet; queue it before
    //    the op queue is captured so the background drain waits for it.
    FocusManager.instance.primaryFocus?.unfocus();
    for (final block in _blocks) {
      unawaited(_syncTitleIfChanged(block));
    }

    // 3. Capture Riverpod handles BEFORE pop. `ref` becomes invalid once
    //    this State is disposed, but the captured notifier instances are
    //    kept alive by the ProviderScope (these providers are not
    //    autoDispose), so the background block below can use them safely.
    final routineNotifier = ref.read(routineProvider.notifier);
    final myPlansNotifier = ref.read(myPlansPaginatedProvider.notifier);
    final pendingOps = _opQueue;
    final blocks = _blocks.map(_toRoutineBlock).toList();

    // 4. Await ONLY the Hive write. It is fast (~ms) and the next screen
    //    reads from Hive-backed state, so this must complete before pop.
    //    A failure here is fatal: we surface it and stay on the screen.
    _logger.info('[EDIT-SAVE] persisting ${blocks.length} blocks');
    try {
      await routineNotifier.saveRoutineLocalOnly(blocks);
    } catch (e, st) {
      _logger.error('[EDIT-SAVE] local save failed', e, st);
      if (mounted) _showErrorSnackBar(_mapError(e));
      return;
    }

    // 5. Invalidate while context is alive. These are cheap; the actual
    //    refetch happens lazily when the next screen reads the provider.
    ref.invalidate(userRoutineProvider);
    ref.invalidate(userPlansFutureProvider);
    ref.invalidate(routineInfoFutureProvider);

    if (mounted) {
      _logger.info('[EDIT-SAVE] popping (background tasks continuing)');
      context.pop();
    }

    // 6. Fire-and-forget the slow work. Errors are non-fatal:
    //    - API queue: each op's user-visible error was already surfaced
    //      inline when the user added the item.
    //    - Notification sync: startup bootstrap re-syncs on next launch.
    //    - Plans refresh: the list refetches when next viewed.
    //    We intentionally do NOT touch `setState`, `ref`, or `context`
    //    below — this closure outlives the widget.
    unawaited(() async {
      try {
        await pendingOps;
      } catch (e) {
        _logger.warning('[EDIT-SAVE-BG] op queue drained with error: $e');
      }
      try {
        await routineNotifier.syncNotifications(blocks);
      } catch (e) {
        _logger.warning('[EDIT-SAVE-BG] notification sync failed: $e');
      }
      try {
        await myPlansNotifier.refresh();
      } catch (e) {
        _logger.warning('[EDIT-SAVE-BG] plans refresh failed: $e');
      }
    }());
  }

  // ─── Dialogs ───

  Future<bool?> _showEmptyBlockDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emptyCount = _blocks.where((b) => b.items.isEmpty).length;
    final hasMultipleEmpty = emptyCount > 1;
    final l10n = context.l10n;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            hasMultipleEmpty
                ? l10n.routine_empty_block_title_plural(emptyCount)
                : l10n.routine_empty_block_title_singular,
          ),
          content: Text(
            hasMultipleEmpty
                ? l10n.routine_empty_block_message_plural(emptyCount)
                : l10n.routine_empty_block_message_singular,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                l10n.routine_empty_block_add_items,
                style: TextStyle(
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: Text(
                hasMultipleEmpty
                    ? l10n.routine_empty_block_delete_plural
                    : l10n.routine_empty_block_delete_singular,
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Block operations ───

  /// Shows a Cupertino wheel time picker in a modal bottom sheet and returns
  /// the selected [TimeOfDay], or null if dismissed.
  Future<TimeOfDay?> _showCupertinoTimePicker({
    required TimeOfDay initialTime,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Follow the device's clock setting so the wheel matches the system
    // 12h/24h preference (consistent with Material's showTimePicker).
    final use24hFormat = MediaQuery.of(context).alwaysUse24HourFormat;
    // Resolve l10n before entering the modal — the popup's builder context
    // does not inherit AppLocalizations from the route.
    final l10n = context.l10n;
    final now = DateTime.now();
    var selected = DateTime(
      now.year,
      now.month,
      now.day,
      initialTime.hour,
      initialTime.minute,
    );

    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) {
        // CupertinoDatePicker reads its text color from the ambient
        // CupertinoTheme, which defaults to light. Force the brightness to
        // match the app theme so the wheel digits stay legible in dark mode.
        return CupertinoTheme(
          data: CupertinoThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
          ),
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              color:
                  isDark
                      ? AppColors.cardBackgroundDark
                      : AppColors.surfaceWhite,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.grey100,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Confirm / Cancel row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(ctx).pop(false);
                        },
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(
                            color:
                                isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(ctx).pop(true);
                        },
                        child: Text(l10n.done),
                      ),
                    ],
                  ),
                  // Picker wheel
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: selected,
                      use24hFormat: use24hFormat,
                      onDateTimeChanged: (dt) => selected = dt,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return null;
    return TimeOfDay(hour: selected.hour, minute: selected.minute);
  }

  Future<void> _pickTime(int index) async {
    final initialTime = _blocks[index].time;
    final TimeOfDay? picked;
    if (Platform.isIOS) {
      picked = await _showCupertinoTimePicker(initialTime: initialTime);
    } else {
      if (!mounted) return;
      picked = await showTimePicker(context: context, initialTime: initialTime);
    }
    if (picked != null) {
      final otherTimes =
          _blocks
              .asMap()
              .entries
              .where((e) => e.key != index)
              .map((e) => e.value.time)
              .toList();
      final adjusted = adjustTimeForMinimumGap(picked, otherTimes);

      if (adjusted == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.noTimeSlot),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final block = _blocks[index];
      final previousTime = block.time;

      setState(() {
        block.time = adjusted;
        _sortBlocks();
      });

      if (adjusted != picked && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.routine_time_adjusted(
                formatRoutineTime(adjusted),
                kMinBlockGapMinutes,
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      if (block.apiTimeBlockId != null) {
        try {
          await _syncBlock(block);
        } catch (e) {
          if (mounted) {
            setState(() {
              block.time = previousTime;
              _sortBlocks();
            });
            _showErrorSnackBar(_mapError(e));
          }
        }
      }
    }
  }

  void _sortBlocks() {
    _blocks.sort(
      (a, b) => timeToMinutes(a.time).compareTo(timeToMinutes(b.time)),
    );
  }

  Future<void> _toggleNotification(int index) async {
    final block = _blocks[index];

    if (block.notificationEnabled) {
      final previousValue = block.notificationEnabled;
      setState(() => block.notificationEnabled = false);

      if (block.apiTimeBlockId != null) {
        try {
          await _syncBlock(block);
        } catch (e) {
          if (mounted) {
            setState(() => block.notificationEnabled = previousValue);
            _showErrorSnackBar(_mapError(e));
          }
        }
      }
      return;
    }

    final enabled = await NotificationService().areNotificationsEnabled();
    if (!enabled && mounted) {
      final granted = await _showNotificationPermissionModal();
      if (granted != true) return;
    }

    if (mounted) {
      setState(() => block.notificationEnabled = true);

      if (block.apiTimeBlockId != null) {
        try {
          await _syncBlock(block);
        } catch (e) {
          if (mounted) {
            setState(() => block.notificationEnabled = false);
            _showErrorSnackBar(_mapError(e));
          }
        }
      }
    }
  }

  Future<bool?> _showNotificationPermissionModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 48,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.routine_notification_title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.routine_notification_description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      final granted =
                          await NotificationService().requestPermission();
                      if (!granted) await openAppSettings();
                      final nowEnabled =
                          await NotificationService().areNotificationsEnabled();
                      nav.pop(nowEnabled);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                      foregroundColor:
                          isDark
                              ? AppColors.textPrimary
                              : AppColors.textPrimaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.routine_notification_enable,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      l10n.routine_notification_skip,
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteBlock(int index) async {
    final block = _blocks[index];
    final apiId = block.apiTimeBlockId;

    // Deliberately NO metadata/shown-flag clearing here. The deletion is not
    // committed until Done, and wiping the per-day delivery records at
    // delete-tap let a mid-edit sync re-fire today's already-delivered
    // notification (ghost duplicate). Committed removals are reconciled by
    // `_syncMetadata` on the next plans refresh.

    // Cancel immediately so the user doesn't receive a notification for a
    // block they just removed, even if they back out without pressing Done.
    // Full reconciliation runs on Done / cold-start via the engine.
    final routineBlock = _toRoutineBlock(block);
    await ref
        .read(routineNotificationServiceProvider)
        .cancelBlockNotification(routineBlock);

    setState(() => _blocks.removeAt(index));

    if (apiId != null) {
      try {
        await _deletePersistedBlock(apiId);
      } catch (e) {
        if (mounted) {
          setState(() {
            _blocks.add(block);
            _sortBlocks();
          });
          _showErrorSnackBar(_mapError(e));
        }
      }
    }
  }

  bool get _isAtMaxBlocks => !canAddBlock(_blocks.length);
  bool get _shouldShowAddButton => !_hasEmptyBlocks && !_isAtMaxBlocks;

  int _calculateListItemCount() {
    return _shouldShowAddButton ? _blocks.length + 1 : _blocks.length;
  }

  void _addBlock() {
    if (_hasEmptyBlocks) return;

    if (_isAtMaxBlocks) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.maxBlocks(kMaxBlocks)),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final otherTimes = _blocks.map((b) => b.time).toList();
    final adjusted = adjustTimeForMinimumGap(TimeOfDay.now(), otherTimes);

    if (adjusted == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.noTimeSlot),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _blocks.add(_EditableBlock(time: adjusted, notificationEnabled: true));
      _sortBlocks();
    });
    // No API call — block is local-only until the first session is added.
  }

  void _onReorderItems(int blockIndex, int oldIndex, int newIndex) {
    final block = _blocks[blockIndex];
    final previousOrder = List<RoutineItem>.from(block.items);

    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = block.items.removeAt(oldIndex);
      block.items.insert(newIndex, item);
    });

    if (block.apiTimeBlockId != null) {
      _syncBlock(block).catchError((e) {
        if (mounted) {
          setState(() {
            block.items
              ..clear()
              ..addAll(previousOrder);
          });
          _showErrorSnackBar(_mapError(e));
        }
      });
    }
  }

  Future<void> _onDeleteItem(int blockIndex, int itemIndex) async {
    final block = _blocks[blockIndex];
    final removedItem = block.items[itemIndex];
    final wasNotEmpty = block.items.isNotEmpty;

    setState(() => block.items.removeAt(itemIndex));

    // Deliberately NO metadata/shown-flag clearing here — see _deleteBlock.
    // Per-day delivery records must survive uncommitted edits so a same-day
    // re-add cannot duplicate today's notification.

    if (wasNotEmpty && block.items.isEmpty) {
      final routineBlock = RoutineBlock(
        id: block.id,
        time: block.time,
        notificationEnabled: block.notificationEnabled,
        apiTimeBlockId: block.apiTimeBlockId,
        items: const [],
      );
      await ref
          .read(routineNotificationServiceProvider)
          .cancelBlockNotification(routineBlock);
    }

    if (block.apiTimeBlockId != null) {
      _syncBlock(block)
          .then((_) {
            // After a successful server DELETE (block.items empty), remove the
            // now-orphaned local block so it does not linger as an empty row.
            if (mounted && block.items.isEmpty) {
              setState(() => _blocks.remove(block));
            }
          })
          .catchError((e) {
            if (mounted) {
              setState(() => block.items.insert(itemIndex, removedItem));
              _showErrorSnackBar(_mapError(e));
            }
          });
    } else if (block.items.isEmpty) {
      // No server state to sync — drop the empty local block immediately.
      setState(() => _blocks.remove(block));
    }
  }

  bool _isSelectingSession = false;

  Future<void> _navigateToSelectSession(int blockIndex) async {
    if (_isSelectingSession) return;
    _isSelectingSession = true;

    try {
      final result = await Navigator.of(context).push<SessionSelection>(
        MaterialPageRoute(builder: (_) => const SelectSessionScreen()),
      );

      if (result == null || !mounted) return;

      switch (result) {
        case PlanSessionSelection(:final plan):
          await _addPlanToBlock(blockIndex, plan);
        case RecitationSessionSelection(:final recitation):
          await _addRecitationToBlock(blockIndex, recitation);
        case SeriesSessionSelection(:final series):
          await _addSeriesToBlock(blockIndex, series);
        case TimerSessionSelection(:final timer):
          await _addTimerToBlock(blockIndex, timer);
        case MantraSessionSelection(:final mantra):
          await _addAccumulatorToBlock(blockIndex, mantra);
      }
    } finally {
      _isSelectingSession = false;
    }
  }

  RoutineItem _routineItemFromPlan(Plan plan) => RoutineItem(
    id: plan.id,
    title: plan.title,
    coverImage: plan.coverImage,
    type: RoutineItemType.plan,
    enrolledAt: DateTime.now(),
  );

  Future<void> _addPlanToBlock(int blockIndex, Plan plan) async {
    final isDuplicate = _blocks[blockIndex].items.any(
      (item) => item.representsStandalonePlan(plan.id),
    );
    if (isDuplicate) {
      _logger.warning('Duplicate item prevented: ${plan.id}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.duplicateItem),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final newItem = _routineItemFromPlan(plan);
    final block = _blocks[blockIndex];
    setState(() => block.items.add(newItem));

    try {
      await _syncBlock(block);
      _refreshPracticeEnrollments();
    } catch (e) {
      if (mounted) {
        setState(() => block.items.remove(newItem));
        _showErrorSnackBar(_mapError(e));
      }
    }
  }

  Future<void> _addRecitationToBlock(
    int blockIndex,
    RecitationModel recitation,
  ) async {
    if (blockIndex < 0 || blockIndex >= _blocks.length) return;
    final block = _blocks[blockIndex];

    final duplicateInBlock = block.items.any(
      (item) =>
          item.id == recitation.textId &&
          item.type == RoutineItemType.recitation,
    );
    if (duplicateInBlock) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.duplicateItem),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final newItem = RoutineItem(
      id: recitation.textId,
      title: recitation.title,
      type: RoutineItemType.recitation,
      language: recitation.language,
      firstSegment: recitation.firstSegment,
    );
    setState(() => block.items.add(newItem));

    try {
      await _syncBlock(block);
    } catch (e) {
      if (mounted) {
        setState(() => block.items.remove(newItem));
        _showErrorSnackBar(_mapError(e));
      }
    }
  }

  Future<void> _addTimerToBlock(int blockIndex, PresetTimer timer) async {
    final newItem = _routineItemFromTimer(timer);
    final block = _blocks[blockIndex];
    setState(() => block.items.add(newItem));

    try {
      await _syncBlock(block);
    } catch (e) {
      if (mounted) {
        setState(() => block.items.remove(newItem));
        _showErrorSnackBar(_mapError(e));
      }
    }
  }

  Future<void> _addAccumulatorToBlock(int blockIndex, Mantra mantra) async {
    if (blockIndex < 0 || blockIndex >= _blocks.length) return;
    final block = _blocks[blockIndex];

    final duplicateInBlock = block.items.any(
      (item) =>
          item.id == mantra.presetId &&
          item.type == RoutineItemType.accumulator,
    );
    if (duplicateInBlock) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.duplicateItem),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final language = ref.read(contentLanguageProvider);
    final newItem = RoutineItem(
      id: mantra.presetId,
      title: mantra.displayTitle(language),
      coverImage: _accumulatorCoverImage(mantra),
      type: RoutineItemType.accumulator,
      enrolledAt: DateTime.now(),
    );
    setState(() => block.items.add(newItem));

    try {
      await _syncBlock(block);
    } catch (e) {
      if (mounted) {
        setState(() => block.items.remove(newItem));
        _showErrorSnackBar(_mapError(e));
      }
    }
  }

  /// Adding a PLAN or SERIES session enrolls the user server-side, so the
  /// client only needs to refresh enrolled-plan / series caches after sync.
  void _refreshPracticeEnrollments() {
    ref.read(myPlansPaginatedProvider.notifier).refresh();
    ref.invalidate(userSeriesEnrollmentsProvider);
    ref.invalidate(routineInfoFutureProvider);
  }

  Future<void> _addSeriesToBlock(int blockIndex, Series series) async {
    if (blockIndex < 0 || blockIndex >= _blocks.length) return;
    final isDuplicate = _blocks[blockIndex].items.any(
      (item) => item.id == series.id && item.type == RoutineItemType.series,
    );
    if (isDuplicate) {
      _logger.warning('Duplicate item prevented: ${series.id}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.duplicateItem),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final newItem = RoutineItem(
      id: series.id,
      title: series.title,
      coverImage: series.coverImage,
      type: RoutineItemType.series,
      enrolledAt: DateTime.now(),
    );
    final block = _blocks[blockIndex];
    setState(() => block.items.add(newItem));

    try {
      await _syncBlock(block);
      _refreshPracticeEnrollments();
    } catch (e) {
      if (mounted) {
        setState(() => block.items.remove(newItem));
        _showErrorSnackBar(_mapError(e));
      }
    }
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show loading/error until the API data is hydrated into local editable
    // state. Watching the provider is limited to this guarded branch so that
    // external invalidations (e.g. ref.invalidate in _saveAndPop) never
    // rebuild the screen mid-editing once hydration is done.
    if (!_hydratedFromApi) {
      final routineAsync = ref.watch(userRoutineProvider);
      return routineAsync.when(
        loading: () => _buildLoadingScaffold(localizations),
        error: (e, _) => _buildErrorScaffold(e, localizations),
        data: (routineData) {
          // Data is ready — schedule hydration for the next frame.
          // addPostFrameCallback is used here because calling setState during
          // build is illegal. The _hydratedFromApi guard prevents multiple
          // callbacks from racing if the provider rebuilds before the frame
          // fires (e.g., a quick re-watch before hydration completes).
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _hydratedFromApi) return;
            _EditableBlock? injectedRecitationBlock;
            _EditableBlock? injectedTimerBlock;
            _EditableBlock? injectedSeriesBlock;
            _EditableBlock? injectedAccumulatorBlock;
            _EditableBlock? injectedCollectionBlock;
            _EditableBlock? injectedMyCollectionBlock;
            _EditableBlock? injectedGroupAccumulatorBlock;
            var collectionAlreadyInRoutine = false;
            var myCollectionAlreadyInRoutine = false;
            var groupAccumulatorAlreadyInRoutine = false;
            setState(() {
              _hydratedFromApi = true;
              _applyInitialData(routineData);
              if (widget.initialPlan != null) {
                _injectInitialPlan(widget.initialPlan!);
              }
              if (widget.initialRecitation != null) {
                injectedRecitationBlock = _injectInitialRecitation(
                  widget.initialRecitation!,
                );
              }
              if (widget.initialTimer != null) {
                injectedTimerBlock = _injectInitialTimer(widget.initialTimer!);
              }
              if (widget.initialSeries != null) {
                injectedSeriesBlock = _injectInitialSeries(
                  widget.initialSeries!,
                );
              }
              if (widget.initialMantra != null) {
                injectedAccumulatorBlock = _injectInitialAccumulator(
                  widget.initialMantra!,
                );
              }
              if (widget.initialGroupCollection != null) {
                injectedCollectionBlock = _injectInitialGroupCollection(
                  widget.initialGroupCollection!,
                );
                collectionAlreadyInRoutine = injectedCollectionBlock == null;
              }
              if (widget.initialMyCollection != null) {
                injectedMyCollectionBlock = _injectInitialMyCollection(
                  widget.initialMyCollection!,
                );
                myCollectionAlreadyInRoutine =
                    injectedMyCollectionBlock == null;
              }
              if (widget.initialGroupAccumulator != null) {
                injectedGroupAccumulatorBlock = _injectInitialGroupAccumulator(
                  widget.initialGroupAccumulator!,
                );
                groupAccumulatorAlreadyInRoutine =
                    injectedGroupAccumulatorBlock == null;
              }
            });
            if (widget.initialPlan != null) {
              _syncInjectedPlan(widget.initialPlan!);
            }
            if (injectedRecitationBlock != null) {
              _syncBlock(injectedRecitationBlock!).catchError((e) {
                if (mounted) _showErrorSnackBar(_mapError(e));
              });
            }
            if (injectedTimerBlock != null) {
              _syncBlock(injectedTimerBlock!).catchError((e) {
                if (mounted) _showErrorSnackBar(_mapError(e));
              });
            }
            if (injectedSeriesBlock != null) {
              _syncBlock(injectedSeriesBlock!)
                  .then((_) {
                    if (mounted) _refreshPracticeEnrollments();
                  })
                  .catchError((e) {
                    if (mounted) _showErrorSnackBar(_mapError(e));
                  });
            }
            if (injectedAccumulatorBlock != null) {
              _syncBlock(injectedAccumulatorBlock!).catchError((e) {
                if (mounted) _showErrorSnackBar(_mapError(e));
              });
            }
            if (injectedCollectionBlock != null) {
              _syncBlock(injectedCollectionBlock!).catchError((e) {
                if (mounted) _showErrorSnackBar(_mapError(e));
              });
            } else if (collectionAlreadyInRoutine) {
              _showCollectionAlreadyAddedSnackBar();
            }
            if (injectedMyCollectionBlock != null) {
              _syncBlock(injectedMyCollectionBlock!).catchError((e) {
                if (mounted) _showErrorSnackBar(_mapError(e));
              });
            } else if (myCollectionAlreadyInRoutine) {
              _showCollectionAlreadyAddedSnackBar();
            }
            if (injectedGroupAccumulatorBlock != null) {
              _syncBlock(injectedGroupAccumulatorBlock!).catchError((e) {
                if (mounted) _showErrorSnackBar(_mapError(e));
              });
            } else if (groupAccumulatorAlreadyInRoutine) {
              _showGroupAccumulatorAlreadyAddedSnackBar();
            }
            if (widget.enrollSeriesId != null && !_seriesEnrollmentHydrated) {
              _seriesEnrollmentHydrated = true;
              _hydrateSeriesEnrollment(widget.enrollSeriesId!);
            }
          });
          return _buildLoadingScaffold(localizations);
        },
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _DoneButton(
                  onTap: _saveAndPop,
                  isDark: isDark,
                  label: localizations.done,
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.routine_edit_title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    itemCount: _calculateListItemCount(),
                    separatorBuilder: (_, index) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1),
                      );
                    },
                    itemBuilder: (context, index) {
                      if (_shouldShowAddButton && index == _blocks.length) {
                        return _AddBlockButton(
                          onTap: _addBlock,
                          isDark: isDark,
                        );
                      }
                      final block = _blocks[index];
                      return RoutineTimeBlock(
                        key: ValueKey(block.id),
                        time: block.time,
                        title: block.title,
                        notificationEnabled: block.notificationEnabled,
                        items: block.items,
                        onTimeChanged: () => _pickTime(index),
                        onTitleChanged: (raw) => _onTitleChanged(block, raw),
                        onTitleEditingDone: () => _syncTitleIfChanged(block),
                        onNotificationToggle: () => _toggleNotification(index),
                        onDelete: () => _deleteBlock(index),
                        onAddSession: () => _navigateToSelectSession(index),
                        onReorderItems:
                            (oldIdx, newIdx) =>
                                _onReorderItems(index, oldIdx, newIdx),
                        onDeleteItem:
                            (itemIdx) => _onDeleteItem(index, itemIdx),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScaffold(AppLocalizations localizations) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  localizations.routine_edit_title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScaffold(Object e, AppLocalizations localizations) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$e', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(userRoutineProvider),
                    child: Text(localizations.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Private widgets ───

class _DoneButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;
  final String label;

  const _DoneButton({
    required this.onTap,
    required this.isDark,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddBlockButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _AddBlockButton({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: 16,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                context.l10n.routine_add_block_label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
