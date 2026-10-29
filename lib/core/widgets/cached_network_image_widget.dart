import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/cache/app_image_cache_manager.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/network_image_utils.dart';

bool _isAssetPath(String url) => url.trim().startsWith('assets/');

bool _isNetworkUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  return uri != null &&
      uri.hasScheme &&
      (uri.scheme == 'http' || uri.scheme == 'https');
}

/// Converts a logical dimension to physical pixels for cache sizing. Returns
/// null when the dimension is null, non-finite (e.g. `double.infinity`), or
/// non-positive — in those cases the framework should decode at natural size.
int? _toCachePx(double? logical, double dpr) {
  if (logical == null || !logical.isFinite || logical <= 0) return null;
  return (logical * dpr).round();
}

/// Strips the query string and fragment so presigned URLs (e.g. S3 with
/// rotating signatures) resolve to the same cache entry across sessions.
String _stableCacheKey(String url) => stableNetworkImageCacheKey(url);

/// Returns a single-axis cache size for fits that decode along one dimension.
/// Returns null when both cache dimensions should be retained.
(int? memCacheWidth, int? memCacheHeight)? _singleAxisCacheDimensions({
  required BoxFit fit,
  required int autoWidth,
  required int autoHeight,
}) {
  switch (fit) {
    case BoxFit.fitWidth:
      return (autoWidth, null);
    case BoxFit.fitHeight:
      return (null, autoHeight);
    case BoxFit.cover:
      return autoWidth >= autoHeight ? (autoWidth, null) : (null, autoHeight);
    case BoxFit.contain:
      // For contain, constrain by the larger dimension to prevent stretching
      // while maintaining aspect ratio during decode
      return autoWidth >= autoHeight ? (autoWidth, null) : (null, autoHeight);
    case BoxFit.fill:
    case BoxFit.none:
    case BoxFit.scaleDown:
      return null;
  }
}

(int? memCacheWidth, int? memCacheHeight) _resolveMemCacheDimensions({
  required double devicePixelRatio,
  required BoxFit fit,
  double? width,
  double? height,
  int? memCacheWidth,
  int? memCacheHeight,
}) {
  if (memCacheWidth != null || memCacheHeight != null) {
    return (memCacheWidth, memCacheHeight);
  }

  final autoWidth = _toCachePx(width, devicePixelRatio);
  final autoHeight = _toCachePx(height, devicePixelRatio);

  if (autoWidth != null && autoHeight != null) {
    final singleAxis = _singleAxisCacheDimensions(
      fit: fit,
      autoWidth: autoWidth,
      autoHeight: autoHeight,
    );
    if (singleAxis != null) return singleAxis;
  }

  return (autoWidth, autoHeight);
}

class CachedNetworkImageWidget extends StatelessWidget {
  /// Remote http(s) URL, or a bundled asset path starting with `assets/`.
  final String? imageUrl;

  /// Shown when [imageUrl] is null/empty, or when a network image fails to load.
  final String? fallbackAsset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? heroTag;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration? placeholderFadeInDuration;
  final Duration? fadeInDuration;
  final VoidCallback? onImageLoaded;

  /// Explicit decode width in physical pixels. When null and [width] is set,
  /// it is auto-derived from `width * devicePixelRatio`.
  final int? memCacheWidth;

  /// Explicit decode height in physical pixels. When null and [height] is set,
  /// it is auto-derived from `height * devicePixelRatio`.
  final int? memCacheHeight;

