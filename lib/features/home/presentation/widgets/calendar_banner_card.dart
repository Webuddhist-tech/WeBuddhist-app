import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';

class CalendarBannerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String celebratedBy;
  final String? imageUrl;

  const CalendarBannerCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.celebratedBy,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: title,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.272,
                        ),
                      ),
                      TextSpan(
                        text: ' / $subtitle',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Instrument Serif',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.home_celebrated_by,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        border: Border.all(color: const Color(0xFFFBF9F4)),
                        borderRadius: BorderRadius.circular(10.5),
                      ),
                      child: Text(
                        celebratedBy,
                        style: const TextStyle(
                          color: Color(0xFFFBF9F4),
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (imageUrl != null && imageUrl!.isNotEmpty) ...[
            const SizedBox(width: 12),
            CachedNetworkImageWidget(
              imageUrl: imageUrl!,
              width: 76,
              height: 66.5,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(8),
              errorWidget: Container(
                width: 76,
                height: 66.5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
