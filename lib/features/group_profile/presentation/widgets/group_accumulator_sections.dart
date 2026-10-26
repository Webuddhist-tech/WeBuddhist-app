import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_accumulator_member_lists.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/youtube_video_player.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_inline_markdown_view.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Leaderboard, About, and Videos for one group accumulation.
///
/// Videos is omitted when the detail has no YouTube links. Leaderboard keeps
/// the existing everyone list and the signed-in user's own counts.
class GroupAccumulatorSections extends StatefulWidget {
  final GroupAccumulatorDetail detail;
  final bool isDark;

  const GroupAccumulatorSections({
    super.key,
    required this.detail,
    required this.isDark,
  });

  @override
  State<GroupAccumulatorSections> createState() =>
      _GroupAccumulatorSectionsState();
}

class _GroupAccumulatorSectionsState extends State<GroupAccumulatorSections>
    with SingleTickerProviderStateMixin {
  late TabController _sections;

  bool get _showVideos => widget.detail.youtubeLinks.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _sections = TabController(length: _tabLength(widget.detail), vsync: this);
  }

  @override
  void didUpdateWidget(GroupAccumulatorSections oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextLength = _tabLength(widget.detail);
    if (nextLength == _sections.length) return;
    final previous = _sections;
    final index = previous.index.clamp(0, nextLength - 1);
    _sections = TabController(
      length: nextLength,
      vsync: this,
      initialIndex: index,
    );
    previous.dispose();
  }

  @override
  void dispose() {
    _sections.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showVideos = _showVideos;
    final labelColor =
        widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final unselected =
        widget.isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dividerColor =
        widget.isDark ? AppColors.cardBorderDark : AppColors.grey300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _sections,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: labelColor,
          unselectedLabelColor: unselected,
          indicatorColor: labelColor,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: dividerColor,
          labelStyle: context.tabLabelStyle(
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          unselectedLabelStyle: context.tabLabelStyle(
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          tabs: [
            Tab(text: context.l10n.group_accumulator_leaderboard),
            Tab(text: context.l10n.connect_event_tab_about),
            if (showVideos) Tab(text: context.l10n.connect_event_tab_videos),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _sections,
            children: [
              _LeaderboardPane(detail: widget.detail, isDark: widget.isDark),
              _AboutPane(detail: widget.detail, isDark: widget.isDark),
              if (showVideos)
                _VideosPane(
                  links: widget.detail.youtubeLinks,
                  isDark: widget.isDark,
                ),
            ],
          ),
        ),
      ],
    );
  }

  static int _tabLength(GroupAccumulatorDetail detail) =>
      detail.youtubeLinks.isEmpty ? 2 : 3;
}

class _LeaderboardPane extends StatefulWidget {
  final GroupAccumulatorDetail detail;
  final bool isDark;

  const _LeaderboardPane({required this.detail, required this.isDark});

  @override
  State<_LeaderboardPane> createState() => _LeaderboardPaneState();
}

class _LeaderboardPaneState extends State<_LeaderboardPane>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelColor =
        widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final unselected =
        widget.isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dividerColor =
        widget.isDark ? AppColors.cardBorderDark : AppColors.grey300;

    return Column(
      children: [
        TabBar(
          controller: _tabs,
          labelColor: labelColor,
          unselectedLabelColor: unselected,
          indicatorColor: labelColor,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: dividerColor,
          labelStyle: context.tabLabelStyle(
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          unselectedLabelStyle: context.tabLabelStyle(
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          tabs: [
            Tab(text: context.l10n.group_accumulator_everyone),
            Tab(text: context.l10n.group_accumulator_me),
          ],
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _tabs,
            builder: (context, _) {
              return IndexedStack(
                index: _tabs.index,
                children: [
                  GroupAccumulatorLeaderboardList(
                    accumulatorId: widget.detail.id,
                    isDark: widget.isDark,
                  ),
                  GroupAccumulatorMyContributionsList(
                    detail: widget.detail,
                    isDark: widget.isDark,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AboutPane extends StatelessWidget {
  final GroupAccumulatorDetail detail;
  final bool isDark;

  const _AboutPane({required this.detail, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final description = detail.description?.trim() ?? '';
    final dateLabel = description.isEmpty ? _dateLabel(context, detail) : null;
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;

    final Widget body;
    if (description.isNotEmpty) {
      body = PlanInlineMarkdownView(
        content: description,
        fontSize: getLocalizedFontSize(AppTextSize.body),
      );
    } else if (dateLabel != null) {
      body = Row(
        children: [
          Icon(
            AppAssets.calendarBlank,
            size: 18,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              dateLabel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      );
    } else {
      body = Text(
        context.l10n.group_about_empty,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: body,
        ),
      ],
    );
  }

  /// `14 Sep – 18 Sep 2026` when both dates share a year, otherwise both years.
  static String? _dateLabel(
    BuildContext context,
    GroupAccumulatorDetail detail,
  ) {
    final start = detail.startDate?.toLocal();
    final end = detail.endDate?.toLocal();
    if (start == null && end == null) return null;

    final locale = intlFormatLocaleOf(context);
    String day(DateTime value, {required bool withYear}) {
      final pattern = withYear ? 'd MMM y' : 'd MMM';
      return DateFormat(pattern, locale).format(value);
    }

    if (start != null && end != null) {
      final sameDay =
          start.year == end.year &&
          start.month == end.month &&
          start.day == end.day;
      if (!sameDay) {
        final sameYear = start.year == end.year;
        return '${day(start, withYear: !sameYear)} – ${day(end, withYear: true)}';
      }
    }

    return day(start ?? end!, withYear: true);
  }
}

class _VideosPane extends StatelessWidget {
  final List<GroupAccumulatorLink> links;
  final bool isDark;

  const _VideosPane({required this.links, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemCount: links.length,
      itemBuilder: (context, index) {
        return _VideoCard(link: links[index], isDark: isDark);
      },
    );
  }
}

class _VideoCard extends StatelessWidget {
  final GroupAccumulatorLink link;
  final bool isDark;

  const _VideoCard({required this.link, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final videoId = _videoId;
    final title = link.title.trim();
    final placeholder =
        isDark ? AppColors.surfaceVariantDark : AppColors.grey100;

    return GestureDetector(
      onTap: () => _open(context, videoId),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (videoId != null)
                    CachedNetworkImageWidget(
                      imageUrl:
                          'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                      fit: BoxFit.cover,
                      errorWidget: ColoredBox(color: placeholder),
                    )
                  else
                    ColoredBox(color: placeholder),
                  Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                      child: const Icon(
                        AppAssets.play,
                        color: AppColors.primaryDark,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 1.25,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? get _videoId {
    final stored = link.videoId?.trim();
    if (stored != null && stored.isNotEmpty) return stored;
    return YoutubePlayer.convertUrlToId(link.url.trim());
  }

  void _open(BuildContext context, String? videoId) {
    if (videoId == null) {
      final uri = Uri.tryParse(link.url.trim());
      if (uri != null) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'video-player'),
        builder:
            (_) => YoutubeVideoPlayer(videoUrl: link.url, title: link.title),
      ),
    );
  }
}