  const CachedNetworkImageWidget({
    super.key,
    this.imageUrl,
    this.fallbackAsset,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.heroTag,
    this.placeholder,
    this.errorWidget,
    this.placeholderFadeInDuration,
    this.fadeInDuration,
    this.onImageLoaded,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = imageUrl?.trim();
    final url = (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;

    Widget imageWidget;

    if (url != null && _isAssetPath(url)) {
      imageWidget = _buildAssetImage(url, context);
    } else if (url != null && _isNetworkUrl(url)) {
      imageWidget = _buildNetworkImage(url, context);
    } else if (url != null) {
      imageWidget =
          fallbackAsset != null
              ? _buildAssetImage(fallbackAsset!, context)
              : _buildErrorWidget(context);
    } else if (fallbackAsset != null) {
      imageWidget = _buildAssetImage(fallbackAsset!, context);
    } else {
      imageWidget = _buildErrorWidget(context);
    }

    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    if (heroTag != null && heroTag!.isNotEmpty) {
      imageWidget = Hero(tag: heroTag!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildNetworkImage(String url, BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final (memW, memH) = _resolveMemCacheDimensions(
      devicePixelRatio: dpr,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
    );
    if (memW != null || memH != null) {
      return _networkImage(url, memW, memH);
    }

    // No bound from the caller: derive one from the layout so a full-width
    // cover is never decoded at its natural size.
    return LayoutBuilder(
      builder: (context, constraints) {
        final (layoutW, layoutH) = _resolveMemCacheDimensions(
          devicePixelRatio: dpr,
          fit: fit,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );
        return _networkImage(url, layoutW, layoutH);
      },
    );
  }

  Widget _networkImage(String url, int? memW, int? memH) {
    final cacheKey = _stableCacheKey(url);
    final fadeIn = fadeInDuration ?? const Duration(milliseconds: 200);

    Widget image = CachedNetworkImage(
      imageUrl: url,
      cacheKey: cacheKey,
      cacheManager: appImageCacheManager,
      width: width,
      height: height,
      fit: fit,
      // Memory decode only. `maxWidthDiskCache` / `maxHeightDiskCache`
      // used to be set from the same pair, which made the *stored file*
      // depend on the size of whichever widget requested it first — while
      // the cache key deliberately does not include that size. Two widgets
      // showing one image at different sizes then fight over a single
      // entry, and the loser can sit on its placeholder indefinitely: a
      // stalled re-encode never resolves and never errors, so no
      // `errorWidget` is reached either.
      //
      // Dropping them costs some disk, since the original is stored rather
      // than a shrunken copy, and keeps the whole memory benefit —
      // `memCacheWidth` / `memCacheHeight` are what bound the decode.
      memCacheWidth: memW,
      memCacheHeight: memH,
      fadeInDuration: fadeIn,
      // Crossfade placeholder and image together; the package default keeps
      // the placeholder on top for a full second.
      fadeOutDuration: fadeIn,
      placeholderFadeInDuration: placeholderFadeInDuration ?? Duration.zero,
      // A re-signed or replaced URL keeps the old image until the new one is
      // decoded, like stale-while-revalidate for data.
      useOldImageOnUrlChange: true,
      placeholder:
          placeholder != null
              ? (context, url) => placeholder!
              : (context, url) => _buildLoadingPlaceholder(context),
      errorWidget:
          errorWidget != null
              ? (context, url, error) => errorWidget!
              : (context, url, error) =>
                  fallbackAsset != null
                      ? _buildAssetImage(fallbackAsset!, context)
                      : _buildErrorWidget(context),
    );

    if (onImageLoaded != null) {
      // Same provider and resize key as the painted image, so listening never
      // triggers a second decode.
      image = _ImageLoadedNotifier(
        onImageLoaded: onImageLoaded!,
        provider: ResizeImage.resizeIfNeeded(
          memW,
          memH,
          CachedNetworkImageProvider(
            url,
            cacheKey: cacheKey,
            cacheManager: appImageCacheManager,
          ),
        ),
        child: image,
      );
    }
    return image;
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
    );
  }

  Widget _buildAssetImage(String assetPath, BuildContext context) {
    // Bundled art is authored at full display size, so without an explicit
    // bound a 1280x720 fallback decodes at natural size even inside a 56px
    // thumbnail. Reuse the network sizing so `cover`/`contain` stay on one
    // axis — passing both axes would resize the decode to an exact box and
    // distort the image.
    final (cacheWidth, cacheHeight) = _resolveMemCacheDimensions(
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
    );

    Widget image = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      errorBuilder:
          (context, error, stackTrace) =>
              errorWidget ?? _buildErrorWidget(context),
    );

    if (onImageLoaded != null) {
      image = _ImageLoadedNotifier(
        onImageLoaded: onImageLoaded!,
        provider: ResizeImage.resizeIfNeeded(
          cacheWidth,
          cacheHeight,
          AssetImage(assetPath),
        ),
        child: image,
      );
    }
    return image;
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
      ),
    );
  }
}

class _ImageLoadedNotifier extends StatefulWidget {
  final Widget child;
  final VoidCallback onImageLoaded;
  final ImageProvider provider;

  const _ImageLoadedNotifier({
    required this.child,
    required this.onImageLoaded,
    required this.provider,
  });

  @override
  State<_ImageLoadedNotifier> createState() => _ImageLoadedNotifierState();
}

class _ImageLoadedNotifierState extends State<_ImageLoadedNotifier> {
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  bool _hasCalledCallback = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_imageStream != null) return;
    _imageStream = widget.provider.resolve(
      createLocalImageConfiguration(context),
    );
    _imageStreamListener = ImageStreamListener((
      ImageInfo image,
      bool synchronousCall,
    ) {
      if (!_hasCalledCallback && mounted) {
        _hasCalledCallback = true;
        widget.onImageLoaded();
      }
    }, onError: (exception, stackTrace) {});
    _imageStream!.addListener(_imageStreamListener!);
  }

  @override
  void dispose() {
    if (_imageStreamListener != null) {
      _imageStream?.removeListener(_imageStreamListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

extension CachedNetworkImageProviderExtension on String {
  ImageProvider get cachedNetworkImageProvider {
    return CachedNetworkImageProvider(
      this,
      cacheKey: _stableCacheKey(this),
      cacheManager: appImageCacheManager,
    );
  }
}
