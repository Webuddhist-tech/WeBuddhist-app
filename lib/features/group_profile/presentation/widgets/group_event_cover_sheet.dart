import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Picks the event cover: the group's own cover or a photo from the device.
class GroupEventCoverSheet extends StatefulWidget {
  final String? groupCoverUrl;
  final GroupEventCover? current;

  const GroupEventCoverSheet({super.key, this.groupCoverUrl, this.current});

  /// Pops with the chosen cover, or null when dismissed.
  static Future<GroupEventCover?> show(
    BuildContext context, {
    String? groupCoverUrl,
    GroupEventCover? current,
  }) {
    return showModalBottomSheet<GroupEventCover>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder:
          (_) => GroupEventCoverSheet(
            groupCoverUrl: groupCoverUrl,
            current: current,
          ),
    );
  }

  @override
  State<GroupEventCoverSheet> createState() => _GroupEventCoverSheetState();
}

class _GroupEventCoverSheetState extends State<GroupEventCoverSheet> {
  GroupEventCover? _selected;
  File? _picked;
  bool _isPicking = false;

  String? get _groupCoverUrl {
    final url = widget.groupCoverUrl?.trim();
    return url != null && url.isNotEmpty ? url : null;
  }

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
    if (widget.current case GroupEventCoverFile(:final file)) _picked = file;
  }

  Future<void> _pickPhoto() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
    } catch (_) {
      picked = null;
    }

    File? file;
    if (picked != null) file = await _prepare(picked);

    if (!mounted) return;
    setState(() {
      _isPicking = false;
      if (file != null) {
        _picked = file;
        _selected = GroupEventCoverFile(file);
      }
    });
  }

  /// Bakes the EXIF orientation into the pixels, like the post composer.
  static Future<File> _prepare(XFile picked) async {
    var file = File(picked.path);
    try {
      final tmpDir = await getTemporaryDirectory();
      final destPath =
          '${tmpDir.path}/group_event_cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        destPath,
        quality: 85,
        autoCorrectionAngle: true,
      );
      if (result != null) file = File(result.path);
    } catch (_) {}
    return file;
  }

  bool _isSelected(GroupEventCover candidate) {
    return switch ((_selected, candidate)) {
      (GroupEventCoverUrl a, GroupEventCoverUrl b) => a.url == b.url,
      (GroupEventCoverFile a, GroupEventCoverFile b) =>
        a.file.path == b.file.path,
      _ => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final groupCoverUrl = _groupCoverUrl;
    final picked = _picked;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.group_event_cover_image,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(AppAssets.x),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: dividerColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 8.0;
                  final tileSize = (constraints.maxWidth - gap * 2) / 3;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      if (groupCoverUrl != null)
                        _CoverTile(
                          size: tileSize,
                          label: l10n.group_event_cover_group_cover,
                          selected: _isSelected(
                            GroupEventCoverUrl(groupCoverUrl),
                          ),
                          onTap:
                              () => setState(
                                () =>
                                    _selected = GroupEventCoverUrl(
                                      groupCoverUrl,
                                    ),
                              ),
                          child: CachedNetworkImageWidget(
                            imageUrl: groupCoverUrl,
                            fit: BoxFit.cover,
                            errorWidget: _ImageFallback(isDark: isDark),
                          ),
                        ),
                      if (picked != null)
                        _CoverTile(
                          size: tileSize,
                          selected: _isSelected(GroupEventCoverFile(picked)),
                          onTap:
                              () => setState(
                                () => _selected = GroupEventCoverFile(picked),
                              ),
                          child: Image.file(picked, fit: BoxFit.cover),
                        ),
                      _PickPhotoTile(
                        size: tileSize,
                        isDark: isDark,
                        isBusy: _isPicking,
                        label: l10n.group_event_cover_choose_photo,
                        onTap: _pickPhoto,
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text(
                l10n.group_event_cover_hint,
                style: TextStyle(fontSize: 12, color: secondaryColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      _selected == null || _isPicking
                          ? null
                          : () => Navigator.of(context).pop(_selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
                    foregroundColor:
                        isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
                    disabledBackgroundColor:
                        isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.grey100,
                    disabledForegroundColor:
                        isDark ? AppColors.grey500 : AppColors.grey600,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.group_event_cover_use,
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
      ),
    );
  }
}

class _CoverTile extends StatelessWidget {
  const _CoverTile({
    required this.size,
    required this.selected,
    required this.onTap,
    required this.child,
    this.label,
  });

  final double size;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        selected
            ? (isDark ? AppColors.surfaceWhite : AppColors.textPrimary)
            : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (label != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                  child: Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PickPhotoTile extends StatelessWidget {
  const _PickPhotoTile({
    required this.size,
    required this.isDark,
    required this.isBusy,
    required this.label,
    required this.onTap,
  });

  final double size;
  final bool isDark;
  final bool isBusy;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.grey500 : AppColors.grey600;
    return SizedBox(
      width: size,
      height: size,
      child: Material(
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
                    : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppAssets.photoLibrary, size: 26, color: color),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: color),
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.image,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
  }
}
