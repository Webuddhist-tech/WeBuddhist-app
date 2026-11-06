import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/core.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/calendar/domain/models/personal_calendar_event.dart';
import 'package:flutter_pecha/features/calendar/presentation/calendar_l10n_utils.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/calendar_event_sources_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Adds a personal event on [date], or edits [event]. The delete confirmation
/// swaps in place, so Cancel returns to an unchanged form.
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
  bool _confirmingDelete = false;
  bool _busy = false;
  bool _failed = false;

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
    Future<Object?> Function() action, {
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
              ? _controller.add(title: title, startDate: widget.date)
              : _controller.edit(event.id, title: title),
      deleted: false,
    );
  }

  void _delete() {
    _submit(() => _controller.delete(widget.event!.id), deleted: true);
  }

  void _setConfirming(bool value) => setState(() {
    _failed = false;
    _confirmingDelete = value;
  });

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
    return _confirmingDelete && event != null
        ? _buildConfirmDelete(context, event)
        : _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final event = widget.event;

    return GroupEventSheet(
      title: DateFormat(
        'EEE d MMM',
        dateFormatLocale(context),
      ).format(widget.date),
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
            _OutlineButton(
              label: l10n.calendar_delete_event,
              color: AppColors.error,
              onPressed: _busy ? null : () => _setConfirming(true),
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
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
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
    return GroupEventSheet(
      title: l10n.calendar_delete_event_title,
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
          _OutlineButton(
            label: l10n.cancel,
            color: Theme.of(context).colorScheme.onSurface,
            onPressed: _busy ? null : () => _setConfirming(false),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Text(l10n.calendar_delete_event_body(event.title)),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
          shape: const StadiumBorder(),
        ),
        child: Text(label),
      ),
    );
  }
}
