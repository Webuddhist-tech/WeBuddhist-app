import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';

class PracticeAccumulationItem extends StatelessWidget {
  const PracticeAccumulationItem({
    super.key,
    required this.mantra,
    required this.language,
    required this.onTap,
  });

  final Mantra mantra;
  final String language;
  final VoidCallback onTap;

  static const int _columns = 2;
  static const double _aspectRatio = 1.1;
  static const double _margin = 8;
  static const double _padding = 16;
  static const double _imageSize = 64;
  static const double _titleGap = 8;
  static const TextStyle _baseTitleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    height: 1.25,
  );

  static TextStyle _titleStyleFor(String language) =>
      AppFontConfig.applyTibetanMetrics(
        language,
        _baseTitleStyle,
        compact: true,
      ) ??
      _baseTitleStyle;

  static double _titleHeight(TextStyle style) =>
      style.fontSize! * style.height! * 2;

  static double _tileHeight(TextStyle titleStyle) =>
      (_margin + _padding) * 2 +
      _imageSize +
      _titleGap +
      _titleHeight(titleStyle);

  /// Keeps the 1.1 tile unless the content (e.g. a Tibetan title) needs more.
  static SliverGridDelegate gridDelegate(String language, double gridWidth) =>
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns,
        mainAxisExtent: math.max(
          gridWidth / _columns / _aspectRatio,
          _tileHeight(_titleStyleFor(language)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final beadUrl = mantra.mantra?.beadImageUrl ?? mantra.beadImageUrl;
    final title = mantra.displayTitle(language);
    final titleStyle = _titleStyleFor(language);

    return Card(
      margin: const EdgeInsets.all(_margin),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(_padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(
                child:
                    beadUrl != null && beadUrl.isNotEmpty
                        ? CachedNetworkImageWidget(
                          imageUrl: beadUrl,
                          width: _imageSize,
                          height: _imageSize,
                          fit: BoxFit.cover,
                        )
                        : Container(
                          width: _imageSize,
                          height: _imageSize,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.surfaceContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.spa, size: 28),
                        ),
              ),
              const SizedBox(height: _titleGap),
              SizedBox(
                height: _titleHeight(titleStyle),
                child: Text(
                  title,
                  style: titleStyle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
