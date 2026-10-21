import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/localization/languages_providers.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_segmented_control.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_event_composer_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_event_in_person_counts_provider.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/screens/group_event_composer_screen.dart';
import 'package:flutter_pecha/features/group_profile/presentation/screens/group_event_in_person_counts_screen.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_draft_mapper.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_draft_summary.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_review_step.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Admin view of an event: its details, each row opening the composer on
/// that step, and its accumulations with the in-person counts to record.
class GroupEventManageScreen extends ConsumerStatefulWidget {
  final GroupEvent event;

  const GroupEventManageScreen({super.key, required this.event});

  static Future<void> show(BuildContext context, {required GroupEvent event}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'group-event-manage'),
        builder: (_) => GroupEventManageScreen(event: event),
      ),
    );
  }

  @override
  ConsumerState<GroupEventManageScreen> createState() =>
      _GroupEventManageScreenState();
}

class _GroupEventManageScreenState
    extends ConsumerState<GroupEventManageScreen> {
  int _tab = 0;
  bool _isOpeningComposer = false;

  String get _groupId => widget.event.groupId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.scaffoldBackgroundDark : AppColors.surfaceLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: SizedBox(
                height: kMinInteractiveDimension,
                child: NavigationToolbar(
                  leading: IconButton(
                    icon: Icon(AppAssets.arrowLeft, color: secondaryColor),
                    tooltip: l10n.back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  middle: Text(
                    l10n.group_event_manage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: ConnectSegmentedControl(
                segments: [
                  l10n.group_event_manage_details,
                  l10n.group_event_manage_counts,
                ],
                selectedIndex: _tab,
                onChanged: (index) => setState(() => _tab = index),
              ),
            ),
            Expanded(
              child:
                  _tab == 0
                      ? _buildDetails(context, isDark)
                      : _buildCounts(context, isDark),
            ),
          ],
        ),
      ),
    );
  }

  // ── Details ────────────────────────────────────────────────────────────

  Widget _buildDetails(BuildContext context, bool isDark) {
    final itemsAsync = ref.watch(groupCmsEventsProvider(_groupId));
    void retry() => ref.invalidate(groupCmsEventsProvider(_groupId));

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorStateWidget(error: error, onRetry: retry),
      data: (items) {
        final item =
            items.where((item) => item.event.id == widget.event.id).firstOrNull;
        if (item == null) {
          return Center(child: Text(context.l10n.notFound));
        }
        return _DetailsList(
          source: GroupEventDraftMapper.fromJson(item.raw),
          isDark: isDark,
          onEdit: _isOpeningComposer ? null : _edit,
        );
      },
    );
  }

  /// Opens the composer on [step] with the event filled in; a saved edit
  /// refreshes every list that shows it.
  Future<void> _edit(GroupEventEditSource source, int step) async {
    final l10n = context.l10n;
    setState(() => _isOpeningComposer = true);
    try {
      final profileEither = await ref.read(
        groupProfileProvider(_groupId).future,
      );
      if (!mounted) return;
      final profile = profileEither.fold((_) => null, (profile) => profile);
      if (profile == null) {
        _showError(l10n.group_event_publish_error);
        return;
      }
      final result = await GroupEventComposerScreen.show(
        context,
        profile,
        existing: source,
        initialStep: step,
      );
      if (result == null || !mounted) return;
      ref.invalidate(groupCmsEventsProvider(_groupId));
      ref.invalidate(groupEventsProvider(_groupId));
      ref.invalidate(groupEventDetailProvider(widget.event.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.group_event_changes_saved)));
    } finally {
      if (mounted) setState(() => _isOpeningComposer = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ── Counts ─────────────────────────────────────────────────────────────

  Widget _buildCounts(BuildContext context, bool isDark) {
    final l10n = context.l10n;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    // The latest copy carries counts changed since the page was opened.
    final event =
        ref
            .watch(groupEventDetailProvider(widget.event.id))
            .valueOrNull
            ?.fold((_) => null, (event) => event) ??
        widget.event;
    final accumulations = [...event.allAccumulations]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        GroupEventSectionLabel(
          l10n.group_event_manage_accumulations,
          isDark: isDark,
        ),
        if (accumulations.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              l10n.group_event_manage_no_accumulations,
              style: TextStyle(fontSize: 14, color: secondaryColor),
            ),
          ),
        for (final accumulation in accumulations)
          accumulation.isAdminCounted
              ? _AdminCountedRow(
                eventId: event.id,
                accumulation: accumulation,
                isDark: isDark,
                onAddCount:
                    () => GroupEventInPersonCountsScreen.show(
                      context,
                      eventId: event.id,
                      accumulation: accumulation,
                    ),
              )
              : _AttendeeCountedRow(accumulation: accumulation, isDark: isDark),
        if (event.isRecurring)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              l10n.group_event_manage_recurring_note,
              style: TextStyle(fontSize: 13, color: secondaryColor),
            ),
          ),
      ],
    );
  }
}

