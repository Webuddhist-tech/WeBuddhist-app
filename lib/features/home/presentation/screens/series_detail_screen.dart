import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/track_first_value.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/core/widgets/skeletons/skeletons.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_provider.dart';
import 'package:flutter_pecha/features/home/presentation/utils/series_analytics.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/plan_list_view.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/series_more_bottom_sheet.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class SeriesDetailScreen extends ConsumerWidget {
  final String seriesId;
  final Series? initialSeries;
  final String? groupId;
  final GroupType? groupType;
  final bool isGroupEnrolled;

  const SeriesDetailScreen({
    super.key,
    required this.seriesId,
    this.initialSeries,
    this.groupId,
    this.groupType,
    this.isGroupEnrolled = false,
  });

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(seriesByIdProvider(seriesId));
    await ref.read(seriesByIdProvider(seriesId).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(seriesByIdProvider(seriesId));
    final localizations = AppLocalizations.of(context)!;

    final fetchedSeries = seriesAsync.whenOrNull(
      data: (either) => either.fold((_) => null, (s) => s),
    );
    final resolvedSeries = fetchedSeries ?? initialSeries;

    final isGroupEnrolledForSeries = _resolveIsGroupEnrolled(ref);

    if (resolvedSeries != null) {
      ref.watch(
        prefetchBookmarkExistsProvider(
          BookmarkTarget(
            type: BookmarkType.series,
            sourceId: resolvedSeries.id,
          ),
        ),
      );
    }

    final Widget scaffold = Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(
              context,
              ref,
              resolvedSeries?.title ?? '',
              resolvedSeries,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _onRefresh(ref),
                child: seriesAsync.when(
                  skipLoadingOnReload: true,
                  skipLoadingOnRefresh: true,
                  data: (either) {
                    return either.fold(
                      (failure) => _buildScrollableMessage(
                        ErrorStateWidget(
                          error: failure,
                          onRetry: () => _onRefresh(ref),
                        ),
                      ),
                      (series) => _buildSeriesBody(
                        context,
                        localizations,
                        ref,
                        series,
                        isGroupEnrolledForSeries,
                      ),
                    );
                  },
                  loading: () {
                    final preview = initialSeries;
                    if (preview != null && !preview.isPlansPayloadPending) {
                      return _buildSeriesBody(
                        context,
                        localizations,
                        ref,
                        preview,
                        isGroupEnrolledForSeries,
                      );
                    }
                    return const PlanListSkeleton();
                  },
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

    return TrackFirstValue<Series>(
      value: resolvedSeries,
      onFirstValue:
          (series) => ref
              .read(seriesAnalyticsProvider)
              .seriesViewed(
                seriesId: series.id,
                seriesTitle: series.title,
                planCount: series.planCount,
                totalDays: series.totalDays,
              ),
      child: scaffold,
    );
  }

  bool _resolveIsGroupEnrolled(WidgetRef ref) {
    final groupId = this.groupId;
    if (groupId == null) return false;

    final profileAsync = ref.watch(groupProfileProvider(groupId));
    return profileAsync.maybeWhen(
      data:
          (either) => either.fold(
            (_) => isGroupEnrolled,
            (profile) => isSeriesGroupEnrolledInProfile(profile, seriesId),
          ),
      orElse: () => isGroupEnrolled,
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    String title,
    Series? series,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(AppAssets.arrowLeft),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            // Disabled until the series is resolved (its id/title drive both
            // actions).
            onPressed:
                series == null
                    ? null
                    : () => _openMoreSheet(context, ref, series),
          ),
        ],
      ),
    );
  }

  void _openMoreSheet(BuildContext context, WidgetRef ref, Series series) {
    showSeriesMoreBottomSheet(
      context,
      seriesId: series.id,
      seriesName: series.title,
      onAddToPractices: () => _onAddToPractices(context, ref, series),
      onShare: () => _onShare(context, ref, series),
    );
  }

  Future<void> _onShare(BuildContext context, WidgetRef ref, Series series) async {
    final longUrl = DeepLinkUrlBuilder.seriesLink(seriesId: series.id).toString();
    final url = await resolveShareUrlRef(ref, longUrl);
    if (!context.mounted) return;

    final message = context.l10n.series_share_message(series.title, url);
    ref.read(seriesAnalyticsProvider).seriesShared(seriesId: series.id);
    await SharePlus.instance.share(ShareParams(text: message));
  }

  /// Adds the series to the user's practice routine.
  ///
  /// Opens the routine editor with the already-loaded [series] injected. Adding
  /// the SERIES session enrolls the user server-side, so no separate enroll
  /// call (or enrollment check, or series re-fetch) is needed — passing the
  /// object avoids a redundant `GET /series/{id}`.
  void _onAddToPractices(BuildContext context, WidgetRef ref, Series series) {
    if (ref.read(authProvider).isGuest) {
      LoginDrawer.show(context, ref);
      return;
    }
    ref
        .read(seriesAnalyticsProvider)
        .seriesAddedToPractices(seriesId: series.id);
    context.pushNamed('edit-routine', extra: {'initialSeries': series});
  }

  Widget _buildSeriesBody(
    BuildContext context,
    AppLocalizations localizations,
    WidgetRef ref,
    Series series,
    bool isGroupEnrolledForSeries,
  ) {
    if (series.plans.isEmpty) {
      return _buildScrollableMessage(
        _buildEmptyState(context, localizations, ref),
      );
    }
    return PlanListView(
      plans: series.plans,
      seriesId: seriesId,
      series: series,
      groupId: groupId,
      groupType: groupType,
      isGroupEnrolled: isGroupEnrolledForSeries,
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations localizations,
    WidgetRef ref,
  ) {
    final fontSize = getLocalizedFontSize(AppTextSize.title);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Text(
        localizations.no_feature_content,
        style: TextStyle(fontSize: fontSize),
        textAlign: TextAlign.center,
      ),
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
