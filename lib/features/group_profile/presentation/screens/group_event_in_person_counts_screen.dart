import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/destructive_confirmation_dialog.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_in_person_count.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_event_in_person_counts_provider.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_request_builder.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// The counts made at an event in person, one per day, that an admin adds to
/// the linked group accumulation: the studio's "Add count" panel on a phone.
class GroupEventInPersonCountsScreen extends ConsumerStatefulWidget {
  final String eventId;
  final GroupEventAccumulation accumulation;

  const GroupEventInPersonCountsScreen({
    super.key,
    required this.eventId,
    required this.accumulation,
  });

  static Future<void> show(
    BuildContext context, {
    required String eventId,
    required GroupEventAccumulation accumulation,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'group-event-in-person-counts'),
        builder:
            (_) => GroupEventInPersonCountsScreen(
              eventId: eventId,
              accumulation: accumulation,
            ),
      ),
    );
  }

  @override
  ConsumerState<GroupEventInPersonCountsScreen> createState() =>
      _GroupEventInPersonCountsScreenState();
}

/// The row being added (no id) or edited.
class _Draft {
  final String? id;
  final DateTime day;
  final String count;

  const _Draft({this.id, required this.day, this.count = ''});

  _Draft copyWith({DateTime? day, String? count}) =>
      _Draft(id: id, day: day ?? this.day, count: count ?? this.count);
}

