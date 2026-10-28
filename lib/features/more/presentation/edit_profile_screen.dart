import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/error/error_message_mapper.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/user_state.dart';
import 'package:flutter_pecha/features/more/presentation/providers/tradition_onboarding_paths_provider.dart';
import 'package:flutter_pecha/features/more/presentation/providers/user_traditions_provider.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/profile_avatar_section.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/tradition_picker_sheet.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/traditions_form_field.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/username_form_field.dart';
import 'package:flutter_pecha/shared/domain/validators/person_name_validator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pecha/core/cache/app_image_cache_manager.dart';
import 'package:flutter_pecha/core/utils/network_image_utils.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  static const String routeName = '/profile';

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _bioCtrl;

  String? _originalUsername;

  UsernameState _usernameState = UsernameState.idle;
  List<String> _usernameSuggestions = [];
  String? _usernameValidationMessage;
  String? _displayNameValidationMessage;
  Timer? _usernameDebounce;

  bool _isRefreshing = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  File? _pickedAvatarFile;
  String? _uploadedAvatarUrl;
  String? _saveError;

  // Captured before refreshUser() runs so we can detect an avatar change
  // when the listener fires (at that point `previous` is the loading state).
  String? _avatarUrlAtRefreshStart;

  static const int _bioMaxLength = 100;
  static const Duration _debounceDuration = Duration(milliseconds: 700);

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider).user;
    _originalUsername = user?.username;
    _avatarUrlAtRefreshStart = user?.avatarUrl;
    _usernameCtrl = TextEditingController(text: user?.username ?? '');
    _displayNameCtrl = TextEditingController(text: user?.visibleName ?? '');
    _bioCtrl = TextEditingController(text: user?.aboutMe ?? '');
    _bioCtrl.addListener(() => setState(() {}));

    // Fetch fresh user info from the API when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _isRefreshing = true);
      ref.read(userProvider.notifier).refreshUser();
      // Warm the tradition picker list so opening the sheet does not flash.
      ref.read(traditionOnboardingPathsProvider.future);
    });
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // ── Username debounce ─────────────────────────────────────────────────────

  static String? _validateUsername(String username, AppLocalizations l10n) {
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

  static String? _validatePersonName(String name, AppLocalizations l10n) {
    return switch (PersonNameValidator.validate(name)) {
      PersonNameValidationError.tooShort => l10n.person_name_min_length,
      PersonNameValidationError.tooLong => l10n.person_name_max_length,
      PersonNameValidationError.invalidCharacters =>
        l10n.person_name_invalid_chars,
      null => null,
    };
  }

  void _onDisplayNameChanged(String value) {
    setState(
      () =>
          _displayNameValidationMessage = _validatePersonName(
            value,
            AppLocalizations.of(context)!,
          ),
    );
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    final trimmed = value.trim();

    if (trimmed.isEmpty || trimmed == _originalUsername) {
      setState(() {
        _usernameState = UsernameState.idle;
        _usernameValidationMessage = null;
        _usernameSuggestions = [];
      });
      return;
    }

    final formatError = _validateUsername(
      trimmed,
      AppLocalizations.of(context)!,
    );
    if (formatError != null) {
      setState(() {
        _usernameState = UsernameState.invalid;
        _usernameValidationMessage = formatError;
        _usernameSuggestions = [];
      });
      return;
    }

    setState(() {
      _usernameState = UsernameState.checking;
      _usernameValidationMessage = null;
      _usernameSuggestions = [];
    });

    _usernameDebounce = Timer(_debounceDuration, () => _checkUsername(trimmed));
  }

  Future<void> _checkUsername(String username) async {
    if (!mounted) return;
    setState(() => _usernameState = UsernameState.checking);

    final result = await ref
        .read(userProvider.notifier)
        .updateUsername(username);

    if (!mounted) return;

    // Discard stale response if the field changed while the request was in-flight.
    if (_usernameCtrl.text.trim() != username) return;

    if (result == null) {
      setState(() {
        _usernameState = UsernameState.error;
        _usernameSuggestions = [];
      });
      return;
    }

    if (result.isAvailable) {
      _originalUsername = result.updatedUsername;
      setState(() {
        _usernameState = UsernameState.available;
        _usernameSuggestions = [];
      });
    } else {
      setState(() {
        _usernameState = UsernameState.conflict;
        _usernameSuggestions = result.suggestions;
      });
    }
  }

  void _applySuggestion(String suggestion) {
    _usernameDebounce?.cancel();
    _usernameCtrl.text = suggestion;
    _usernameCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _checkUsername(suggestion);
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _onSave() async {
    // If a username check is pending, wait for it first.
    if (_usernameState == UsernameState.checking) return;

    // Block save if username has a conflict or failed frontend validation.
    if (_usernameState == UsernameState.conflict) return;
    if (_usernameState == UsernameState.invalid) return;
    if (_displayNameValidationMessage != null) return;

    final l10n = AppLocalizations.of(context)!;

    final displayNameError = _validatePersonName(_displayNameCtrl.text, l10n);
    if (displayNameError != null) {
      setState(() => _displayNameValidationMessage = displayNameError);
      return;
    }

    // Fail fast when offline so the user gets a clear message instead of a
    // raw token-refresh error from the network layer.
    final isOnline =
        await ref.read(connectivityServiceProvider).checkConnectivity();
    if (!mounted) return;
    if (!isOnline) {
      setState(() => _saveError = l10n.edit_profile_offline);
      return;
    }

    // If the username debounce hasn't fired yet, run it synchronously.
    final pendingUsername = _usernameCtrl.text.trim();
    if (_usernameDebounce?.isActive == true &&
        pendingUsername != _originalUsername &&
        pendingUsername.isNotEmpty) {
      _usernameDebounce!.cancel();
      final formatError = _validateUsername(
        pendingUsername,
        AppLocalizations.of(context)!,
      );
      if (formatError != null) {
        setState(() {
          _usernameState = UsernameState.invalid;
          _usernameValidationMessage = formatError;
          _usernameSuggestions = [];
        });
        return;
      }
      await _checkUsername(pendingUsername);
      if (!mounted) return;
      if (_usernameState == UsernameState.conflict ||
          _usernameState == UsernameState.error ||
          _usernameState == UsernameState.invalid) {
        return;
      }
    }

    setState(() {
      _saveError = null;
      _isSaving = true;
    });

    // Use the newly uploaded URL if available, otherwise preserve the existing
    // one so the backend doesn't wipe the avatar on a plain profile save.
    final existingAvatarUrl = ref.read(userProvider).user?.avatarUrl;
    final avatarUrlToSend = _uploadedAvatarUrl ?? existingAvatarUrl;

    final error = await ref
        .read(userProvider.notifier)
        .saveProfile(
          displayName:
              PersonNameValidator.sanitize(_displayNameCtrl.text) ?? '',
          aboutMe: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
          avatarUrl: avatarUrlToSend,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      // Never surface the raw error string (it can be a low-level NSURLError /
      // token-refresh dump). Connectivity can drop between the pre-check and
      // the request, so detect network failures by content here too — note the
      // offline case is wrapped as an auth failure, so type-based mapping is
      // unreliable and we must inspect the message.
      final friendly =
          ErrorMessageMapper.isNetworkError(error)
              ? l10n.edit_profile_offline
              : l10n.edit_profile_save_failed;
      setState(() => _saveError = friendly);
      return;
    }

    // Refresh user data in the background so me_screen immediately shows the
    // latest avatar and profile fields from the server (the POST /users/info
    // response may omit avatar_url, which would otherwise wipe it from state).
    unawaited(ref.read(userProvider.notifier).refreshUser());

    Navigator.of(context).pop();
  }

  // ── Avatar picker + upload ────────────────────────────────────────────────

  static const int _maxAvatarBytes = 1024 * 1024; // 1 MB — matches server limit

  /// Returns a new [File] whose pixels are physically rotated to match the
  /// EXIF orientation and whose EXIF orientation tag is stripped/set to 1.
  ///
  /// This ensures the file stored on S3 always has correct upright pixels,
  /// regardless of which iOS version or image renderer fetches it later.
  Future<File> _normalizeOrientation(String sourcePath) async {
    final tmpDir = await getTemporaryDirectory();
    final destPath =
        '${tmpDir.path}/avatar_normalized_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      destPath,
      quality: 90,
      autoCorrectionAngle: true,
    );
    return result != null ? File(result.path) : File(sourcePath);
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? xFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (xFile == null || !mounted) return;

    // Physically bake the EXIF orientation into the pixel data before upload.
    // Without this, some iOS versions store the image with pixels in sensor
    // orientation (e.g. landscape) and only an EXIF tag to indicate rotation.
    // CachedNetworkImage and other renderers handle that tag inconsistently,
    // causing the avatar to appear rotated on a subset of devices.
    final file = await _normalizeOrientation(xFile.path);

    // Guard against files that are still over the server limit even after
    // picker compression. Skips the network call entirely.
    final fileSize = await file.length();
    if (fileSize > _maxAvatarBytes) {
      _showAvatarUploadError(null);
      return;
    }

    setState(() {
      _pickedAvatarFile = file;
      _isUploadingAvatar = true;
      _saveError = null;
    });

    final result = await ref.read(userProvider.notifier).uploadAvatar(file);

    if (!mounted) return;

    if (result.error != null) {
      // Upload failed — revert the local preview and show a friendly dialog.
      setState(() {
        _isUploadingAvatar = false;
        _pickedAvatarFile = null;
      });
      _showAvatarUploadError(result.error!);
    } else {
      // Upload succeeded — evict the stale image from both the disk cache and
      // Flutter's in-memory image cache. Both must be cleared because presigned
      // S3 URLs share the same stable cache key, and the imageCache can serve
      // stale decoded pixels even after the disk entry is removed.
      final oldUrl = ref.read(userProvider).user?.avatarUrl ?? '';
      if (oldUrl.isNotEmpty) {
        _evictAvatarFromAllCaches(oldUrl);
      }

      setState(() {
        _isUploadingAvatar = false;
        _uploadedAvatarUrl = result.url;
      });
    }
  }

  /// Removes [url] from every layer of image caching so the widget always
  /// re-fetches the latest image from the server.
  ///
  /// Two separate stores must be cleared:
  /// • `flutter_cache_manager`'s disk + memory store (via [CachedNetworkImage.evictFromCache])
  /// • Flutter's decoded-pixel in-memory cache (via [ImageProvider.evict])
  ///   — this is the layer that causes stale images even after disk eviction.
  void _evictAvatarFromAllCaches(String url) {
    if (url.isEmpty) return;
    unawaited(appImageCacheManager.removeFile(stableNetworkImageCacheKey(url)));
    // Each display size decodes under its own key, so drop every decoded
    // image, live ones included; they come back from disk.
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  }

  void _showAvatarUploadError(String? rawError) {
    // null → client-side size rejection; non-null → server error string
    final bool isTooBig =
        rawError == null ||
        rawError.contains('413') ||
        rawError.toLowerCase().contains('too large');
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.edit_profile_photo_not_uploaded),
            content: Text(
              isTooBig
                  ? l10n.edit_profile_photo_too_large
                  : l10n.edit_profile_photo_upload_failed,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.common_ok),
              ),
            ],
          ),
    );
  }

  void _showAvatarSourceSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final l10n = AppLocalizations.of(context)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(AppAssets.photoLibrary),
                title: Text(l10n.edit_profile_choose_from_library),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadAvatar(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(AppAssets.camera),
                title: Text(l10n.edit_profile_take_photo),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadAvatar(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    context.push(AppRoutes.deleteAccount);
  }

  Future<void> _showTraditionPicker() async {
    try {
      await ref.read(traditionOnboardingPathsProvider.future);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.something_went_wrong),
        ),
      );
      return;
    }
    if (!mounted) return;

    final currentTraditions =
        ref.read(userTraditionsProvider).valueOrNull ?? const [];
    await showTraditionPickerSheet(
      context,
      initialSelectedCodes:
          currentTraditions.map((t) => t.traditionCode).toSet(),
    );
  }

  Future<void> _onRemoveTradition(String userTraditionId) async {
    final l10n = AppLocalizations.of(context)!;
    final removed = await ref
        .read(userTraditionsProvider.notifier)
        .removeTradition(userTraditionId);
    if (!mounted || removed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.edit_profile_tradition_remove_failed)),
    );
  }

  bool get _canSave =>
      !_isRefreshing &&
      !_isSaving &&
      !_isUploadingAvatar &&
      _usernameState != UsernameState.checking &&
      _usernameState != UsernameState.conflict &&
      _usernameState != UsernameState.invalid &&
      _displayNameValidationMessage == null;

  @override
  Widget build(BuildContext context) {
    // Update text fields once the fresh API data arrives.
    ref.listen<UserState>(userProvider, (previous, next) {
      if (!_isRefreshing) return;
      if (next.isLoading) return;
      if (!mounted) return;
      final user = next.user;
      if (user != null) {
        // If the avatar URL changed, purge the old decoded image from both
        // flutter_cache_manager's disk store and Flutter's in-memory image
        // cache. Without this, the imageCache serves stale pixels even though
        // the disk cache was already evicted at upload time.
        final oldUrl = _avatarUrlAtRefreshStart ?? '';
        final newUrl = user.avatarUrl ?? '';
        if (oldUrl.isNotEmpty && oldUrl != newUrl) {
          _evictAvatarFromAllCaches(oldUrl);
        }

        _originalUsername = user.username;
        _usernameCtrl.text = user.username ?? '';
        _displayNameCtrl.text = user.visibleName;
        _bioCtrl.text = user.aboutMe ?? '';
      }
      setState(() => _isRefreshing = false);
    });

    final user = ref.watch(userProvider).user;
    final avatarUrl = user?.avatarUrl ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userTraditionsAsync = ref.watch(userTraditionsProvider);
    final userTraditions = userTraditionsAsync.valueOrNull ?? const [];
    final isLoadingTraditions =
        userTraditionsAsync.isLoading && userTraditions.isEmpty;

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isDark ? AppColors.grey800 : AppColors.grey300,
      ),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isDark ? AppColors.grey600 : AppColors.grey900,
        width: 1.5,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(
            AppAssets.arrowLeft,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.edit_profile_title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        bottom:
            (_isRefreshing || _isSaving || _isUploadingAvatar)
                ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppColors.grey600 : AppColors.grey300,
                    ),
                  ),
                )
                : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed:
                  _canSave
                      ? () {
                        HapticFeedback.lightImpact();
                        _onSave();
                      }
                      : null,
              style: TextButton.styleFrom(
                backgroundColor:
                    isDark
                        ? AppColors.surfaceWhite
                        : AppColors.scaffoldBackgroundDark,
                foregroundColor:
                    isDark ? AppColors.textPrimary : AppColors.textPrimaryDark,
                disabledBackgroundColor:
                    isDark ? AppColors.grey800 : AppColors.grey300,
                disabledForegroundColor:
                    isDark ? AppColors.grey600 : AppColors.grey500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                AppLocalizations.of(context)!.edit_profile_save,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Avatar ────────────────────────────────────────────────
              ProfileAvatarSection(
                avatarUrl: avatarUrl,
                isUploadingAvatar: _isUploadingAvatar,
                pickedAvatarFile: _pickedAvatarFile,
                onEditTap: _showAvatarSourceSheet,
              ),

              const SizedBox(height: 32),

              // ── Save error banner ─────────────────────────────────────
              if (_saveError != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        AppAssets.warningCircle,
                        size: 18,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _saveError!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Display name ──────────────────────────────────────────
              _buildNameField(
                controller: _displayNameCtrl,
                label: AppLocalizations.of(context)!.edit_profile_display_name,
                validationMessage: _displayNameValidationMessage,
                onChanged: _onDisplayNameChanged,
                isDark: isDark,
                inputBorder: inputBorder,
                focusedBorder: focusedBorder,
              ),

              const SizedBox(height: 20),

              // ── Username ──────────────────────────────────────────────
              UsernameFormField(
                controller: _usernameCtrl,
                usernameState: _usernameState,
                usernameSuggestions: _usernameSuggestions,
                onChanged: _onUsernameChanged,
                onSuggestionTap: _applySuggestion,
                isDark: isDark,
                validationMessage: _usernameValidationMessage,
              ),

              const SizedBox(height: 20),

              // ── Bio ───────────────────────────────────────────────────
              TextField(
                controller: _bioCtrl,
                maxLines: 3,
                maxLength: _bioMaxLength,
                buildCounter: (
                  context, {
                  required currentLength,
                  required isFocused,
                  required maxLength,
                }) {
                  return Text(
                    '$currentLength/${maxLength ?? _bioMaxLength}',
                    style: TextStyle(fontSize: 12, color: AppColors.grey600),
                  );
                },
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.edit_profile_bio,
                  labelStyle: TextStyle(color: AppColors.grey500),
                  hintText: AppLocalizations.of(context)!.edit_profile_bio_hint,
                  hintStyle: TextStyle(color: AppColors.grey500),
                  filled: true,
                  fillColor:
                      isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceWhite,
                  border: inputBorder,
                  enabledBorder: inputBorder,
                  focusedBorder: focusedBorder,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Traditions ────────────────────────────────────────────
              TraditionsFormField(
                traditions: userTraditions,
                isLoading: isLoadingTraditions,
                isDark: isDark,
                onTap: _showTraditionPicker,
                onRemove: (tradition) => _onRemoveTradition(tradition.id),
              ),

              const SizedBox(height: 32),

              // ── Delete account ────────────────────────────────────────
              InkWell(
                onTap: _showDeleteAccountDialog,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        AppAssets.trash,
                        size: 22,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(
                            context,
                          )!.edit_profile_delete_account,
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Icon(
                        AppAssets.caretRight,
                        size: 20,
                        color: AppColors.grey600,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField({
    required TextEditingController controller,
    required String label,
    required String? validationMessage,
    required ValueChanged<String> onChanged,
    required bool isDark,
    required InputBorder inputBorder,
    required InputBorder focusedBorder,
  }) {
    final hasError = validationMessage != null;
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade400),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLength: PersonNameValidator.maxLength,
          buildCounter:
              (
                context, {
                required currentLength,
                required isFocused,
                required maxLength,
              }) => const SizedBox.shrink(),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: AppColors.grey500),
            filled: true,
            fillColor:
                isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
            border: inputBorder,
            enabledBorder: hasError ? errorBorder : inputBorder,
            focusedBorder: hasError ? errorBorder : focusedBorder,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              validationMessage,
              style: TextStyle(color: Colors.red.shade600, fontSize: 13),
            ),
          ),
      ],
    );
  }
}
