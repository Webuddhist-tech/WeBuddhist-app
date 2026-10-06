import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/timer/domain/entities/ambient_sound.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/features/timer/domain/usecases/create_user_timer_usecase.dart';
import 'package:flutter_pecha/features/timer/domain/usecases/update_user_timer_usecase.dart';
import 'package:flutter_pecha/features/timer/presentation/providers/timers_providers.dart';
import 'package:flutter_pecha/features/timer/presentation/widgets/ambient_sound_sheet.dart';
import 'package:flutter_pecha/features/timer/presentation/widgets/duration_picker_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "New timer" screen — lets the user configure and create a custom timer
/// via `POST /timers/user`.
///
/// Passing [timer] switches the screen to edit mode, which updates that timer
/// via `PUT /timers/user/{id}` instead. Only duration and ambient sound are
/// editable; the name follows the duration.
///
/// `group_id` and `parent_preset_id` are never sent (no app concept for
/// either yet). `name`/`description` have no input fields in this design, so
/// they're derived: name is "{n} minutes", description is always "".
class NewTimerScreen extends ConsumerStatefulWidget {
  const NewTimerScreen({super.key, this.timer});

  /// The user-created timer being edited, or null when creating a new one.
  final PresetTimer? timer;

  static const _defaultDurationMinutes = 20;

  @override
  ConsumerState<NewTimerScreen> createState() => _NewTimerScreenState();
}

class _NewTimerScreenState extends ConsumerState<NewTimerScreen> {
  /// What gets saved. Kept separate from [_durationMinutes] so editing a timer
  /// whose duration isn't a whole number of minutes doesn't round it down when
  /// the user only changed the ambient sound.
  late int _durationMs;
  late int _durationMinutes;
  late String? _ambientSoundId;
  String? _ambientSoundName;
  bool _isSubmitting = false;

  bool get _isEditing => widget.timer != null;

  bool get _didChangeDuration =>
      widget.timer == null || _durationMs != widget.timer!.durationMs;

  @override
  void initState() {
    super.initState();
    final timer = widget.timer;
    _durationMs =
        timer?.durationMs ?? NewTimerScreen._defaultDurationMinutes * 60000;
    _durationMinutes =
        timer == null
            ? NewTimerScreen._defaultDurationMinutes
            : (timer.durationMinutes < 1 ? 1 : timer.durationMinutes);
    _ambientSoundId = timer?.ambientSoundId;
  }

  /// The ambient sound name to display. An edited timer only carries the id,
  /// so it is resolved against the loaded sound catalog until the user picks
  /// a different sound themselves.
  String? _ambientSoundNameFrom(Map<String, AmbientSound> soundsById) {
    if (_ambientSoundName != null) return _ambientSoundName;
    final id = _ambientSoundId;
    return id == null ? null : soundsById[id]?.name;
  }

  Future<void> _pickDuration() async {
    final selected = await DurationPickerSheet.show(
      context,
      initialMinutes: _durationMinutes,
    );
    if (selected != null && mounted) {
      setState(() {
        _durationMinutes = selected;
        _durationMs = selected * 60000;
      });
    }
  }

  Future<void> _pickAmbientSound() async {
    final selection = await AmbientSoundSheet.show(
      context,
      selectedId: _ambientSoundId,
      selectedName: _ambientSoundNameFrom(ref.read(ambientSoundByIdProvider)),
    );
    if (selection != null && mounted) {
      setState(() {
        _ambientSoundId = selection.id;
        _ambientSoundName = selection.name;
      });
    }
  }

  /// The name tracks the duration, but an untouched duration keeps the stored
  /// name so a timer of e.g. 90s isn't renamed to "1 minutes" by an edit that
  /// only changed the ambient sound.
  String get _timerName =>
      _didChangeDuration ? '$_durationMinutes minutes' : widget.timer!.name;

  String _failureMessage(Failure failure) =>
      failure is ValidationFailure && _durationMs <= 0
          ? context.l10n.timer_duration_must_be_greater_than_error
          : failure.message;

  Future<PresetTimer?> _createTimer() async {
    setState(() => _isSubmitting = true);
    final useCase = ref.read(createUserTimerUseCaseProvider);
    final result = await useCase(
      CreateUserTimerParams(
        name: _timerName,
        description: '',
        durationMs: _durationMs,
        ambientSoundId: _ambientSoundId,
      ),
    );
    if (!mounted) return null;
    setState(() => _isSubmitting = false);

    return result.fold((failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_failureMessage(failure))),
      );
      return null;
    }, (timer) => timer);
  }

  Future<void> _onSave() async {
    if (_isSubmitting) return;
    final timer = await _createTimer();
    if (timer != null && mounted) context.pop();
  }

  Future<void> _onSaveChanges() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final result = await ref.read(updateUserTimerUseCaseProvider)(
      UpdateUserTimerParams(
        timerId: widget.timer!.id,
        name: _timerName,
        durationMs: _durationMs,
        ambientSoundId: _ambientSoundId,
      ),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold((failure) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_failureMessage(failure))));
    }, (_) => context.pop());
  }

  Future<void> _onBeginSession() async {
    if (_isSubmitting) return;
    final timer = await _createTimer();
    if (timer != null && mounted) {
      context.pushReplacement('/home/timers/active', extra: timer);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(ambientSoundsFutureProvider);
    final ambientSoundName = _ambientSoundNameFrom(
      ref.watch(ambientSoundByIdProvider),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _SettingsRow(
                    label: context.l10n.timer_duration_label,
                    value: '$_durationMinutes min',
                    onTap: _pickDuration,
                  ),
                  const SizedBox(height: 12),
                  _SettingsRow(
                    label: context.l10n.timer_ambient_sound_label,
                    value:
                        ambientSoundName ??
                        context.l10n.timer_ambient_sound_none,
                    leadingIcon: AppAssets.timerAmbientSound,
                    onTap: _pickAmbientSound,
                  ),
                ],
              ),
            ),
            Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final bgColor = isDark ? AppColors.surfaceWhite : Colors.black;
                final fgColor = isDark ? Colors.black : AppColors.surfaceWhite;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          _isSubmitting
                              ? null
                              : (_isEditing ? _onSaveChanges : _onBeginSession),
                      style: FilledButton.styleFrom(
                        backgroundColor: bgColor,
                        foregroundColor: fgColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: const StadiumBorder(),
                      ),
                      child:
                          _isSubmitting
                              ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(fgColor),
                                ),
                              )
                              : Text(
                                _isEditing
                                    ? context.l10n.timer_save_changes
                                    : context.l10n.timer_begin_session,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 48,
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(AppAssets.arrowLeft),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                _isEditing
                    ? context.l10n.timer_edit_title
                    : context.l10n.timer_new_title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 88,
            height: 48,
            child: Align(
              alignment: Alignment.centerRight,
              // Editing saves through the bottom button instead, so there is
              // only ever one save action on screen.
              child:
                  _isEditing
                      ? null
                      : TextButton(
                        onPressed: _isSubmitting ? null : _onSave,
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          context.l10n.save,
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.leadingIcon,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : AppColors.surfaceWhite;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final labelColor = textColor.withValues(alpha: 0.5);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (leadingIcon != null) ...[
                          Icon(
                            leadingIcon,
                            size: 16,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                AppAssets.caretRight,
                size: 18,
                color: textColor.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
