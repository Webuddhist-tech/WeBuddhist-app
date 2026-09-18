import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/destructive_confirmation_dialog.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_link_card.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_post_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_post_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_post_add_link_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// What the composer pops with. [saved] is false when the screen closed
/// after a save that only partially persisted; the list should still take
/// [post], but the caller must not report success.
class GroupPostComposerResult {
  final ConnectPost post;
  final bool saved;

  const GroupPostComposerResult(this.post, {required this.saved});
}

/// Full-screen composer. Pops with the created or updated post, or null when
/// nothing was persisted.
class GroupPostComposerScreen extends ConsumerStatefulWidget {
  final GroupProfile profile;

  /// When set, the composer edits this post instead of creating one.
  final ConnectPost? post;

  const GroupPostComposerScreen({super.key, required this.profile, this.post});

  static const int maxPhotos = 10;
  static const int maxLinkLabelLength = 255;

  static Future<GroupPostComposerResult?> show(
    BuildContext context,
    GroupProfile profile, {
    ConnectPost? post,
  }) {
    return Navigator.of(context).push<GroupPostComposerResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => GroupPostComposerScreen(profile: profile, post: post),
      ),
    );
  }

  @override
  ConsumerState<GroupPostComposerScreen> createState() =>
      _GroupPostComposerScreenState();
}