class _DetailsList extends ConsumerWidget {
  final GroupEventEditSource source;
  final bool isDark;
  final void Function(GroupEventEditSource source, int step)? onEdit;

  const _DetailsList({
    required this.source,
    required this.isDark,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = intlFormatLocaleOf(context);
    final languages = ref.watch(resolvedContentLanguagesProvider);
    final draft = source.draft;
    final name = GroupEventDraftSummary.eventName(draft);
    void edit(int step) => onEdit?.call(source, step);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (draft.cover != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: GroupEventCoverImage(cover: draft.cover!, isDark: isDark),
            ),
          GroupEventSectionLabel(l10n.group_event_review_event, isDark: isDark),
          GroupEventReviewRow(
            icon: AppAssets.list,
            label: l10n.group_event_review_name,
            value: name.isEmpty ? l10n.group_event_review_none : name,
            onTap: () => edit(0),
          ),
          GroupEventReviewRow(
            icon: AppAssets.translate,
            label: l10n.group_event_review_languages,
            value: GroupEventDraftSummary.languageNames(draft, languages),
            onTap: () => edit(0),
          ),
          GroupEventReviewRow(
            icon: AppAssets.calendarBlank,
            label: l10n.group_event_review_when,
            value: GroupEventDraftSummary.when(draft, l10n, locale),
            onTap: () => edit(1),
          ),
          GroupEventReviewRow(
            icon: AppAssets.mapPin,
            label: l10n.group_event_review_where,
            value: GroupEventDraftSummary.where(draft, l10n),
            onTap: () => edit(1),
          ),
          if (draft.format.needsLink)
            GroupEventReviewRow(
              icon: AppAssets.monitorPlay,
              label: l10n.group_event_review_live_link,
              value: GroupEventDraftSummary.liveLink(draft, l10n),
              onTap: () => edit(1),
            ),
          GroupEventSectionLabel(
            l10n.group_event_step_practices,
            isDark: isDark,
          ),
          GroupEventReviewRow(
            icon: AppAssets.list,
            label: l10n.group_event_review_practices,
            value: GroupEventDraftSummary.practices(draft, l10n),
            onTap: () => edit(2),
          ),
          GroupEventReviewRow(
            icon: AppAssets.monitorPlay,
            label: l10n.group_event_review_videos,
            value: GroupEventDraftSummary.videos(draft, l10n),
            onTap: () => edit(2),
          ),
          GroupEventSectionLabel(
            l10n.group_event_review_settings,
            isDark: isDark,
          ),
          GroupEventReviewRow(
            icon: AppAssets.sliders,
            label: l10n.group_event_review_event_settings,
            value: GroupEventDraftSummary.settings(draft, l10n),
            onTap: () => edit(3),
          ),
        ],
      ),
    );
  }
}

/// An accumulation the admin counts for: how much is recorded, and the way in.
class _AdminCountedRow extends ConsumerWidget {
  final String eventId;
  final GroupEventAccumulation accumulation;
  final bool isDark;
  final VoidCallback onAddCount;

  const _AdminCountedRow({
    required this.eventId,
    required this.accumulation,
    required this.isDark,
    required this.onAddCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(
      groupEventInPersonCountsProvider((
        eventId: eventId,
        eventAccumulationId: accumulation.id,
      )),
    );
    final total = state.summary?.totalCount;
    final numberFormat = NumberFormat.decimalPattern(
      intlFormatLocaleOf(context),
    );
    return _AccumulationRow(
      title: accumulation.title,
      subtitle:
          total == null
              ? l10n.group_event_manage_admin_adds_pending
              : l10n.group_event_manage_admin_adds(numberFormat.format(total)),
      isDark: isDark,
      trailing: TextButton(
        onPressed: onAddCount,
        style: TextButton.styleFrom(
          foregroundColor:
              isDark ? AppColors.accentGold : AppColors.accentGoldDarkest,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Text(
          l10n.group_event_manage_add_count,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// An accumulation attendees log in the app: its total and who added to it.
class _AttendeeCountedRow extends ConsumerWidget {
  final GroupEventAccumulation accumulation;
  final bool isDark;

  const _AttendeeCountedRow({required this.accumulation, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref
        .watch(groupAccumulatorDetailProvider(accumulation.groupAccumulatorId))
        .valueOrNull
        ?.fold((_) => null, (detail) => detail);
    final numberFormat = NumberFormat.decimalPattern(
      intlFormatLocaleOf(context),
    );
    return _AccumulationRow(
      title:
          accumulation.title.isNotEmpty
              ? accumulation.title
              : detail?.title ?? '',
      subtitle:
          detail == null
              ? l10n.group_event_manage_attendees_add_pending
              : l10n.group_event_manage_attendees_add(
                numberFormat.format(detail.totalCount),
                detail.memberCount,
              ),
      isDark: isDark,
    );
  }
}

class _AccumulationRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;
  final Widget? trailing;

  const _AccumulationRow({
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: secondaryColor),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}
