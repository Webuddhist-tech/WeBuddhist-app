import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_comments_sheet.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_of_day_content.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_of_day_engagement_bar.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_share_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VerseOfDayCard extends ConsumerStatefulWidget {
  const VerseOfDayCard({super.key, required this.verseOfDay});

  final VerseOfDay verseOfDay;

  @override
  ConsumerState<VerseOfDayCard> createState() => _VerseOfDayCardState();
}

class _VerseOfDayCardState extends ConsumerState<VerseOfDayCard> {
  final GlobalKey _shareIconKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _onShareTap() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);
    await shareVerseOfDayQuote(
      context,
      verseOfDay: widget.verseOfDay,
      shareOriginKey: _shareIconKey,
    );
    if (mounted) setState(() => _isSharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localeProvider).languageCode;
    final typography = VerseOfDayTypography.forCard(languageCode);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      child: InkWell(
        onTap: () => showVerseShareSheet(context, widget.verseOfDay),
        child: VerseOfDayContent(
          verseOfDay: widget.verseOfDay,
          typography: typography,
          useContentFontForAttribution: typography.useContentFontForAttribution,
          verseColor: colorScheme.onSurface,
          attributionColor:
              colorScheme.brightness == Brightness.dark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
          textAlign: TextAlign.start,
          attributionSpacing: 10,
          textPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          footer: VerseOfDayEngagementBar(
            verseId: widget.verseOfDay.id,
            onCommentTap:
                () => VerseCommentsSheet.show(
                  context,
                  verseId: widget.verseOfDay.id,
                ),
            trailing: GestureDetector(
              key: _shareIconKey,
              onTap: _isSharing ? null : _onShareTap,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 32,
                height: 32,
                child:
                    _isSharing
                        ? Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                        : Icon(
                          AppAssets.readerShare,
                          color: colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