class _GroupPostComposerScreenState
    extends ConsumerState<GroupPostComposerScreen> {
  final TextEditingController _captionController = TextEditingController();
  final List<_ComposerPhoto> _photos = [];
  GroupPostLinkDraft? _link;
  bool _isPickingPhotos = false;
  bool _isSubmitting = false;

  /// What the server holds; advances when an edit partially persists.
  ConnectPost? _basePost;

  bool get _isEditing => widget.post != null;

  bool get _hasContent =>
      _captionController.text.trim().isNotEmpty ||
      _photos.isNotEmpty ||
      _link != null;

  bool get _captionChanged =>
      _captionController.text.trim() != (_basePost?.caption ?? '').trim();

  bool get _mediaChanged {
    final original = _basePost?.media ?? const <ConnectPostMedia>[];
    if (_photos.length != original.length) return true;
    for (final (index, photo) in _photos.indexed) {
      final base = original[index];
      final source = photo.source;
      // A partially saved local photo is known only by its uploaded key.
      final unchanged =
          source != null
              ? source.id == base.id
              : base.id.isEmpty &&
                  base.mediaKey != null &&
                  base.mediaKey == photo.uploadedKey;
      if (!unchanged) return true;
    }
    return false;
  }

  bool get _linkChanged {
    final links = _basePost?.links ?? const <ConnectPostLink>[];
    final original = links.isNotEmpty ? links.first : null;
    final link = _link;
    if (original == null || link == null) {
      return original != null || link != null;
    }
    return original.url != link.url ||
        (original.label ?? '') != (_truncateLabel(link.title) ?? '');
  }

  bool get _isDirty => _captionChanged || _mediaChanged || _linkChanged;

  /// Editing asks before losing changes; a new post asks once it has content.
  bool get _shouldConfirmDiscard => _isEditing ? _isDirty : _hasContent;

  bool get _canSubmit =>
      _hasContent &&
      !_isSubmitting &&
      !_isPickingPhotos &&
      (!_isEditing || _isDirty);

  @override
  void initState() {
    super.initState();
    _captionController.addListener(() => setState(() {}));
    final post = widget.post;
    _basePost = post;
    if (post == null) return;
    _captionController.value = TextEditingValue(
      text: post.caption,
      selection: TextSelection.collapsed(offset: post.caption.length),
    );
    _photos.addAll(post.media.map(_ComposerPhoto.remote));
    if (post.links.isNotEmpty) {
      final link = post.links.first;
      _link = GroupPostLinkDraft(
        url: link.url,
        type: link.type,
        title: link.label,
      );
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _onCancel() async {
    if (_isSubmitting) return;
    if (!_shouldConfirmDiscard) {
      Navigator.of(context).pop(_partialResult);
      return;
    }
    await _confirmDiscard();
  }

  /// Parts that persisted before a failed save; the list must still see them.
  GroupPostComposerResult? get _partialResult {
    final base = _basePost;
    if (base == null || identical(base, widget.post)) return null;
    return GroupPostComposerResult(base, saved: false);
  }

  Future<void> _confirmDiscard() async {
    final l10n = context.l10n;
    final discard = await showDestructiveConfirmationDialog(
      context,
      title: l10n.group_post_discard_title,
      message: l10n.group_post_discard_message,
      confirmLabel: l10n.group_post_discard,
      cancelLabel: l10n.group_post_keep_editing,
    );
    if (discard == true && mounted) {
      Navigator.of(context).pop(_partialResult);
    }
  }

  Future<void> _pickPhotos() async {
    if (_isPickingPhotos || _isSubmitting) return;

    final remaining = GroupPostComposerScreen.maxPhotos - _photos.length;
    if (remaining <= 0) {
      _showPhotoLimit();
      return;
    }

    setState(() => _isPickingPhotos = true);

    final picker = ImagePicker();
    var picked = <XFile>[];
    try {
      if (remaining == 1) {
        // The multi picker requires a limit of at least two.
        final single = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        );
        if (single != null) picked = [single];
      } else {
        picked = await picker.pickMultiImage(
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
          limit: remaining,
        );
      }
    } catch (_) {
      picked = [];
    }

    final prepared = <_ComposerPhoto>[];
    for (final (index, file) in picked.take(remaining).indexed) {
      prepared.add(await _ComposerPhoto.prepare(file, index));
    }

    if (!mounted) return;
    setState(() {
      _photos.addAll(prepared);
      _isPickingPhotos = false;
    });

    if (picked.length > remaining) _showPhotoLimit();
  }

  void _showPhotoLimit() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.group_post_photo_limit(
            GroupPostComposerScreen.maxPhotos,
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removePhoto(_ComposerPhoto photo) {
    setState(() => _photos.remove(photo));
  }

  Future<void> _addLink() async {
    if (_isSubmitting) return;
    final draft = await GroupPostAddLinkSheet.show(context);
    if (draft == null || !mounted) return;
    setState(() => _link = draft);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final l10n = context.l10n;
    final post = _basePost;

    List<GroupPostMediaRequest>? media;
    if (post == null || _mediaChanged) {
      media = await _buildMediaRequests();
      if (!mounted) return;
      if (media == null) {
        setState(() => _isSubmitting = false);
        _showError(l10n.group_post_upload_error);
        return;
      }
    }

    final caption = _captionController.text.trim();
    final link = _link;
    final links = [
      if (link != null)
        GroupPostLinkRequest(
          type: link.type,
          url: link.url,
          label: _truncateLabel(link.title),
          displayOrder: 1,
        ),
    ];

    final saved =
        post == null
            ? await _create(
              caption: caption,
              media: media ?? const [],
              links: links,
            )
            : await _saveEdits(
              post,
              caption: caption,
              media: media,
              links: links,
            );
    if (!mounted) return;

    if (saved == null) {
      setState(() => _isSubmitting = false);
      _showError(
        post == null
            ? l10n.group_post_publish_error
            : l10n.group_post_update_error,
      );
      return;
    }
    Navigator.of(context).pop(GroupPostComposerResult(saved, saved: true));
  }

  /// Uploads new photos and lists every item in display order. Null when an
  /// upload failed or an existing item has no storage key to resend.
  Future<List<GroupPostMediaRequest>?> _buildMediaRequests() async {
    final repository = ref.read(groupPostRepositoryProvider);
    final keys = await Future.wait(
      _photos.map((photo) async {
        final source = photo.source;
        if (source != null) return source.mediaKey;
        if (photo.uploadedKey != null) return photo.uploadedKey;
        final upload = await repository.uploadMedia(photo.file!);
        return upload.fold((_) => null, (key) => key);
      }),
    );

    final media = <GroupPostMediaRequest>[];
    for (final (index, key) in keys.indexed) {
      if (key == null || key.isEmpty) return null;
      var photo = _photos[index];
      // Remember the key so a retry after a failed save doesn't re-upload.
      if (photo.source == null && photo.uploadedKey == null) {
        photo = photo.withUploadedKey(key);
        _photos[index] = photo;
      }
      final mediaType = photo.source?.mediaType ?? '';
      media.add(
        GroupPostMediaRequest(
          mediaType: mediaType.isNotEmpty ? mediaType : 'IMAGE',
          mediaKey: key,
          width: photo.width,
          height: photo.height,
          durationMs: photo.source?.durationMs,
          displayOrder: index + 1,
        ),
      );
    }
    return media;
  }

  Future<ConnectPost?> _create({
    required String caption,
    required List<GroupPostMediaRequest> media,
    required List<GroupPostLinkRequest> links,
  }) async {
    final result = await ref
        .read(groupPostRepositoryProvider)
        .createPost(
          widget.profile.id,
          CreateGroupPostRequest(caption: caption, media: media, links: links),
        );
    return result.fold((_) => null, (created) => created);
  }

  /// Only changed parts are sent. Falls back to a local copy when the API
  /// returns no body, so the list updates before its next fetch.
  Future<ConnectPost?> _saveEdits(
    ConnectPost post, {
    required String caption,
    required List<GroupPostMediaRequest>? media,
    required List<GroupPostLinkRequest> links,
  }) async {
    final result = await ref
        .read(groupPostRepositoryProvider)
        .updatePost(
          widget.profile.id,
          post.id,
          caption: _captionChanged ? caption : null,
          status: post.status.isNotEmpty ? post.status : 'PUBLISHED',
          media: media,
          links: _linkChanged ? links : null,
        );
    return result.fold(
      (failure) {
        if (failure is PartialPostUpdateFailure) {
          _recordPartialSave(post, failure, caption);
        }
        return null;
      },
      (updated) => updated ?? _applyEdits(post, caption: caption),
    );
  }

  /// Advances the base to what persisted so a retry only resends the rest.
  void _recordPartialSave(
    ConnectPost post,
    PartialPostUpdateFailure failure,
    String caption,
  ) {
    _basePost = _applyEdits(
      post,
      caption: failure.captionSaved ? caption : null,
      media: failure.mediaSaved,
      links: failure.linksSaved,
    );
  }

  ConnectPost _applyEdits(
    ConnectPost post, {
    String? caption,
    bool media = true,
    bool links = true,
  }) {
    final link = _link;
    return post.copyWith(
      caption: caption,
      media:
          !media
              ? null
              : [
                for (final (index, photo) in _photos.indexed)
                  photo.source ??
                      ConnectPostMedia(
                        id: '',
                        mediaType: 'IMAGE',
                        url: '',
                        width: photo.width,
                        height: photo.height,
                        displayOrder: index + 1,
                        mediaKey: photo.uploadedKey,
                      ),
              ],
      links:
          !links
              ? null
              : [
                if (link != null)
                  ConnectPostLink(
                    id: post.links.isNotEmpty ? post.links.first.id : '',
                    type: link.type,
                    url: link.url,
                    label: _truncateLabel(link.title),
                    displayOrder: 1,
                  ),
              ],
      updatedAt: DateTime.now(),
    );
  }

  String? _truncateLabel(String? label) {
    final trimmed = label?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (trimmed.length <= GroupPostComposerScreen.maxLinkLabelLength) {
      return trimmed;
    }
    return trimmed.substring(0, GroupPostComposerScreen.maxLinkLabelLength);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;

    return PopScope(
      canPop:
          !_shouldConfirmDiscard && !_isSubmitting && _partialResult == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _isSubmitting) return;
        if (!_shouldConfirmDiscard) {
          Navigator.of(context).pop(_partialResult);
          return;
        }
        _confirmDiscard();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(l10n, isDark, secondaryColor),
              _buildPostingTo(l10n, isDark, secondaryColor),
              Divider(height: 1, thickness: 1, color: dividerColor),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _captionController,
                        enabled: !_isSubmitting,
                        autofocus: true,
                        maxLines: null,
                        minLines: 3,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 16, height: 1.4),
                        decoration: InputDecoration(
                          hintText: l10n.group_post_caption_hint,
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: secondaryColor,
                          ),
                          // Undo the theme's fill and outline.
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                        ),
                      ),
                      if (_photos.isNotEmpty || _isPickingPhotos) ...[
                        const SizedBox(height: 12),
                        _buildPhotoGrid(isDark),
                      ],
                      if (_link != null) ...[
                        const SizedBox(height: 16),
                        ConnectPostLinkCard(
                          url: _link!.url,
                          label: _link!.title,
                          onTap: () {},
                          onRemove:
                              _isSubmitting
                                  ? null
                                  : () => setState(() => _link = null),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _buildBottomBar(l10n, isDark, secondaryColor, dividerColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    AppLocalizations l10n,
    bool isDark,
    Color secondaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
      child: Row(
        children: [
          TextButton(
            onPressed: _isSubmitting ? null : _onCancel,
            style: TextButton.styleFrom(
              foregroundColor: secondaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(l10n.cancel, style: const TextStyle(fontSize: 16)),
          ),
          Expanded(
            child: Text(
              _isEditing
                  ? l10n.group_post_edit_title
                  : l10n.group_post_new_title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: _canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
                foregroundColor:
                    isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
                disabledBackgroundColor:
                    isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
                disabledForegroundColor:
                    isDark ? AppColors.grey500 : AppColors.grey600,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child:
                  _isSubmitting
                      ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              isDark
                                  ? AppColors.textPrimary
                                  : AppColors.surfaceWhite,
                        ),
                      )
                      : Text(
                        _isEditing ? l10n.save : l10n.group_post_button,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostingTo(
    AppLocalizations l10n,
    bool isDark,
    Color secondaryColor,
  ) {
    final profile = widget.profile;
    final avatarUrl = profile.avatarUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        children: [
          Text(
            l10n.group_post_posting_to,
            style: TextStyle(fontSize: 13, color: secondaryColor),
          ),
          const SizedBox(width: 8),
          ClipOval(
            child: SizedBox(
              width: 22,
              height: 22,
              child:
                  avatarUrl != null && avatarUrl.isNotEmpty
                      ? CachedNetworkImageWidget(
                        imageUrl: avatarUrl,
                        width: 22,
                        height: 22,
                        fit: BoxFit.cover,
                        errorWidget: _avatarFallback(isDark),
                      )
                      : _avatarFallback(isDark),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              profile.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(bool isDark) {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.usersThree,
        size: 12,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
  }

  Widget _buildPhotoGrid(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final tileSize = (constraints.maxWidth - gap * 2) / 3;
        final canAddMore =
            _photos.length < GroupPostComposerScreen.maxPhotos &&
            !_isSubmitting;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final photo in _photos)
              SizedBox(
                width: tileSize,
                height: tileSize,
                child: _PhotoTile(
                  photo: photo,
                  onRemove: _isSubmitting ? null : () => _removePhoto(photo),
                ),
              ),
            if (_isPickingPhotos)
              SizedBox(
                width: tileSize,
                height: tileSize,
                child: _AddPhotoTile(isDark: isDark, isBusy: true),
              )
            else if (canAddMore)
              SizedBox(
                width: tileSize,
                height: tileSize,
                child: _AddPhotoTile(isDark: isDark, onTap: _pickPhotos),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBottomBar(
    AppLocalizations l10n,
    bool isDark,
    Color secondaryColor,
    Color dividerColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _ComposerAction(
                icon: AppAssets.photoLibrary,
                label: l10n.group_post_photos,
                color: secondaryColor,
                onTap: _isSubmitting || _isPickingPhotos ? null : _pickPhotos,
              ),
            ),
            Expanded(
              child: _ComposerAction(
                icon: AppAssets.linkSimple,
                label: l10n.group_post_link,
                color: secondaryColor,
                onTap: _isSubmitting ? null : _addLink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerAction extends StatelessWidget {
  const _ComposerAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor =
        onTap == null
            ? color
            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, this.onRemove});

  final _ComposerPhoto photo;
  final VoidCallback? onRemove;

  Widget _buildImage(BuildContext context) {
    final file = photo.file;
    if (file != null) return Image.file(file, fit: BoxFit.cover);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final source = photo.source;
    return CachedNetworkImageWidget(
      imageUrl: source?.thumbnailUrl ?? source?.url ?? '',
      fit: BoxFit.cover,
      errorWidget: ColoredBox(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
        child: Icon(
          AppAssets.photoLibrary,
          color: isDark ? AppColors.grey500 : AppColors.grey600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildImage(context),
        ),
        if (onRemove != null)
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: Colors.black.withValues(alpha: 0.6),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onRemove,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: Icon(AppAssets.x, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.isDark, this.onTap, this.isBusy = false});

  final bool isDark;
  final VoidCallback? onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.cardBorderDark : AppColors.grey300,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        child: Center(
          child:
              isBusy
                  ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Icon(
                    AppAssets.plus,
                    size: 28,
                    color: isDark ? AppColors.grey500 : AppColors.grey600,
                  ),
        ),
      ),
    );
  }
}

class _ComposerPhoto {
  final File? file;

  /// Set for media already on the server; kept by resending its key.
  final ConnectPostMedia? source;
  final int? width;
  final int? height;

  /// Storage key from a finished upload, reused if the save must be retried.
  final String? uploadedKey;

  const _ComposerPhoto({
    this.file,
    this.source,
    this.width,
    this.height,
    this.uploadedKey,
  });

  factory _ComposerPhoto.remote(ConnectPostMedia media) =>
      _ComposerPhoto(source: media, width: media.width, height: media.height);

  _ComposerPhoto withUploadedKey(String key) => _ComposerPhoto(
    file: file,
    source: source,
    width: width,
    height: height,
    uploadedKey: key,
  );

  /// Bakes the EXIF orientation into the pixels (some iOS builds keep it only
  /// as a tag) and reads the final size for the API.
  static Future<_ComposerPhoto> prepare(XFile picked, int index) async {
    var file = File(picked.path);
    try {
      final tmpDir = await getTemporaryDirectory();
      final destPath =
          '${tmpDir.path}/group_post_${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        destPath,
        quality: 85,
        autoCorrectionAngle: true,
      );
      if (result != null) file = File(result.path);
    } catch (_) {}

    int? width;
    int? height;
    try {
      final image = await decodeImageFromList(await file.readAsBytes());
      width = image.width;
      height = image.height;
      image.dispose();
    } catch (_) {}

    return _ComposerPhoto(file: file, width: width, height: height);
  }
}
