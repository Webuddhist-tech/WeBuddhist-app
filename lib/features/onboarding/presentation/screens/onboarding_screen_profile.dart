import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/error_message_mapper.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/username_form_field.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_choice_scaffold.dart';
import 'package:flutter_pecha/shared/domain/validators/person_name_validator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Onboarding screen for phone accounts: choose a display name and username.
///
/// Auth0 creates phone accounts with a generated display name and username,
/// so this step replaces both. Continue saves the username first
/// (PATCH /users/username) because it is the one the backend can refuse, then
/// the display name (POST /users/info).
class OnboardingScreenProfile extends ConsumerStatefulWidget {
  const OnboardingScreenProfile({
    super.key,
    required this.onNext,
    this.stepIndex = 0,
    this.stepCount = 3,
  });

  final VoidCallback onNext;

  /// Position in the progress bar; see [OnboardingChoiceScaffold.stepCount].
  final int stepIndex;
  final int stepCount;

  @override
  ConsumerState<OnboardingScreenProfile> createState() =>
      _OnboardingScreenProfileState();
}

class _OnboardingScreenProfileState
    extends ConsumerState<OnboardingScreenProfile> {
  final _displayNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();

  String? _displayNameError;
  UsernameState _usernameState = UsernameState.idle;
  String? _usernameMessage;
  List<String> _usernameSuggestions = const [];

  /// The username the backend already accepted, so a retry after a failed
  /// display name save does not claim it again.
  String? _savedUsername;
  bool _isSaving = false;
  String? _saveError;

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  static String? _displayNameErrorFor(String value, AppLocalizations l10n) {
    if (PersonNameValidator.sanitize(value) == null) {
      return l10n.onboarding_profile_display_name_required;
    }
    return switch (PersonNameValidator.validate(value)) {
      PersonNameValidationError.tooShort => l10n.person_name_min_length,
      PersonNameValidationError.tooLong => l10n.person_name_max_length,
      PersonNameValidationError.invalidCharacters =>
        l10n.person_name_invalid_chars,
      null => null,
    };
  }

  /// Mirrors the backend's USERNAME_PATTERN, one message per rule. Same rules
  /// as the Edit Profile screen.
  static String? _usernameErrorFor(String username, AppLocalizations l10n) {
    if (username.length < 3) return l10n.username_min_length;
    if (username.length > 30) return l10n.username_max_length;
    if (username.contains(' ')) return l10n.username_no_spaces;
    if (!RegExp(r'^[a-zA-Z0-9_.\-]+$').hasMatch(username)) {
      return l10n.username_invalid_chars;
    }
    if (!RegExp(r'^[a-zA-Z0-9]').hasMatch(username)) {
      return l10n.username_must_start_alphanumeric;
    }
    if (!RegExp(r'[a-zA-Z0-9]$').hasMatch(username)) {
      return l10n.username_must_end_alphanumeric;
    }
    return null;
  }

  void _onDisplayNameChanged(String value) {
    // Only re-check once an error is showing, so typing is not interrupted.
    if (_displayNameError == null) return;
    setState(
      () => _displayNameError = _displayNameErrorFor(value, context.l10n),
    );
  }

  void _onUsernameChanged(String value) {
    final trimmed = value.trim();
    final message =
        trimmed.isEmpty ? null : _usernameErrorFor(trimmed, context.l10n);
    setState(() {
      _usernameState =
          message == null ? UsernameState.idle : UsernameState.invalid;
      _usernameMessage = message;
      _usernameSuggestions = const [];
    });
  }

  void _onSuggestionTap(String suggestion) {
    _usernameCtrl.text = suggestion;
    _usernameCtrl.selection = TextSelection.collapsed(
      offset: suggestion.length,
    );
    _onUsernameChanged(suggestion);
  }

  // ── Continue ──────────────────────────────────────────────────────────────

  Future<void> _continue() async {
    if (_isSaving) return;
    final l10n = context.l10n;
    final username = _usernameCtrl.text.trim();
    final displayNameError = _displayNameErrorFor(_displayNameCtrl.text, l10n);
    final usernameError = _usernameErrorFor(username, l10n);

    setState(() {
      _displayNameError = displayNameError;
      _saveError = null;
      if (usernameError != null) {
        _usernameState = UsernameState.invalid;
        _usernameMessage = usernameError;
        _usernameSuggestions = const [];
      }
    });
    if (displayNameError != null || usernameError != null) return;

    final isOnline =
        await ref.read(connectivityServiceProvider).checkConnectivity();
    if (!mounted) return;
    if (!isOnline) {
      setState(() => _saveError = l10n.edit_profile_offline);
      return;
    }

    setState(() => _isSaving = true);
    final userNotifier = ref.read(userProvider.notifier);

    if (username != _savedUsername) {
      setState(() => _usernameState = UsernameState.checking);
      final result = await userNotifier.updateUsername(username);
      if (!mounted) return;
      if (result == null || !result.isAvailable) {
        setState(() {
          _isSaving = false;
          _usernameState =
              result == null ? UsernameState.error : UsernameState.conflict;
          _usernameSuggestions = result?.suggestions ?? const [];
        });
        return;
      }
      _savedUsername = username;
      setState(() => _usernameState = UsernameState.available);
    }

    // saveProfile sends the stored first and last name back unchanged, so
    // make sure the profile is loaded before saving over it.
    if (ref.read(userProvider).user == null) await userNotifier.refreshUser();
    if (!mounted) return;
    final user = ref.read(userProvider).user;
    final error = await userNotifier.saveProfile(
      displayName: PersonNameValidator.sanitize(_displayNameCtrl.text) ?? '',
      aboutMe: user?.aboutMe,
      avatarUrl: user?.avatarUrl,
    );
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isSaving = false;
        _saveError =
            ErrorMessageMapper.isNetworkError(error)
                ? l10n.edit_profile_offline
                : l10n.edit_profile_save_failed;
      });
      return;
    }

    setState(() => _isSaving = false);
    widget.onNext();
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Figma: the placeholders use the content (serif) font, 16/24, grey.
    final placeholderStyle = TextStyle(
      fontFamily: AppFontConfig.getFontFamily(
        Localizations.localeOf(context).languageCode,
        FontType.content,
      ),
      fontSize: 16,
      height: 24 / 16,
      color: isDark ? AppColors.grey500 : AppColors.textSecondary,
    );

    return OnboardingChoiceScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: l10n.onboarding_profile_title,
      subtitle: l10n.onboarding_profile_subtitle,
      note: l10n.onboarding_profile_note,
      isSaving: _isSaving,
      onContinue: _continue,
      options: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DisplayNameField(
            controller: _displayNameCtrl,
            placeholder: l10n.edit_profile_display_name,
            placeholderStyle: placeholderStyle,
            errorText: _displayNameError,
            enabled: !_isSaving,
            isDark: isDark,
            onChanged: _onDisplayNameChanged,
          ),
          const SizedBox(height: 24),
          UsernameFormField(
            controller: _usernameCtrl,
            usernameState: _usernameState,
            usernameSuggestions: _usernameSuggestions,
            validationMessage: _usernameMessage,
            onChanged: _onUsernameChanged,
            onSuggestionTap: _onSuggestionTap,
            isDark: isDark,
            placeholderStyle: placeholderStyle,
          ),
          if (_saveError != null) ...[
            const SizedBox(height: 16),
            Text(
              _saveError!,
              style: TextStyle(color: Colors.red.shade600, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

/// Display name input styled like [UsernameFormField].
class _DisplayNameField extends StatelessWidget {
  const _DisplayNameField({
    required this.controller,
    required this.placeholder,
    required this.placeholderStyle,
    required this.errorText,
    required this.enabled,
    required this.isDark,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String placeholder;
  final TextStyle placeholderStyle;
  final String? errorText;
  final bool enabled;
  final bool isDark;
  final ValueChanged<String> onChanged;

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final idle = isDark ? AppColors.grey800 : AppColors.grey300;
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      maxLength: PersonNameValidator.maxLength,
      buildCounter:
          (
            context, {
            required currentLength,
            required isFocused,
            required maxLength,
          }) => null,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.name],
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: placeholderStyle,
        errorText: errorText,
        filled: true,
        fillColor:
            isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
        border: _border(idle),
        enabledBorder: _border(idle),
        disabledBorder: _border(idle),
        focusedBorder: _border(
          isDark ? AppColors.grey600 : AppColors.grey900,
          width: 1.5,
        ),
        errorBorder: _border(Colors.red.shade400),
        focusedErrorBorder: _border(Colors.red.shade400, width: 1.5),
        // Figma: 52 tall, 20 in from the left, 16 from the right.
        contentPadding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      ),
    );
  }
}
