import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:wheel_picker/wheel_picker.dart';

/// Dialog for adding mala rounds completed outside the app.
///
/// Returns the selected round count, or `null` when dismissed.
Future<int?> showAddMalaRoundsDialog(BuildContext context) {
  return showDialog<int>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _AddMalaRoundsDialog(),
  );
}

class _AddMalaRoundsDialog extends StatefulWidget {
  const _AddMalaRoundsDialog();

  @override
  State<_AddMalaRoundsDialog> createState() => _AddMalaRoundsDialogState();
}

class _AddMalaRoundsDialogState extends State<_AddMalaRoundsDialog> {
  /// Highest pick on the wheel; it loops back to 0 past this.
  static const _maxRounds = 20;
  static const _itemExtent = 36.0;
  static const _magnification = 1.25;

  late final WheelPickerController _controller = WheelPickerController(
    itemCount: _maxRounds + 1,
  );
  int _rounds = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onIndexChanged(int index, WheelPickerInteractionType _) {
    HapticFeedback.selectionClick();
    setState(() => _rounds = index);
  }

  void _confirm() {
    if (_rounds <= 0) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_rounds);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.goldLight;
    final onSurface = theme.colorScheme.onSurface;
    final useTibetan = context.isTibetanLocale;

    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.mala_add_rounds_title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.mala_add_rounds_message,
              style: theme.textTheme.bodyMedium?.copyWith(color: onSurface),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: _itemExtent * 5.5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Selected-row pill behind the wheel.
                  Container(
                    height: _itemExtent * _magnification,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  WheelPicker(
                    controller: _controller,
                    looping: true,
                    onIndexChanged: _onIndexChanged,
                    selectedIndexColor: onSurface,
                    style: const WheelPickerStyle(
                      itemExtent: _itemExtent,
                      magnification: _magnification,
                      squeeze: 1.1,
                      diameterRatio: 1.6,
                      surroundingOpacity: 0.35,
                    ),
                    builder:
                        (context, index) => Center(
                          child: Text(
                            useTibetan ? toTibetanDigits(index) : '$index',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: onSurface,
                            ),
                          ),
                        ),
                  ),
                  // Unit label beside the selected number; taps fall through.
                  IgnorePointer(
                    child: Row(
                      children: [
                        const Spacer(),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 28),
                            child: Text(
                              l10n.mala_rounds_unit(_rounds),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _rounds > 0 ? _confirm : null,
              style: FilledButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.textPrimaryDark : Colors.black,
                foregroundColor: isDark ? AppColors.textPrimary : Colors.white,
                disabledBackgroundColor:
                    isDark ? AppColors.grey600 : AppColors.grey300,
                disabledForegroundColor:
                    isDark ? AppColors.grey500 : AppColors.grey600,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                l10n.ai_confirm,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      _rounds > 0
                          ? (isDark ? AppColors.textPrimary : Colors.white)
                          : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
