import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Dialog for adding offline group-accumulation chants completed outside the app.
///
/// Returns the selected chant count, or `null` when dismissed.
Future<int?> showAddOfflineChantsDialog(
  BuildContext context, {
  String? title,
  String? message,
}) {
  return showDialog<int>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _AddOfflineChantsDialog(title: title, message: message),
  );
}

class _AddOfflineChantsDialog extends StatefulWidget {
  final String? title;
  final String? message;

  const _AddOfflineChantsDialog({this.title, this.message});

  @override
  State<_AddOfflineChantsDialog> createState() => _AddOfflineChantsDialogState();
}

class _AddOfflineChantsDialogState extends State<_AddOfflineChantsDialog> {
  static const _maxChants = 999;

  int _chants = 0;

  void _decrement() {
    if (_chants <= 0) return;
    HapticFeedback.selectionClick();
    setState(() => _chants--);
  }

  void _increment() {
    if (_chants >= _maxChants) return;
    HapticFeedback.selectionClick();
    setState(() => _chants++);
  }

  void _confirm() {
    if (_chants <= 0) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_chants);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.goldLight;

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
              widget.title ?? l10n.group_accumulator_add_offline_chants_title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.message ??
                  l10n.group_accumulator_add_offline_chants_message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ChantStepButton(
                  icon: AppAssets.minusCircle,
                  onPressed: _chants > 0 ? _decrement : null,
                ),
                const SizedBox(width: 20),
                Container(
                  width: 72,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark ? AppColors.cardBorderDark : AppColors.grey300,
                    ),
                  ),
                  child: Text(
                    '$_chants',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                _ChantStepButton(
                  icon: AppAssets.plusCircle,
                  onPressed: _chants < _maxChants ? _increment : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _chants > 0 ? _confirm : null,
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
                      _chants > 0
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

class _ChantStepButton extends StatelessWidget {
  const _ChantStepButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;
    final color = enabled ? theme.colorScheme.onSurface : AppColors.grey400;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Icon(icon, size: 40, color: color),
      ),
    );
  }
}
