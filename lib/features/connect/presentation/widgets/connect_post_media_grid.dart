import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';

/// Post photos laid out like the feed design: one photo at its own shape, two
/// side by side, three as two over one, four or more as a 2x2 grid whose last
/// tile shows how many photos are left.
class ConnectPostMediaGrid extends StatelessWidget {
  const ConnectPostMediaGrid({
    super.key,
    required this.media,
    required this.isDark,
    required this.onTapImage,
    this.onDoubleTap,
    this.borderRadius = BorderRadius.zero,
  });

  static const maxVisible = 4;
  static const gap = 2.0;

  final List<ConnectPostMedia> media;
  final bool isDark;

  /// Called with the index in [media] of the tapped photo.
  final ValueChanged<int> onTapImage;
  final VoidCallback? onDoubleTap;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();

    final Widget grid;
    switch (media.length) {
      case 1:
        grid = _singleImage(media.first);
      case 2:
        grid = AspectRatio(aspectRatio: 2, child: Row(children: _row([0, 1])));
      case 3:
        grid = AspectRatio(
          aspectRatio: 1,
          child: Column(
            children: [
              Expanded(child: Row(children: _row([0, 1]))),
              const SizedBox(height: gap),
              Expanded(child: _tile(2)),
            ],
          ),
        );
      default:
        grid = AspectRatio(
          aspectRatio: 1,
          child: Column(
            children: [
              Expanded(child: Row(children: _row([0, 1]))),
              const SizedBox(height: gap),
              Expanded(child: Row(children: _row([2, 3]))),
            ],
          ),
        );
    }

    return ClipRRect(borderRadius: borderRadius, child: grid);
  }

  List<Widget> _row(List<int> indexes) {
    return [
      for (var i = 0; i < indexes.length; i++) ...[
        if (i > 0) const SizedBox(width: gap),
        Expanded(child: _tile(indexes[i])),
      ],
    ];
  }

  Widget _tile(int index) {
    final hiddenCount = media.length - maxVisible;
    final showsHiddenCount = index == maxVisible - 1 && hiddenCount > 0;

    return GestureDetector(
      key: ValueKey('connect_post_media_tile_$index'),
      onTap: () => onTapImage(index),
      onDoubleTap: onDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImageWidget(
            imageUrl: media[index].url,
            fit: BoxFit.cover,
            errorWidget: _errorWidget(),
          ),
          if (showsHiddenCount)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.45),
              child: Center(
                child: Text(
                  '+$hiddenCount',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _singleImage(ConnectPostMedia item) {
    final width = item.width;
    final height = item.height;
    final Widget image;
    if (width != null && height != null && width > 0 && height > 0) {
      image = AspectRatio(
        aspectRatio: width / height,
        child: CachedNetworkImageWidget(
          imageUrl: item.url,
          fit: BoxFit.cover,
          errorWidget: _errorWidget(),
        ),
      );
    } else {
      image = CachedNetworkImageWidget(
        imageUrl: item.url,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        errorWidget: _errorWidget(),
      );
    }

    return GestureDetector(
      key: const ValueKey('connect_post_media_tile_0'),
      onTap: () => onTapImage(0),
      onDoubleTap: onDoubleTap,
      child: image,
    );
  }

  Widget _errorWidget() {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.photoLibrary,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
  }
}
