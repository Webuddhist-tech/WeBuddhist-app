import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/core/widgets/skeletons/skeletons.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_inline_markdown_view.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pecha/core/utils/network_image_utils.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';

class SeriesInfoScreen extends ConsumerWidget {
  final String seriesId;

  const SeriesInfoScreen({super.key, required this.seriesId});

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(seriesByIdProvider(seriesId));
    await ref.read(seriesByIdProvider(seriesId).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(seriesByIdProvider(seriesId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _onRefresh(ref),
                child: seriesAsync.when(
                  data:
                      (either) => either.fold(
                        (failure) => _buildScrollableMessage(
                          ErrorStateWidget(
                            error: failure,
                            onRetry: () => _onRefresh(ref),
                          ),
                        ),
                        (series) => _buildContent(context, ref, series),
                      ),
                  loading:
                      () => const SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: SizedBox(height: 400, child: PlanListSkeleton()),
                      ),
                  error:
                      (error, stackTrace) => _buildScrollableMessage(
                        ErrorStateWidget(
                          error: error,
                          onRetry: () => _onRefresh(ref),
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Series series) {
    final locale = ref.watch(localeProvider);
    final lineHeight = getLineHeight(locale.languageCode);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleFontSize = getLocalizedFontSize(AppTextSize.titleLarge);
    final bodyFontSize = getLocalizedFontSize(AppTextSize.body);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ResponsiveCoverImage(
                  image: series.coverImage,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              series.title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                height: lineHeight,
              ),
            ),
          ),
          if (series.group != null) ...[
            const SizedBox(height: 16),
            _buildGroupRow(context, series.group!, isDark, lineHeight),
          ],
          if (series.description.trim().isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSection(
              context,
              body: series.description,
              bodyFontSize: bodyFontSize,
              lineHeight: lineHeight,
              isDark: isDark,
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(AppAssets.arrowLeft),
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }

  Widget _buildGroupRow(
    BuildContext context,
    SeriesGroup group,
    bool isDark,
    double? lineHeight,
  ) {
    final subtitleColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return GestureDetector(
      onTap: () => context.push('/home/group/${group.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor:
                  isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
              backgroundImage:
                  group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                      ? group.avatarUrl!.cachedNetworkImageProvider
                      : null,
              onBackgroundImageError:
                  group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                      ? reportImageLoadError
                      : null,
              child:
                  (group.avatarUrl == null || group.avatarUrl!.isEmpty)
                      ? Icon(
                        AppAssets.usersThree,
                        size: 20,
                        color: isDark ? AppColors.grey500 : AppColors.grey600,
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (group.title.isNotEmpty)
                    Text(
                      group.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: lineHeight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (group.subTitle != null &&
                      group.subTitle!.trim().isNotEmpty)
                    Text(
                      group.subTitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                        height: lineHeight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(
              AppAssets.caretRight,
              color: isDark ? AppColors.grey500 : AppColors.grey600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String body,
    required double bodyFontSize,
    required double? lineHeight,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: PlanInlineMarkdownView(content: body, fontSize: bodyFontSize),
    );
  }

  Widget _buildScrollableMessage(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}
