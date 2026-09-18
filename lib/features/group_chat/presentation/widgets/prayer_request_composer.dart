import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Pill field for a new prayer request: `+` on the left, send on the right
/// once something has been typed.
class PrayerRequestComposer extends StatelessWidget {
  const PrayerRequestComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.isSending,
    required this.onSubmit,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool isSending;
  final VoidCallback onSubmit;
  final bool enabled;

  static const double _minHeight = 44;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.grey800 : AppColors.grey300;
    final fillColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite;
    final iconColor = isDark ? AppColors.textTertiaryDark : AppColors.grey800;
    final sendColor = isDark ? AppColors.surfaceWhite : AppColors.textPrimary;

    return Container(
      constraints: const BoxConstraints(minHeight: _minHeight),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(_minHeight / 2),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.only(left: 12, right: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(AppAssets.plus, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              style: TextStyle(
                fontSize: 15,
                height: 1.2,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 15,
                  height: 1.2,
                  color:
                      isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textSecondary,
                ),
                isDense: true,
                filled: false,
                fillColor: Colors.transparent,
                hoverColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;
              if (!hasText && !isSending) return const SizedBox.shrink();
              final canSend = enabled && hasText && !isSending;
              return IconButton(
                onPressed: canSend ? onSubmit : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                icon:
                    isSending
                        ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: sendColor,
                          ),
                        )
                        : Icon(
                          AppAssets.arrowCircleUp,
                          size: 28,
                          color: canSend ? sendColor : borderColor,
                        ),
              );
            },
          ),
        ],
      ),
    );
  }
}
