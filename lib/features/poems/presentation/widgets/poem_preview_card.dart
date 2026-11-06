import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poem.dart';
import 'package:flutter_pecha/features/poems/presentation/utils/poem_share.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single poem preview shown on the home page — cover image, title, a
/// truncated excerpt, and the author, matching the "Poems" home section.
///
/// Tapping the card opens the full-screen swipeable poems viewer starting on
/// this poem.
class PoemPreviewCard extends ConsumerWidget {
  const PoemPreviewCard({super.key, required this.poem, required this.onTap});

  /// Cover frame from the Figma home Poem / Card (`21711:2611`): 324 × 190.
  static const coverWidth = 324.0;
  static const coverHeight = 190.0;

  /// Room under the cover for title, excerpt, and the author row. Fits a
  /// 2-line title and 3-line excerpt at normal text size; with larger text
  /// the excerpt shows fewer lines instead of shrinking the cover.
  static const textAreaHeight = 190.0;

  static double coverHeightFor(double width) =>
      width * coverHeight / coverWidth;

  /// Full card height for a carousel page [width] wide, so every card's cover
  /// keeps the design ratio.
  static double heightFor(double width) =>
      coverHeightFor(width) + textAreaHeight;

  final Poem poem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final languageCode = ref.watch(contentLanguageProvider);
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final primaryColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final placeholderColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.grey100;
    final excerptStyle = TextStyle(
      fontSize: 14,
      color: secondaryColor,
      height: 1.5,
    );

    return InkWell(
      onTap: onTap,
      child: CustomMultiChildLayout(
        delegate: _PoemCardLayout(),
        children: [
          LayoutId(
            id: _PoemCardSlot.cover,
            child:
                poem.imageUrl != null && poem.imageUrl!.isNotEmpty
                    ? CachedNetworkImageWidget(
                      imageUrl: poem.imageUrl,
                      fit: BoxFit.cover,
                    )
                    : ColoredBox(
                      color: placeholderColor,
                      child: Icon(
                        AppAssets.bookOpenText,
                        size: 40,
                        color: isDark ? AppColors.grey500 : AppColors.grey600,
                      ),
                    ),
          ),
          LayoutId(
            id: _PoemCardSlot.title,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text(
                poem.title,
                textAlign: TextAlign.center,
                style: AppFontConfig.applyTibetanMetrics(
                  languageCode,
                  TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                    height: 1.3,
                  ),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          LayoutId(
            id: _PoemCardSlot.excerpt,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _PoemPreviewExcerpt(
                content: poem.content,
                style:
                    AppFontConfig.applyTibetanMetrics(
                      languageCode,
                      excerptStyle,
                    ) ??
                    excerptStyle,
              ),
            ),
          ),
          LayoutId(
            id: _PoemCardSlot.footer,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 4, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      poem.authorName,
                      style: AppFontConfig.applyTibetanMetrics(
                        languageCode,
                        TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                          height: 1.2,
                        ),
                        compact: true,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => sharePoem(context, poem),
                    icon: Icon(
                      AppAssets.readerShare,
                      size: 20,
                      color: secondaryColor,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    tooltip: context.l10n.share,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PoemCardSlot { cover, title, excerpt, footer }

/// Cover on top at the design ratio, then title and excerpt, with author and
/// share pinned to the bottom.
///
/// The cover never shrinks. When the text does not fit, the title is clipped
/// and the excerpt drops lines, so the space comes out of the content.
class _PoemCardLayout extends MultiChildLayoutDelegate {
  @override
  void performLayout(Size size) {
    final coverHeight = PoemPreviewCard.coverHeightFor(
      size.width,
    ).clamp(0.0, size.height);
    layoutChild(
      _PoemCardSlot.cover,
      BoxConstraints.tight(Size(size.width, coverHeight)),
    );

    final footer = layoutChild(
      _PoemCardSlot.footer,
      BoxConstraints.tightFor(width: size.width),
    );
    var room = size.height - coverHeight - footer.height;
    if (room < 0) room = 0;

    final title = layoutChild(
      _PoemCardSlot.title,
      BoxConstraints(
        minWidth: size.width,
        maxWidth: size.width,
        maxHeight: room,
      ),
    );
    room -= title.height;
    if (room < 0) room = 0;

    layoutChild(
      _PoemCardSlot.excerpt,
      BoxConstraints(
        minWidth: size.width,
        maxWidth: size.width,
        maxHeight: room,
      ),
    );

    positionChild(_PoemCardSlot.cover, Offset.zero);
    positionChild(_PoemCardSlot.title, Offset(0, coverHeight));
    positionChild(_PoemCardSlot.excerpt, Offset(0, coverHeight + title.height));
    positionChild(_PoemCardSlot.footer, Offset(0, size.height - footer.height));
  }

  @override
  bool shouldRelayout(_PoemCardLayout oldDelegate) => false;
}

/// Shows poem lines with their original breaks and appends `...` when clipped.
///
/// Shows up to 3 lines, fewer when the card has less height left.
class _PoemPreviewExcerpt extends StatelessWidget {
  const _PoemPreviewExcerpt({required this.content, required this.style});

  final String content;
  final TextStyle style;

  static const _maxLines = 3;
  static const _ellipsis = '...';

  int _linesThatFit(
    double maxHeight,
    TextDirection textDirection,
    TextScaler textScaler,
  ) {
    if (!maxHeight.isFinite) return _maxLines;
    final lineHeight =
        (TextPainter(
          text: TextSpan(text: content, style: style),
          maxLines: 1,
          textDirection: textDirection,
          textScaler: textScaler,
        )..layout()).height;
    if (lineHeight <= 0) return _maxLines;
    return (maxHeight / lineHeight).floor().clamp(0, _maxLines);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textDirection = Directionality.of(context);
        final textScaler = MediaQuery.textScalerOf(context);
        final maxLines = _linesThatFit(
          constraints.maxHeight,
          textDirection,
          textScaler,
        );
        if (maxLines == 0) return const SizedBox.shrink();

        final textSpan = TextSpan(text: content, style: style);
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: maxLines,
          textDirection: textDirection,
          textScaler: textScaler,
        )..layout(maxWidth: constraints.maxWidth);

        if (!textPainter.didExceedMaxLines) {
          return Text(content, style: style, textAlign: TextAlign.center);
        }

        final ellipsisSpan = TextSpan(text: _ellipsis, style: style);

        var endIndex = content.length;
        var startIndex = 0;

        while (startIndex < endIndex) {
          final mid = startIndex + ((endIndex - startIndex) ~/ 2);
          final testPainter = TextPainter(
            text: TextSpan(
              text: content.substring(0, mid),
              style: style,
              children: [ellipsisSpan],
            ),
            maxLines: maxLines,
            textDirection: textDirection,
            textScaler: textScaler,
          )..layout(maxWidth: constraints.maxWidth);

          if (testPainter.didExceedMaxLines) {
            endIndex = mid;
          } else {
            startIndex = mid + 1;
          }
        }

        final validLength = (startIndex - 1).clamp(0, content.length);
        final truncatedText = content.substring(0, validLength).trimRight();

        return Text.rich(
          TextSpan(text: truncatedText, style: style, children: [ellipsisSpan]),
          textAlign: TextAlign.center,
        );
      },
    );
  }
}
