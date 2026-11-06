import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/features/home/presentation/providers/home_poems_preview_provider.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/poems_section_skeleton.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poem.dart';
import 'package:flutter_pecha/features/poems/presentation/widgets/poem_dots_indicator.dart';
import 'package:flutter_pecha/features/poems/presentation/widgets/poem_preview_card.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Home page "Poems" section — shown after group events. Displays poems in a
/// horizontal scrollable PageView with dot indicators.
class PoemsSection extends ConsumerWidget {
  const PoemsSection({super.key});

  static const _horizontalPadding = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poemsAsync = ref.watch(homePoemsPreviewProvider);

    return poemsAsync.when(
      data: (poems) {
        if (poems.isEmpty) return const SizedBox.shrink();
        return _PoemsContent(poems: poems);
      },
      loading: () => const PoemsSectionSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PoemsContent extends StatefulWidget {
  const _PoemsContent({required this.poems});

  final List<Poem> poems;

  @override
  State<_PoemsContent> createState() => _PoemsContentState();
}

class _PoemsContentState extends State<_PoemsContent> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openViewer(BuildContext context, {String? initialPoemId}) {
    context.pushNamed(
      'home-poems',
      extra: initialPoemId != null ? {'initialPoemId': initialPoemId} : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTibetan = context.isTibetanLocale;
    final sectionTitleSize = getLocalizedFontSize(AppTextSize.bodyLarge);
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final dotColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final inactiveDotColor = isDark ? AppColors.grey800 : AppColors.grey300;
    final dotTrackColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceWhite;
    final dotTrackBorderColor =
        isDark ? AppColors.cardBorderDark : AppColors.grey100;
    final sectionContentGap = isTibetan ? 16.0 : 12.0;
    final sectionBackgroundColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PoemsSection._horizontalPadding,
            0,
            PoemsSection._horizontalPadding,
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.home_poems,
                  strutStyle: context.tibetanStrutStyle(
                    sectionTitleSize,
                    compact: true,
                  ),
                  style: TextStyle(
                    fontSize: sectionTitleSize,
                    fontWeight: FontWeight.w700,
                    height:
                        isTibetan
                            ? AppFontConfig.tibetanCompactLineHeight
                            : 1.2,
                    leadingDistribution:
                        isTibetan
                            ? AppFontConfig.tibetanLeadingDistribution
                            : null,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _openViewer(context),
                style: TextButton.styleFrom(
                  foregroundColor: subtitleColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.see_all,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: sectionContentGap),
        Material(
          color: sectionBackgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder:
                    (context, constraints) => SizedBox(
                      height: PoemPreviewCard.heightFor(constraints.maxWidth),
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: widget.poems.length,
                        onPageChanged: (index) {
                          setState(() => _currentIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return PoemPreviewCard(
                            poem: widget.poems[index],
                            onTap:
                                () => _openViewer(
                                  context,
                                  initialPoemId: widget.poems[index].id,
                                ),
                          );
                        },
                      ),
                    ),
              ),
              const SizedBox(height: 12),
              PoemDotsIndicator(
                count: widget.poems.length,
                currentIndex: _currentIndex,
                activeColor: dotColor,
                inactiveColor: inactiveDotColor,
                backgroundColor: dotTrackColor,
                borderColor: dotTrackBorderColor,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
