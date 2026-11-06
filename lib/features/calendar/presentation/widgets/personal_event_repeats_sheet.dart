import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/calendar/domain/models/personal_calendar_event.dart';
import 'package:flutter_pecha/features/calendar/presentation/calendar_l10n_utils.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/calendar_event_sources_providers.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_repeats_sheet.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// The rule wording shared with space events, e.g. "Weekly on Friday".
String _optionLabel(
  PersonalRepeatOption option,
  DateTime firstDate,
  AppLocalizations l10n,
  String locale,
) {
  final repeat = option.repeat;
  final rule = GroupEventRecurrenceDraft(
    frequency: switch (repeat) {
      PersonalRepeat.monthlyGregorian ||
      PersonalRepeat.monthlyLunar => GroupEventRecurrenceFrequency.monthly,
      PersonalRepeat.yearlyGregorian ||
      PersonalRepeat.yearlyLunar => GroupEventRecurrenceFrequency.yearly,
      _ => GroupEventRecurrenceFrequency.weekly,
    },
    dateSystem:
        _isLunar(repeat)
            ? GroupEventDateSystem.tibetanLunar
            : GroupEventDateSystem.gregorian,
    day: option.day,
    month: option.month,
    dayOfWeek: option.dayOfWeek,
  );
  return recurrenceRuleLabel(rule, firstDate, l10n, locale);
}

bool _isLunar(PersonalRepeat repeat) =>
    repeat == PersonalRepeat.monthlyLunar ||
    repeat == PersonalRepeat.yearlyLunar;

/// Lists the repeat options the server works out from the first date. Pops the
/// chosen [PersonalRepeatOption]; null means it was dismissed.
class PersonalEventRepeatsSheet extends ConsumerWidget {
  const PersonalEventRepeatsSheet({
    super.key,
    required this.firstDate,
    required this.selected,
  });

  final DateTime firstDate;
  final PersonalRepeat selected;

  static Future<PersonalRepeatOption?> show(
    BuildContext context, {
    required DateTime firstDate,
    required PersonalRepeat selected,
  }) {
    return GroupEventSheet.show<PersonalRepeatOption>(
      context,
      builder:
          (_) => PersonalEventRepeatsSheet(
            firstDate: firstDate,
            selected: selected,
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final options = ref.watch(personalRepeatOptionsProvider(firstDate));
    return GroupEventSheet(
      title: l10n.group_event_repeats,
      child: options.when(
        loading:
            () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
        error:
            (_, __) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.something_went_wrong, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed:
                        () => ref.invalidate(
                          personalRepeatOptionsProvider(firstDate),
                        ),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
        data: (rows) => _buildList(context, rows),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<PersonalRepeatOption> rows) {
    final l10n = context.l10n;
    final locale = dateFormatLocale(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final activeColor = isDark ? AppColors.surfaceWhite : AppColors.textPrimary;
    final repeating = rows.where((row) => row.repeat != PersonalRepeat.none);
    final nextDates =
        repeating
            .where((row) => row.repeat == selected)
            .firstOrNull
            ?.nextDates ??
        const <DateTime>[];

    Widget option(PersonalRepeatOption row, String title, String? subtitle) {
      final isSelected = row.repeat == selected;
      return InkWell(
        onTap: () => Navigator.of(context).pop(row),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, color: secondaryColor),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? activeColor : AppColors.grey400,
                    width: isSelected ? 6 : 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      children: [
        option(
          PersonalRepeatOption.noRepeat,
          l10n.calendar_does_not_repeat,
          null,
        ),
        Divider(height: 1, thickness: 1, color: dividerColor),
        for (final row in repeating) ...[
          option(
            row,
            _optionLabel(row, firstDate, l10n, locale),
            _isLunar(row.repeat)
                ? l10n.group_event_tibetan_lunar
                : l10n.group_event_gregorian,
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
        ],
        if (nextDates.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.group_event_next_dates,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nextDates
                      .map((d) => DateFormat('EEE d MMM', locale).format(d))
                      .join(' · '),
                  style: TextStyle(fontSize: 13, color: secondaryColor),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Text(
            l10n.group_event_repeats_hint,
            style: TextStyle(fontSize: 12, color: secondaryColor),
          ),
        ),
      ],
    );
  }
}
