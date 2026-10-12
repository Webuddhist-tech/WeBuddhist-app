import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/utils/network_image_utils.dart';

/// Displays the circular profile avatar with an upload-in-progress overlay
/// and a small edit button in the bottom-right corner.
class ProfileAvatarSection extends StatelessWidget {
  const ProfileAvatarSection({
    super.key,
    required this.avatarUrl,
    required this.isUploadingAvatar,
    required this.pickedAvatarFile,
    required this.onEditTap,
  });

  final String avatarUrl;
  final bool isUploadingAvatar;
  final File? pickedAvatarFile;

  /// Called when the user taps the edit button. Disabled while uploading.
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final image = _resolveImage();
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Hero(
            tag: 'profile-avatar',
            child: CircleAvatar(
              radius: 52,
              backgroundColor: AppColors.grey300,
              backgroundImage: image,
              onBackgroundImageError:
                  image != null ? ignoreImageLoadError : null,
              child: avatarUrl.isEmpty && pickedAvatarFile == null
                  ? Icon(
                      AppAssets.profile,
                      size: 44,
                      color: AppColors.grey600,
                    )
                  : null,
            ),
          ),
          if (isUploadingAvatar) _UploadingOverlay(),
          Positioned(
            bottom: 0,
            right: 0,
            child: _EditButton(
              onTap: isUploadingAvatar ? null : onEditTap,
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _resolveImage() {
    if (pickedAvatarFile != null) return FileImage(pickedAvatarFile!);
    if (avatarUrl.isNotEmpty) return avatarUrl.cachedNetworkImageProvider;
    return null;
  }
}

class _UploadingOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 18),
      ),
    );
  }
}
