import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/calendar/domain/tibetan_calendar_service.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/tibetan_calendar_providers.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_schedule_utils.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// "1st", "2nd", "26th"; other locales get the bare number.
String ordinalDay(int day, String locale) {
  if (!locale.toLowerCase().startsWith('en')) return '$day';
  final mod100 = day % 100;
  if (mod100 >= 11 && mod100 <= 13) return '${day}th';
  return switch (day % 10) {
    1 => '${day}st',
    2 => '${day}nd',
    3 => '${day}rd',
    _ => '${day}th',
  };
}

/// Title for a rule, e.g. "Monthly on the 15th lunar day (Full moon)".
String recurrenceRuleLabel(
  GroupEventRecurrenceDraft rule,
  DateTime firstDate,
  AppLocalizations l10n,
  String locale,
) {
  switch (rule.frequency) {
    case GroupEventRecurrenceFrequency.weekly:
      return l10n.group_event_repeats_weekly(
        DateFormat.EEEE(locale).format(firstDate),
      );
    case GroupEventRecurrenceFrequency.monthly:
      final day = rule.day ?? firstDate.day;
      if (!rule.isLunar) {
        return l10n.group_event_repeats_monthly(ordinalDay(day, locale));
      }
      final base = l10n.group_event_repeats_monthly_lunar(
        ordinalDay(day, locale),
      );
      final moon = switch (day) {
        15 => l10n.group_event_full_moon,
        30 => l10n.group_event_new_moon,
        _ => null,
      };
      return moon == null ? base : '$base ($moon)';
    case GroupEventRecurrenceFrequency.yearly:
      if (rule.isLunar) return l10n.group_event_repeats_yearly_lunar;
      return l10n.group_event_repeats_yearly(
        DateFormat.MMMMd(locale).format(firstDate),
      );
  }
}

class GroupEventRepeatsSheet extends ConsumerStatefulWidget {
  final DateTime firstDate;
  final GroupEventRecurrenceDraft? selected;

  const GroupEventRepeatsSheet({
    super.key,
    required this.firstDate,
    this.selected,
  });

  static Future<GroupEventRecurrenceDraft?> show(
    BuildContext context, {
    required DateTime firstDate,
    GroupEventRecurrenceDraft? selected,
  }) {
    return GroupEventSheet.show<GroupEventRecurrenceDraft>(
      context,
      builder:
          (_) =>
              GroupEventRepeatsSheet(firstDate: firstDate, selected: selected),
    );
  }

  @override
  ConsumerState<GroupEventRepeatsSheet> createState() =>
      _GroupEventRepeatsSheetState();
}

class _GroupEventRepeatsSheetState
    extends ConsumerState<GroupEventRepeatsSheet> {
  late final TibetanCalendarService _calendar = ref.read(
    tibetanCalendarServiceProvider,
  );
  late final List<GroupEventRecurrenceDraft> _rules =
      GroupEventScheduleUtils.rulesForDate(
        widget.firstDate,
        _calendar,
        durationDays: widget.selected?.durationDays ?? 1,
      );
  late GroupEventRecurrenceDraft? _selected = _matchSelected();

  GroupEventRecurrenceDraft? _matchSelected() {
    final selected = widget.selected;
    if (selected == null) return null;
    return _rules.where((rule) => rule.sameRule(selected)).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = intlFormatLocaleOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final activeColor = isDark ? AppColors.surfaceWhite : AppColors.textPrimary;
    final selected = _selected;
    final nextDates =
        selected == null
            ? const <DateTime>[]
            : GroupEventScheduleUtils.nextOccurrences(
              selected,
              widget.firstDate,
              _calendar,
            );

    return GroupEventSheet(
      title: l10n.group_event_repeats,
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final rule in _rules) ...[
            InkWell(
              onTap: () {
                setState(() => _selected = rule);
                Navigator.of(context).pop(rule);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recurrenceRuleLabel(
                              rule,
                              widget.firstDate,
                              l10n,
                              locale,
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rule.isLunar
                                ? l10n.group_event_tibetan_lunar
                                : l10n.group_event_gregorian,
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              selected != null && rule.sameRule(selected)
                                  ? activeColor
                                  : AppColors.grey400,
                          width:
                              selected != null && rule.sameRule(selected)
                                  ? 6
                                  : 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
      ),
    );
  }
}
