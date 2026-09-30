import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poem.dart';
import 'package:flutter_pecha/features/poems/presentation/providers/poems_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single page inside the full-screen poems viewer. Scrolling collapses the
/// cover image; the title moves into the viewer top bar once it scrolls off,
/// while poem body, author, and chapter scroll together below.
class PoemStoryPage extends ConsumerStatefulWidget {
  const PoemStoryPage({super.key, required this.poem});

  final Poem poem;

  static const horizontalPadding = 24.0;
  static const contentHorizontalPadding = 28.0;

  @override
  ConsumerState<PoemStoryPage> createState() => _PoemStoryPageState();
}

class _PoemStoryPageState extends ConsumerState<PoemStoryPage> {
  static const _topBarHeight = 56.0;

  final GlobalKey _titleKey = GlobalKey();

  void _syncAppBarTitleVisibility() {
    if (!mounted) return;

    final titleContext = _titleKey.currentContext;
    if (titleContext == null) return;

    final renderBox = titleContext.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final titleBottom =
        renderBox.localToGlobal(Offset(0, renderBox.size.height)).dy;
    final collapseThreshold =
        MediaQuery.paddingOf(titleContext).top + _topBarHeight;
    final shouldShow = titleBottom <= collapseThreshold;

    final current = ref.read(
      poemViewerAppBarTitleVisibleProvider(widget.poem.id),
    );
    if (current != shouldShow) {
      ref
          .read(poemViewerAppBarTitleVisibleProvider(widget.poem.id).notifier)
          .state = shouldShow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final poem = widget.poem;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final placeholderColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.grey100;
    final backgroundColor =
        isDark
            ? AppColors.scaffoldBackgroundDark
            : AppColors.scaffoldBackgroundLight;
    final imageHeight = MediaQuery.sizeOf(context).height * 0.32;
    final languageCode = ref.watch(contentLanguageProvider);
    final isTibetan = AppFontConfig.isTibetanLanguage(languageCode);
    // Tibetan glyphs sit tall above the baseline, so give the title extra room.
    final titleTopPadding = isTibetan ? 20.0 : 8.0;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification ||
            notification is ScrollEndNotification) {
          _syncAppBarTitleVisibility();
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: imageHeight,
            toolbarHeight: 0,
            pinned: false,
            stretch: true,
            automaticallyImplyLeading: false,
            backgroundColor: backgroundColor,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _CoverImage(
                poem: poem,
                placeholderColor: placeholderColor,
                isDark: isDark,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                PoemStoryPage.horizontalPadding,
                titleTopPadding,
                PoemStoryPage.horizontalPadding,
                12,
              ),
              child: Text(
                key: _titleKey,
                poem.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                strutStyle: AppFontConfig.tibetanStrutStyle(languageCode, 20),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                  height: isTibetan ? AppFontConfig.tibetanUiLineHeight : 1.3,
                  leadingDistribution:
                      isTibetan ? AppFontConfig.tibetanLeadingDistribution : null,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              PoemStoryPage.contentHorizontalPadding,
              8,
              PoemStoryPage.contentHorizontalPadding,
              32,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Text(
                    poem.content,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    poem.authorName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.poemAuthor,
                      height: 1.3,
                    ),
                  ),
                  if (poem.chapterName != null &&
                      poem.chapterName!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      poem.chapterName!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: secondaryColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({
    required this.poem,
    required this.placeholderColor,
    required this.isDark,
  });

  final Poem poem;
  final Color placeholderColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (poem.imageUrl != null && poem.imageUrl!.isNotEmpty) {
      return CachedNetworkImageWidget(
        imageUrl: poem.imageUrl,
        fit: BoxFit.cover,
      );
    }

    return ColoredBox(
      color: placeholderColor,
      child: Icon(
        AppAssets.bookOpenText,
        size: 48,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
  }
}