class _GroupEventInPersonCountsScreenState
    extends ConsumerState<GroupEventInPersonCountsScreen> {
  _Draft? _draft;
  final _countController = TextEditingController();

  GroupEventInPersonCountsKey get _key => (
    eventId: widget.eventId,
    eventAccumulationId: widget.accumulation.id,
  );

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final state = ref.watch(groupEventInPersonCountsProvider(_key));
    final title = widget.accumulation.title;

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
                    title.isEmpty
                        ? l10n.group_event_manage_add_count
                        : '${l10n.group_event_manage_add_count} · $title',
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
            Expanded(child: _buildBody(context, state, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    GroupEventInPersonCountsState state,
    bool isDark,
  ) {
    final l10n = context.l10n;
    final summary = state.summary;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    if (summary == null) {
      final error = state.error;
      if (error != null && !state.isLoading) {
        return ErrorStateWidget(
          error: error,
          onRetry:
              () =>
                  ref
                      .read(groupEventInPersonCountsProvider(_key).notifier)
                      .loadInitial(),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    if (summary.groupAccumulatorId == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          l10n.group_event_in_person_no_accumulation,
          style: TextStyle(fontSize: 14, color: secondaryColor),
        ),
      );
    }

    final draft = _draft;
    final today = GroupEventRequestBuilder.todayIn(summary.timezone);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        _AccumulationCard(
          summary: summary,
          fallbackTitle: widget.accumulation.title,
          fallbackImageUrl: widget.accumulation.groupAccumulator?.imageUrl,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed:
                draft?.id == null && draft != null
                    ? null
                    : () => _startDraft(today),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              side: BorderSide(
                color: isDark ? AppColors.grey800 : AppColors.grey400,
              ),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(AppAssets.plus, size: 18),
            label: Text(l10n.group_event_in_person_add_day),
          ),
        ),
        const SizedBox(height: 12),
        if (draft != null && draft.id == null)
          _DraftCard(
            draft: draft,
            maxDay: today,
            controller: _countController,
            pending: state.isSaving,
            isDark: isDark,
            onPickDay: () => _pickDay(draft, today),
            onSave: _save,
            onCancel: _cancelDraft,
          ),
        if (state.items.isEmpty && draft == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l10n.group_event_in_person_empty,
              style: TextStyle(fontSize: 14, color: secondaryColor),
            ),
          ),
        for (final item in state.items)
          draft != null && draft.id == item.id
              ? _DraftCard(
                draft: draft,
                maxDay: today,
                controller: _countController,
                pending: state.isSaving,
                isDark: isDark,
                onPickDay: () => _pickDay(draft, today),
                onSave: _save,
                onCancel: _cancelDraft,
              )
              : _CountRow(
                item: item,
                isDark: isDark,
                enabled: !state.isSaving,
                onEdit: () => _editItem(item),
                onDelete: () => _confirmDelete(item),
              ),
        if (state.hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child:
                  state.isLoadingMore
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : TextButton(
                        onPressed:
                            () =>
                                ref
                                    .read(
                                      groupEventInPersonCountsProvider(
                                        _key,
                                      ).notifier,
                                    )
                                    .loadMore(),
                        child: Text(l10n.group_event_in_person_load_more),
                      ),
            ),
          ),
      ],
    );
  }

  // ── Draft handling ─────────────────────────────────────────────────────

  void _startDraft(DateTime today) {
    _countController.text = '';
    setState(() => _draft = _Draft(day: today));
  }

  void _editItem(GroupEventInPersonCount item) {
    _countController.text = item.count.toString();
    setState(
      () =>
          _draft = _Draft(id: item.id, day: item.date, count: '${item.count}'),
    );
  }

  void _cancelDraft() {
    _countController.text = '';
    setState(() => _draft = null);
  }

  Future<void> _pickDay(_Draft draft, DateTime maxDay) async {
    final picked = await _DaySheet.show(
      context,
      initial: draft.day.isAfter(maxDay) ? maxDay : draft.day,
      maxDay: maxDay,
    );
    if (picked == null || !mounted) return;
    setState(() => _draft = draft.copyWith(day: picked));
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    final l10n = context.l10n;
    final count = int.tryParse(_countController.text.trim());
    if (count == null || count < 1) {
      _showError(l10n.group_event_in_person_invalid_count);
      return;
    }
    final failure = await ref
        .read(groupEventInPersonCountsProvider(_key).notifier)
        .save(
          countId: draft.id,
          day: DateFormat('yyyy-MM-dd').format(draft.day),
          count: count,
        );
    if (!mounted) return;
    if (failure != null) {
      _showError(_failureMessage(l10n, failure));
      return;
    }
    _cancelDraft();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          draft.id == null
              ? l10n.group_event_in_person_added
              : l10n.group_event_in_person_updated,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(GroupEventInPersonCount item) async {
    final l10n = context.l10n;
    final locale = intlFormatLocaleOf(context);
    Failure? failure;
    final deleted = await showDestructiveConfirmationDialog(
      context,
      title: l10n.group_event_in_person_delete_title,
      message: l10n.group_event_in_person_delete_message(
        NumberFormat.decimalPattern(locale).format(item.count),
        DateFormat('EEE, d MMM yyyy', locale).format(item.date),
      ),
      confirmLabel: l10n.delete,
      onConfirmed: () async {
        failure = await ref
            .read(groupEventInPersonCountsProvider(_key).notifier)
            .remove(item.id);
        return failure == null;
      },
    );
    if (!mounted || deleted == null) return;
    if (deleted) {
      if (_draft?.id == item.id) _cancelDraft();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.group_event_in_person_deleted)),
      );
    } else if (failure != null) {
      _showError(_failureMessage(l10n, failure!));
    }
  }

  /// The API names the reason in `detail`; the rest reads as it came.
  static String _failureMessage(AppLocalizations l10n, Failure failure) {
    return switch (failure.message) {
      'IN_PERSON_COUNT_EXISTS' => l10n.group_event_in_person_exists,
      'EVENT_HAS_NO_GROUP_ACCUMULATOR' ||
      'NO_MANUAL_EVENT_ACCUMULATION' ||
      'EVENT_ACCUMULATION_ID_REQUIRED' =>
        l10n.group_event_in_person_no_accumulation,
      final message when message.isNotEmpty => message,
      _ => l10n.group_event_in_person_save_error,
    };
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────

/// The linked accumulation and how far along it is, app and in-person apart.
class _AccumulationCard extends StatelessWidget {
  final GroupEventInPersonCountList summary;
  final String fallbackTitle;
  final String? fallbackImageUrl;
  final bool isDark;

  const _AccumulationCard({
    required this.summary,
    required this.fallbackTitle,
    required this.fallbackImageUrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final numberFormat = NumberFormat.decimalPattern(
      intlFormatLocaleOf(context),
    );
    final primaryColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final trackColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final title =
        (summary.groupAccumulatorTitle ?? '').trim().isNotEmpty
            ? summary.groupAccumulatorTitle!.trim()
            : fallbackTitle;
    final imageUrl =
        summary.groupAccumulatorImage?.displayUrl ?? fallbackImageUrl;
    final total = summary.groupAccumulatorTotalCount;
    final inPerson = summary.totalCount;
    final app = summary.appCount;
    final target = summary.groupAccumulatorTargetCount;
    // Without a target the bar shows the in-person share of the total.
    final scale =
        target != null && target > 0 ? target : ((total ?? 0) < 1 ? 1 : total!);
    final percent =
        target != null && target > 0 && total != null
            ? total / target * 100
            : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.grey300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child:
                      imageUrl == null || imageUrl.isEmpty
                          ? ColoredBox(color: trackColor)
                          : CachedNetworkImageWidget(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: ColoredBox(color: trackColor),
                          ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          if (total != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    target != null && target > 0
                        ? l10n.group_event_in_person_of_target(
                          numberFormat.format(total),
                          numberFormat.format(target),
                        )
                        : l10n.group_event_in_person_in_total(
                          numberFormat.format(total),
                        ),
                    style: TextStyle(fontSize: 13, color: secondaryColor),
                  ),
                ),
                if (percent != null)
                  Text(
                    percent < 0.1 && total > 0
                        ? '<0.1%'
                        : '${percent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    _Segment(
                      value: app,
                      scale: scale,
                      color: AppColors.primary,
                    ),
                    _Segment(
                      value: inPerson,
                      scale: scale,
                      color: AppColors.warning,
                    ),
                    Expanded(flex: 1000, child: ColoredBox(color: trackColor)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _Legend(
                  color: AppColors.primary,
                  label: l10n.group_event_in_person_legend_app,
                  value: numberFormat.format(app),
                  isDark: isDark,
                ),
                _Legend(
                  color: AppColors.warning,
                  label: l10n.group_event_in_person_legend_in_person,
                  value: numberFormat.format(inPerson),
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A bar segment sized as its share of [scale], kept visible when non-zero.
class _Segment extends StatelessWidget {
  final int value;
  final int scale;
  final Color color;

  const _Segment({
    required this.value,
    required this.scale,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (value <= 0) return const SizedBox.shrink();
    final share = (value / scale * 1000).clamp(8, 1000).round();
    return Expanded(flex: share, child: ColoredBox(color: color));
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final bool isDark;

  const _Legend({
    required this.color,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: secondaryColor)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
      ],
    );
  }
}

/// Day and count being entered, with save and cancel.
class _DraftCard extends StatelessWidget {
  final _Draft draft;
  final DateTime maxDay;
  final TextEditingController controller;
  final bool pending;
  final bool isDark;
  final VoidCallback onPickDay;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _DraftCard({
    required this.draft,
    required this.maxDay,
    required this.controller,
    required this.pending,
    required this.isDark,
    required this.onPickDay,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = intlFormatLocaleOf(context);
    final primaryColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.grey800 : AppColors.grey400;
    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: secondaryColor,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.group_event_in_person_day, style: labelStyle),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: pending ? null : onPickDay,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                DateFormat(
                                  'd MMM yyyy',
                                  locale,
                                ).format(draft.day),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            Icon(
                              AppAssets.calendarBlank,
                              size: 18,
                              color: secondaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.group_event_in_person_count, style: labelStyle),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 44,
                      child: TextField(
                        controller: controller,
                        enabled: !pending,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => onSave(),
                        style: TextStyle(fontSize: 15, color: primaryColor),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: pending ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
                  foregroundColor:
                      isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child:
                    pending
                        ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                isDark
                                    ? AppColors.textPrimary
                                    : AppColors.surfaceWhite,
                          ),
                        )
                        : Text(l10n.save),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: pending ? null : onCancel,
                style: TextButton.styleFrom(foregroundColor: secondaryColor),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  final GroupEventInPersonCount item;
  final bool isDark;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CountRow({
    required this.item,
    required this.isDark,
    required this.enabled,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = intlFormatLocaleOf(context);
    final primaryColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.grey300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              DateFormat('EEE, d MMM yyyy', locale).format(item.date),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: primaryColor,
              ),
            ),
          ),
          Text(
            NumberFormat.decimalPattern(locale).format(item.count),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: l10n.edit,
            onPressed: enabled ? onEdit : null,
            icon: Icon(AppAssets.pencilSimple, size: 20, color: secondaryColor),
          ),
          IconButton(
            tooltip: l10n.delete,
            onPressed: enabled ? onDelete : null,
            icon: const Icon(
              AppAssets.trash,
              size: 20,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wheel picker for the day a count was made, never after today.
class _DaySheet extends StatefulWidget {
  final DateTime initial;
  final DateTime maxDay;

  const _DaySheet({required this.initial, required this.maxDay});

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initial,
    required DateTime maxDay,
  }) {
    return GroupEventSheet.show<DateTime>(
      context,
      builder: (_) => _DaySheet(initial: initial, maxDay: maxDay),
    );
  }

  @override
  State<_DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends State<_DaySheet> {
  late DateTime _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GroupEventSheet(
      title: l10n.group_event_in_person_day,
      footer: GroupEventSheet.primaryButton(
        context,
        label: l10n.done,
        onPressed: () => Navigator.of(context).pop(_value),
      ),
      child: SizedBox(
        height: 216,
        child: CupertinoTheme(
          data: CupertinoThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
          ),
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: widget.initial,
            maximumDate: widget.maxDay,
            onDateTimeChanged:
                (dt) => _value = DateTime(dt.year, dt.month, dt.day),
          ),
        ),
      ),
    );
  }
}
