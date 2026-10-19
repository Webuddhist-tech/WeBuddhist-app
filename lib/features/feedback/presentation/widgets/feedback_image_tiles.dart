import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/widgets/dashed_rounded_border_painter.dart';

/// The dashed "+" tile that opens the photo picker.
class FeedbackAddImageTile extends StatelessWidget {
  const FeedbackAddImageTile({
    super.key,
    required this.size,
    required this.color,
    required this.onTap,
    required this.loading,
    required this.tooltip,
  });

  final double size;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(
            painter: DashedRoundedBorderPainter(
              color: color,
              radius: 12,
              dashWidth: 5,
            ),
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child:
                    loading
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        )
                        : Icon(AppAssets.plus, size: 28, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A picked photo, with a button to take it out again.
class FeedbackImageThumb extends StatelessWidget {
  const FeedbackImageThumb({
    super.key,
    required this.file,
    required this.size,
    required this.onRemove,
  });

  final File file;
  final double size;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              file,
              fit: BoxFit.cover,
              cacheWidth: (size * 3).round(),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black.withValues(alpha: 0.6),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(AppAssets.x, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
