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

  @override
  Widget build(BuildContext context) {
    final beadUrl = mantra.mantra?.beadImageUrl ?? mantra.beadImageUrl;
    final title = mantra.displayTitle(language);

    const baseTitleStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      height: 1.25,
    );
    final titleStyle =
        AppFontConfig.applyTibetanMetrics(
          language,
          baseTitleStyle,
          compact: true,
        ) ??
        baseTitleStyle;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(
                child:
                    beadUrl != null && beadUrl.isNotEmpty
                        ? CachedNetworkImageWidget(
                          imageUrl: beadUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        )
                        : Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.surfaceContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.spa, size: 28),
                        ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: titleStyle.fontSize! * titleStyle.height! * 2,
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
