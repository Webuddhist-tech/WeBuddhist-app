import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/core.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/calendar/domain/models/personal_calendar_event.dart';
import 'package:flutter_pecha/features/calendar/presentation/calendar_l10n_utils.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/calendar_event_sources_providers.dart';
import 'package:flutter_pecha/features/calendar/presentation/widgets/personal_event_repeats_sheet.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum _Step { form, confirmDelete }

/// Adds a personal event on [date], or edits [event] opened from [date]. The
/// delete confirmation swaps in place, so Cancel returns to an unchanged form.
class PersonalEventSheet extends ConsumerStatefulWidget {
  const PersonalEventSheet({super.key, required this.date, this.event});

  final DateTime date;
  final PersonalCalendarEvent? event;

  /// Completes with true when the event was deleted.
  static Future<bool?> show(
    BuildContext context, {
    required DateTime date,
    PersonalCalendarEvent? event,
  }) {
    return GroupEventSheet.show<bool>(
      context,
      builder: (_) => PersonalEventSheet(date: date, event: event),
    );
  }

  @override
  ConsumerState<PersonalEventSheet> createState() => _PersonalEventSheetState();
}

class _PersonalEventSheetState extends ConsumerState<PersonalEventSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.event?.title,
  );
  late PersonalRepeat _repeat = widget.event?.repeat ?? PersonalRepeat.none;
  late int? _repeatDay = widget.event?.day;
  bool _busy = false;
  bool _failed = false;
  _Step _step = _Step.form;

  /// Repeat options always come from the event's first date.
  DateTime get _firstDate => widget.event?.startDate ?? widget.date;

  bool get _canSave => !_busy && _name.text.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  PersonalCalendarController get _controller =>
      ref.read(personalCalendarControllerProvider);

  /// Runs [action], keeping the sheet open with a message if it fails.
  Future<void> _submit(
    Future<Failure?> Function() action, {
    required bool deleted,
  }) async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    final failure = await action();
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(deleted);
    } else {
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  void _save() {
    final title = _name.text.trim();
    final event = widget.event;
    _submit(
      () =>
          event == null
              ? _controller.add(
                title: title,
                startDate: _firstDate,
                repeat: _repeat,
              )
              : _controller.edit(event, title: title, repeat: _repeat),
      deleted: false,
    );
  }

  /// Deletes the whole event. For a repeating one that is every date: the API
  /// has no way to remove a single date.
  void _delete() {
    final event = widget.event!;
    _submit(() => _controller.delete(event.id), deleted: true);
  }

  Future<void> _pickRepeat() async {
    final choice = await PersonalEventRepeatsSheet.show(
      context,
      firstDate: _firstDate,
      selected: _repeat,
    );
    if (choice != null && mounted) {
      setState(() {
        _repeat = choice.repeat;
        _repeatDay = choice.day;
      });
    }
  }

  /// Shown above a sheet's buttons after a failed save or delete.
  Widget _errorMessage(BuildContext context) {
    if (!_failed) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        context.l10n.something_went_wrong,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    if (_step == _Step.confirmDelete && event != null) {
      return _buildConfirmDelete(context, event);
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = dateFormatLocale(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final event = widget.event;

    return GroupEventSheet(
      title: DateFormat('EEE d MMM', locale).format(widget.date),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _errorMessage(context),
          GroupEventSheet.primaryButton(
            context,
            label: l10n.save,
            onPressed: _canSave ? _save : null,
          ),
          if (event != null) ...[
            const SizedBox(height: 12),
            _DangerOutlineButton(
              label: l10n.calendar_delete_event,
              onPressed:
                  _busy
                      ? null
                      : () => setState(() {
                        _failed = false;
                        _step = _Step.confirmDelete;
                      }),
            ),
          ],
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.calendar_event_name,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _name,
              autofocus: event == null,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.calendar_event_name_hint,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickRepeat,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.calendar_repeat,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            calendarRepeatLabel(
                                  l10n,
                                  _repeat,
                                  _repeatDay,
                                  locale,
                                ) ??
                                l10n.calendar_does_not_repeat,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Icon(AppAssets.caretRight, size: 20, color: muted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmDelete(
    BuildContext context,
    PersonalCalendarEvent event,
  ) {
    final l10n = context.l10n;
    final repeat = calendarRepeatLabel(
      l10n,
      event.repeat,
      event.day,
      dateFormatLocale(context),
    );
    return GroupEventSheet(
      title:
          repeat != null
              ? l10n.calendar_delete_repeating_title
              : l10n.calendar_delete_event_title,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _errorMessage(context),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _busy ? null : _delete,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.surfaceWhite,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: Text(l10n.delete),
            ),
          ),
          const SizedBox(height: 12),
          _CancelButton(onPressed: _busy ? null : _backToForm),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Text(
          repeat != null
              ? l10n.calendar_delete_repeating_body(event.title, repeat)
              : l10n.calendar_delete_event_body(event.title),
        ),
      ),
    );
  }

  void _backToForm() => setState(() {
    _failed = false;
    _step = _Step.form;
  });
}

class _DangerOutlineButton extends StatelessWidget {
  const _DangerOutlineButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
          shape: const StadiumBorder(),
        ),
        child: Text(label),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.onSurface,
          side: BorderSide(color: colors.outline),
          shape: const StadiumBorder(),
        ),
        child: Text(context.l10n.cancel),
      ),
    );
  }
}
