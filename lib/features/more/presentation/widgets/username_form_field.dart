import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum UsernameState { idle, checking, available, conflict, error, invalid }

/// A self-contained username input that shows a real-time availability status
/// icon and inline feedback (conflict message + tappable suggestions).
class UsernameFormField extends StatelessWidget {
  const UsernameFormField({
    super.key,
    required this.controller,
    required this.usernameState,
    required this.usernameSuggestions,
    required this.onChanged,
    required this.onSuggestionTap,
    required this.isDark,
    this.validationMessage,
    this.placeholderStyle,
  });

  final TextEditingController controller;
  final UsernameState usernameState;
  final List<String> usernameSuggestions;
  final ValueChanged<String> onChanged;

  /// Called when the user taps one of the suggested available usernames.
  final ValueChanged<String> onSuggestionTap;
  final bool isDark;

  /// Shown below the field when [usernameState] is [UsernameState.invalid].
  final String? validationMessage;

  /// When set, "Username" is a placeholder in this style that disappears on
  /// typing, as on the onboarding step, instead of a floating label.
  final TextStyle? placeholderStyle;

  InputBorder get _inputBorder => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: isDark ? AppColors.grey800 : AppColors.grey300,
    ),
  );

  InputBorder get _focusedBorder => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: isDark ? AppColors.grey600 : AppColors.grey900,
      width: 1.5,
    ),
  );

  InputBorder get _errorBorder => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.red.shade400),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isError =
        usernameState == UsernameState.conflict ||
        usernameState == UsernameState.invalid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: placeholderStyle == null ? l10n.username_label : null,
            labelStyle: TextStyle(color: AppColors.grey500),
            hintText: placeholderStyle == null ? null : l10n.username_label,
            hintStyle: placeholderStyle,
            filled: true,
            fillColor:
                isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
            border: _inputBorder,
            enabledBorder: isError ? _errorBorder : _inputBorder,
            focusedBorder: isError ? _errorBorder : _focusedBorder,
            contentPadding:
                placeholderStyle == null
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                    : const EdgeInsets.fromLTRB(20, 14, 16, 14),
            suffixIcon: _buildStatusIcon(),
          ),
        ),
        _buildFeedback(l10n),
      ],
    );
  }

  Widget? _buildStatusIcon() {
    switch (usernameState) {
      case UsernameState.checking:
        return Padding(
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.grey600),
            ),
          ),
        );
      case UsernameState.available:
        return Icon(
          AppAssets.checkCircle,
          color: Colors.green.shade600,
          size: 20,
        );
      case UsernameState.conflict:
        return Icon(
          AppAssets.warningCircle,
          color: Colors.red.shade600,
          size: 20,
        );
      case UsernameState.error:
        return Icon(
          AppAssets.warningCircle,
          color: Colors.orange.shade600,
          size: 20,
        );
      case UsernameState.invalid:
        return Icon(
          PhosphorIconsRegular.warningCircle,
          color: Colors.red.shade600,
          size: 20,
        );
      case UsernameState.idle:
        return null;
    }
  }

  Widget _buildFeedback(AppLocalizations l10n) {
    switch (usernameState) {
      case UsernameState.conflict:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              l10n.username_taken,
              style: TextStyle(color: Colors.red.shade600, fontSize: 13),
            ),
            if (usernameSuggestions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                children: [
                  Text(
                    l10n.username_available_label,
                    style: TextStyle(
                      color: isDark ? AppColors.grey400 : AppColors.grey600,
                      fontSize: 13,
                    ),
                  ),
                  for (int i = 0; i < usernameSuggestions.length; i++) ...[
                    GestureDetector(
                      onTap: () => onSuggestionTap(usernameSuggestions[i]),
                      child: Text(
                        usernameSuggestions[i],
                        style: TextStyle(
                          color: isDark ? AppColors.grey400 : AppColors.grey600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (i < usernameSuggestions.length - 1)
                      Text(
                        ', ',
                        style: TextStyle(
                          color: isDark ? AppColors.grey400 : AppColors.grey600,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ],
        );
      case UsernameState.error:
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            l10n.username_check_error,
            style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
          ),
        );
      case UsernameState.invalid:
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            validationMessage ?? l10n.username_invalid_format,
            style: TextStyle(color: Colors.red.shade600, fontSize: 13),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
