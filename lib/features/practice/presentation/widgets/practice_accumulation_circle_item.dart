import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';

class PracticeAccumulationCircleItem extends StatelessWidget {
  const PracticeAccumulationCircleItem({
    super.key,
    required this.mantra,
    required this.language,
    required this.onTap,
  });

  final Mantra mantra;
  final String language;
  final VoidCallback onTap;

  static const itemWidth = 110.0;
  static const beadSize = 70.0;
  static const _labelGap = 8.0;
  static const _labelMaxLines = 2;
  static const _titleStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    height: 1.33,
  );

  // Label height follows the device text scale so large fonts never clip.
  static double labelHeightOf(BuildContext context) {
    final scaledFont = MediaQuery.textScalerOf(
      context,
    ).scale(_titleStyle.fontSize!);
    return scaledFont * _titleStyle.height! * _labelMaxLines;
  }

  static double heightOf(BuildContext context) =>
      beadSize + _labelGap + labelHeightOf(context);

  @override
  Widget build(BuildContext context) {
    final beadUrl = mantra.mantra?.beadImageUrl ?? mantra.beadImageUrl;
    final title = mantra.displayTitle(language);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: itemWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipOval(
              child:
                  beadUrl != null && beadUrl.isNotEmpty
                      ? CachedNetworkImageWidget(
                        imageUrl: beadUrl,
                        width: beadSize,
                        height: beadSize,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        width: beadSize,
                        height: beadSize,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.spa, size: 24),
                      ),
            ),
            const SizedBox(height: _labelGap),
            SizedBox(
              height: labelHeightOf(context),
              child: Text(
                title,
                style: _titleStyle,
                textAlign: TextAlign.center,
                maxLines: _labelMaxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
