import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

class PlanCoverImage extends StatelessWidget {
  final ResponsiveImage? image;
  final double? height;

  /// Full width with square corners, for headers that bleed to the edges.
  final bool edgeToEdge;

  const PlanCoverImage({
    super.key,
    required this.image,
    this.height,
    this.edgeToEdge = false,
  });

  @override
  Widget build(BuildContext context) {
    final double resolvedHeight =
        height ?? MediaQuery.of(context).size.height * 0.3;
    final radius = edgeToEdge ? BorderRadius.zero : BorderRadius.circular(12);

    return Container(
      height: resolvedHeight,
      width: double.infinity,
      margin:
          edgeToEdge
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(borderRadius: radius),
      child: ResponsiveCoverImage(
        image: image,
        width: double.infinity,
        height: resolvedHeight,
        fit: BoxFit.cover,
        borderRadius: radius,
        errorWidget: const Center(child: Icon(Icons.broken_image, size: 80)),
      ),
    );
  }
}
