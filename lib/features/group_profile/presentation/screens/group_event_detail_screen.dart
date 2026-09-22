import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_event_attendance_utils.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_event_filter_utils.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_link_utils.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/add_offline_chants_dialog.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_accumulator_member_lists.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_participants_drawer.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_participation_dialog.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_enrollment_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_provider.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/plan_list_view.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/youtube_video_player.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/group_accumulation_counts_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_sync_manager.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plans_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_inline_markdown_view.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

enum _EventTab { videos, about, accumulations }

class GroupEventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const GroupEventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<GroupEventDetailScreen> createState() =>
      _GroupEventDetailScreenState();
}

class _GroupEventDetailScreenState
    extends ConsumerState<GroupEventDetailScreen> {
  _EventTab? _selectedTab;
  bool? _attendingOverride;
  GroupEventParticipationType? _participationOverride;
  GroupEventParticipationType? _pendingJoin;
  bool _isSubmitting = false;
  bool _isOpeningPuja = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eventAsync = ref.watch(groupEventDetailProvider(widget.eventId));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.scaffoldBackgroundDark : AppColors.surfaceLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(context, isDark),
            Expanded(
              child: eventAsync.when(
                data:
                    (either) => either.fold(
                      (failure) => ErrorStateWidget(
                        error: failure,
                        onRetry:
                            () => ref.invalidate(
                              groupEventDetailProvider(widget.eventId),
                            ),
                      ),
                      (event) => _buildContent(context, event, isDark),
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, _) => ErrorStateWidget(
                      error: error,
                      onRetry:
                          () => ref.invalidate(
                            groupEventDetailProvider(widget.eventId),
                          ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(AppAssets.arrowLeft),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
          Expanded(
            child: Text(
              context.l10n.connect_tab_events,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(AppAssets.readerShare),
            onPressed: _shareEvent,
            iconSize: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, GroupEvent event, bool isDark) {
    final participantsState = ref.watch(
      groupEventParticipantsProvider(event.id),
    );
    final participants = participantsState.participants;

    // Clear the optimistic overrides once the server confirms the change,
    // so subsequent state derives purely from the event.
    final attendingConfirmed =
        _attendingOverride != null && _attendingOverride == event.isJoined;
    final participationConfirmed =
        _participationOverride != null &&
        _participationOverride == event.myParticipationType;
    if (attendingConfirmed || participationConfirmed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          if (attendingConfirmed) _attendingOverride = null;
          if (participationConfirmed) _participationOverride = null;
        });
      });
    }

    final isAttending = _attendingOverride ?? event.isJoined;
    final totalAttending = _attendeeCount(event, isAttending);
    final videos = _videoLinks(event);
    final groupAccumulator = event.groupAccumulator;
    final tabs = <_EventTab>[
      if (videos.isNotEmpty) _EventTab.videos,
      _EventTab.about,
      if (groupAccumulator != null) _EventTab.accumulations,
    ];
    final selectedTab =
        tabs.contains(_selectedTab) ? _selectedTab! : tabs.first;
    final isPast = isGroupEventPast(event);
    final canSwitchParticipation =
        isGroupEventHybrid(event) && isAttending && !isPast;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EventHeroCard(event: event, isDark: isDark),
          const SizedBox(height: 14),
          _AttendeesRow(
            eventId: event.id,
            participants: participants,
            totalAttending: totalAttending,
            isDark: isDark,
          ),
          if (!isPast || (event.hasPuja && isAttending)) ...[
            const SizedBox(height: 14),
            _buildActionRow(event, isAttending, isDark, isPast: isPast),
          ],
          const SizedBox(height: 16),
          _EventInfoCard(
            event: event,
            isDark: isDark,
            participation:
                canSwitchParticipation ? _participationOf(event) : null,
            onParticipationChanged:
                canSwitchParticipation
                    ? (type) => _changeParticipation(event, type)
                    : null,
            participationBusy: _isSubmitting,
          ),
          const SizedBox(height: 16),
          _buildTabs(tabs, selectedTab, isDark),
          const SizedBox(height: 20),
          switch (selectedTab) {
            _EventTab.videos => _VideosPanel(
              videos: videos,
              event: event,
              isDark: isDark,
            ),
            _EventTab.about => _AboutPanel(event: event, isDark: isDark),
            _EventTab.accumulations => _EventAccumulatorPanel(
              accumulatorId: groupAccumulator!.id,
              groupTitle: event.groupName,
              isDark: isDark,
            ),
          },
        ],
      ),
    );
  }

  int _attendeeCount(GroupEvent event, bool isAttending) {
    var count = event.participantCount;
    if (isAttending && !event.isJoined) count++;
    if (!isAttending && event.isJoined) count--;
    return math.max(0, count);
  }

  /// A single-format event leaves no choice; hybrid stays null until picked.
  GroupEventParticipationType? _participationOf(GroupEvent event) {
    final chosen = _participationOverride ?? event.myParticipationType;
    if (chosen != null) return chosen;
    if (isGroupEventHybrid(event)) return null;
    return isGroupEventOnline(event)
        ? GroupEventParticipationType.online
        : GroupEventParticipationType.offline;
  }

  String _attendingLabel(GroupEvent event) => switch (_participationOf(event)) {
    GroupEventParticipationType.online =>
      context.l10n.connect_event_joining_online,
    GroupEventParticipationType.offline =>
      context.l10n.connect_event_joining_in_person,
    null => context.l10n.connect_event_attending,
  };

  Widget _buildActionRow(
    GroupEvent event,
    bool isAttending,
    bool isDark, {
    required bool isPast,
  }) {
    final secondaryButtonColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite;
    final secondaryBorder = isDark ? AppColors.grey800 : AppColors.grey300;
    final isHybrid = isGroupEventHybrid(event);

    // Hybrid events ask up front instead of via a dialog after tapping Attend.
    if (isHybrid && !isAttending) {
      Widget joinButton(GroupEventParticipationType type, String label) {
        final isPending = _isSubmitting && _pendingJoin == type;
        return Expanded(
          child: OutlinedButton(
            onPressed:
                _isSubmitting
                    ? null
                    : () => _attendEvent(event, participation: type),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor: secondaryButtonColor,
              foregroundColor:
                  isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              side: BorderSide(color: secondaryBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child:
                isPending
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(label),
          ),
        );
      }

      return Row(
        children: [
          joinButton(
            GroupEventParticipationType.offline,
            context.l10n.connect_event_join_in_person,
          ),
          const SizedBox(width: 12),
          joinButton(
            GroupEventParticipationType.online,
            context.l10n.connect_event_join_online,
          ),
        ],
      );
    }

    final attendButton = ElevatedButton(
      onPressed:
          _isSubmitting
              ? null
              : () => isAttending ? _leaveEvent(event) : _attendEvent(event),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size(0, 44),
        backgroundColor:
            isAttending
                ? (isDark ? AppColors.surfaceVariantDark : AppColors.grey100)
                : (isDark ? AppColors.surfaceWhite : AppColors.textPrimary),
        foregroundColor:
            isAttending
                ? (isDark ? AppColors.textTertiaryDark : AppColors.textPrimary)
                : (isDark ? AppColors.textPrimary : AppColors.surfaceWhite),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child:
          _isSubmitting
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Text(
                isAttending
                    ? _attendingLabel(event)
                    : context.l10n.connect_event_attend,
              ),
    );

    if (event.hasPuja && isAttending) {
      final pujaButton = ElevatedButton(
        onPressed: _isOpeningPuja ? null : () => _enterPuja(event),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 44),
          backgroundColor:
              isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
          foregroundColor:
              isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child:
            _isOpeningPuja
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Text(
                  isHybrid
                      ? context.l10n.connect_event_enter
                      : context.l10n.start_reading,
                ),
      );
      // A hybrid attendee switches their choice in the info card below.
      if (isPast || isHybrid) {
        return SizedBox(width: double.infinity, child: pujaButton);
      }
      return Row(
        children: [
          Expanded(child: attendButton),
          const SizedBox(width: 12),
          Expanded(child: pujaButton),
        ],
      );
    }

    if (!isAttending) {
      return SizedBox(width: double.infinity, child: attendButton);
    }

    return Row(
      children: [
        Expanded(child: attendButton),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : _shareEvent,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor: secondaryButtonColor,
              foregroundColor:
                  isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              side: BorderSide(color: secondaryBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(context.l10n.group_invite),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(List<_EventTab> tabs, _EventTab selected, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 20),
            _EventTabButton(
              label: _tabLabel(tabs[i]),
              selected: tabs[i] == selected,
              isDark: isDark,
              onTap: () => setState(() => _selectedTab = tabs[i]),
            ),
          ],
        ],
      ),
    );
  }

  String _tabLabel(_EventTab tab) => switch (tab) {
    _EventTab.videos => context.l10n.connect_event_tab_videos,
    _EventTab.about => context.l10n.connect_event_tab_about,
    _EventTab.accumulations => context.l10n.connect_event_tab_accumulations,
  };

  /// Opens the event's puja: auto-enrolls in its series and opens the (only)
  /// plan's day list, or previews the plan when the event has no series.
  /// Only online attendees get the live stream; a hybrid attendee who never
  /// picked is asked first, since the choice decides the layout.
  Future<void> _enterPuja(GroupEvent event) async {
    if (_isOpeningPuja) return;
    final seriesId = event.series?.id ?? event.seriesId;
    final planId = event.plan?.id ?? event.planId;
    if (seriesId == null && planId == null) return;

    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    var participation = _participationOf(event);
    final needsChoice = participation == null;
    if (needsChoice) {
      participation = await GroupEventParticipationDialog.show(context);
      if (participation == null || !mounted) return;
    }

    setState(() => _isOpeningPuja = true);
    try {
      if (needsChoice && !await _saveParticipation(event, participation)) {
        return;
      }
      if (seriesId != null) {
        await _enterSeries(
          event,
          seriesId,
          showLiveStream: participation == GroupEventParticipationType.online,
        );
      } else {
        await _openPlanPreview(planId!, eventId: event.id);
      }
    } finally {
      if (mounted) setState(() => _isOpeningPuja = false);
    }
  }

  Future<bool> _saveParticipation(
    GroupEvent event,
    GroupEventParticipationType participation,
  ) async {
    final result = await ref
        .read(groupProfileRepositoryProvider)
        .joinGroupEvent(event.id, participationType: participation);
    if (!mounted) return false;
    return result.fold(
      (failure) {
        _showError(failure.message);
        return false;
      },
      (_) {
        setState(() => _participationOverride = participation);
        _refreshEvent(event);
        return true;
      },
    );
  }

  Future<void> _changeParticipation(
    GroupEvent event,
    GroupEventParticipationType participation,
  ) async {
    if (_isSubmitting || participation == _participationOf(event)) return;
    setState(() => _isSubmitting = true);
    try {
      await _saveParticipation(event, participation);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openPlanPreview(String planId, {String? eventId}) async {
    final either = await ref.read(planByIdFutureProvider(planId).future);
    if (!mounted) return;
    final plan = either.fold((_) => null, (plan) => plan);
    if (plan == null) {
      _showError(context.l10n.notFound);
      return;
    }
    context.push(
      AppRoutes.practicePlanPreview,
      extra: {'plan': plan, if (eventId != null) 'eventId': eventId},
    );
  }

  Future<void> _enterSeries(
    GroupEvent event,
    String seriesId, {
    required bool showLiveStream,
  }) async {
    final seriesEither = await ref.read(seriesByIdProvider(seriesId).future);
    if (!mounted) return;
    final series = seriesEither.fold((_) => null, (s) => s);
    final plan = series?.plans.firstOrNull;
    if (plan == null) {
      _showError(context.l10n.notFound);
      return;
    }

    final enrollments = await ref.read(userSeriesEnrollmentsProvider.future);
    if (!mounted) return;
    if (!enrollments.contains(seriesId)) {
      final ok =
          await ref.read(seriesEnrollmentProvider(seriesId).notifier).enroll();
      if (!mounted) return;
      if (!ok) {
        final state = ref.read(seriesEnrollmentProvider(seriesId));
        _showError(
          state is SeriesEnrollmentFailure
              ? state.failure.message
              : context.l10n.series_enroll_error,
        );
        return;
      }
    }

    // Prefer the enrolled plan so flexible plans keep their saved start date.
    final enrolled =
        ref
            .read(myPlansPaginatedProvider)
            .plans
            .where((p) => p.id == plan.id)
            .firstOrNull;
    final userPlan = enrolled ?? userPlanFromCatalogPlan(plan);
    final startDate = userPlan.effectiveStartDate;
    context.push(
      '/practice/details',
      extra: {
        'plan': userPlan,
        'selectedDay': selectedDayForStart(startDate, userPlan.totalDays),
        'startDate': startDate,
        'seriesId': seriesId,
        'eventId': event.id,
        'showLiveStream': showLiveStream,
      },
    );
  }

  List<GroupEventLink> _videoLinks(GroupEvent event) {
    return event.links
        .where(
          (link) =>
              link.url.isNotEmpty &&
              GroupEventLinkUtils.kindOf(link) == GroupEventLinkKind.video,
        )
        .toList();
  }

  /// [participation] is only set for hybrid events; the server fills in the
  /// rest.
  Future<void> _attendEvent(
    GroupEvent event, {
    GroupEventParticipationType? participation,
  }) async {
    if (isGroupEventPast(event)) return;

    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _pendingJoin = participation;
    });
    final result = await joinGroupEventEnsuringGroupMembership(
      ref: ref,
      event: event,
      participationType: participation,
    );
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _pendingJoin = null;
    });

    result.fold((failure) => _showError(failure.message), (_) {
      setState(() {
        _attendingOverride = true;
        _participationOverride = participation;
      });
      _refreshEvent(event);
    });
  }

  Future<void> _leaveEvent(GroupEvent event) async {
    if (isGroupEventPast(event)) return;

    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await ref
        .read(groupProfileRepositoryProvider)
        .leaveGroupEvent(event.id);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold((failure) => _showError(failure.message), (_) {
      setState(() {
        _attendingOverride = false;
        _participationOverride = null;
      });
      _refreshEvent(event);
    });
  }

  void _refreshEvent(GroupEvent event) {
    ref.invalidate(groupEventDetailProvider(event.id));
    ref.read(groupEventParticipantsProvider(event.id).notifier).refresh();
    if (event.groupId.isNotEmpty) {
      ref.invalidate(groupEventsProvider(event.groupId));
    }
  }

  Future<void> _shareEvent() async {
    final longUrl =
        DeepLinkUrlBuilder.eventLink(eventId: widget.eventId).toString();
    final shareUrl = await resolveShareUrlRef(ref, longUrl);
    if (!mounted) return;

    await SharePlus.instance.share(
      ShareParams(
        text: shareUrl,
        sharePositionOrigin: getSharePositionOrigin(context: context),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

class _EventHeroCard extends StatelessWidget {
  final GroupEvent event;
  final bool isDark;

  const _EventHeroCard({required this.event, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final title =
        event.title.trim().isNotEmpty
            ? event.title.trim()
            : context.l10n.connect_event_fallback_title;

    return Material(
      color: cardColor,
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 190,
            width: double.infinity,
            child:
                event.image != null && !event.image!.isEmpty
                    ? ResponsiveCoverImage(
                      image: event.image,
                      fit: BoxFit.cover,
                    )
                    : ColoredBox(
                      color:
                          isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.grey100,
                      child: Icon(
                        AppAssets.calendarDots,
                        size: 42,
                        color: isDark ? AppColors.grey500 : AppColors.grey600,
                      ),
                    ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendeesRow extends StatelessWidget {
  final String eventId;
  final List<GroupEventParticipant> participants;
  final int totalAttending;
  final bool isDark;

  const _AttendeesRow({
    required this.eventId,
    required this.participants,
    required this.totalAttending,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (totalAttending <= 0) {
      return const SizedBox.shrink();
    }

    final shown = participants.take(2).toList();
    final remaining = math.max(0, totalAttending - shown.length);
    final textColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    final double avatarSize = 28.0;
    final double overlap = 18.0;

    final int totalItems = shown.length + (remaining > 0 ? 1 : 0);
    final double stackWidth =
        totalItems == 0 ? 0 : (totalItems - 1) * overlap + avatarSize;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          () => GroupEventParticipantsDrawer.show(
            context,
            eventId: eventId,
            totalAttending: totalAttending,
          ),
      child: Row(
        children: [
          if (totalItems > 0)
            SizedBox(
              width: stackWidth,
              height: avatarSize,
              child: Stack(
                children: [
                  // Paint first avatar last so it sits on top of the rest.
                  for (var i = shown.length - 1; i >= 0; i--)
                    Positioned(
                      left: i * overlap,
                      child: _ParticipantAvatar(
                        participant: shown[i],
                        isDark: isDark,
                        size: avatarSize,
                      ),
                    ),
                  // Painted after the avatars so the overflow count stays on top.
                  if (remaining > 0)
                    Positioned(
                      left: shown.length * overlap,
                      child: Container(
                        width: avatarSize,
                        height: avatarSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isDark
                                  ? AppColors.grey800
                                  : const Color(0xFFE8E5DF),
                          border: Border.all(
                            color:
                                isDark
                                    ? AppColors.scaffoldBackgroundDark
                                    : AppColors.surfaceLight,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '+$remaining',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.greyDark,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (totalItems > 0) const SizedBox(width: 8),
          Text(
            context.l10n.connect_event_participants_attending(totalAttending),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  final GroupEventParticipant participant;
  final bool isDark;
  final double size;

  const _ParticipantAvatar({
    required this.participant,
    required this.isDark,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = participant.avatarUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color:
              isDark
                  ? AppColors.scaffoldBackgroundDark
                  : AppColors.surfaceLight,
          width: 2,
        ),
      ),
      child: ClipOval(
        child:
            avatarUrl != null && avatarUrl.isNotEmpty
                ? CachedNetworkImageWidget(
                  imageUrl: avatarUrl,
                  fit: BoxFit.cover,
                  errorWidget: _avatarFallback(),
                )
                : _avatarFallback(),
      ),
    );
  }

  Widget _avatarFallback() {
    final name = participant.displayName;
    final initials = _getInitials(name);

    return ColoredBox(
      color: AppColors.primary,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDarkest,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0].characters.first}${parts[1].characters.first}'
          .toUpperCase();
    }
    return name.characters.take(2).toString().toUpperCase();
  }
}

class _EventInfoCard extends StatelessWidget {
  final GroupEvent event;
  final bool isDark;

  /// The attendee's current hybrid choice; chips show when
  /// [onParticipationChanged] is set.
  final GroupEventParticipationType? participation;
  final ValueChanged<GroupEventParticipationType>? onParticipationChanged;
  final bool participationBusy;

  const _EventInfoCard({
    required this.event,
    required this.isDark,
    this.participation,
    this.onParticipationChanged,
    this.participationBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dateText = _formatDateText(context, event);
    final recurrenceText = _formatRecurrenceText(context, event);
    final locationName = event.location?.name.trim() ?? '';
    final isOnline = isGroupEventOnline(event);
    final showLocation = !isOnline && locationName.isNotEmpty;
    final links =
        event.links
            .where(
              (link) =>
                  link.url.isNotEmpty &&
                  GroupEventLinkUtils.kindOf(link) != GroupEventLinkKind.video,
            )
            .toList();
    final showOnline = isOnline || isGroupEventHybrid(event);
    // A meeting room stands in for the venue only when the event runs online;
    // on a venue-only event it is just another resource.
    bool isVenueLink(GroupEventLink link) =>
        showOnline &&
        GroupEventLinkUtils.kindOf(link) == GroupEventLinkKind.meeting;
    final meetingLinks = links.where(isVenueLink).toList();
    final otherLinks = links.where((link) => !isVenueLink(link)).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EventSectionLabel(text: context.l10n.connect_event_when),
          const SizedBox(height: 10),
          if (dateText != null)
            _EventInfoRow(
              icon: AppAssets.clock,
              text: dateText,
              iconColor: secondaryColor,
            )
          else
            Text(
              context.l10n.connect_event_date_tba,
              style: TextStyle(fontSize: 14, color: secondaryColor),
            ),
          if (recurrenceText != null) ...[
            const SizedBox(height: 10),
            _EventInfoRow(
              icon: AppAssets.repeat,
              text: recurrenceText,
              iconColor: secondaryColor,
            ),
          ],
          if (showLocation || showOnline) ...[
            const SizedBox(height: 16),
            _EventSectionLabel(text: context.l10n.connect_event_where),
            const SizedBox(height: 10),
          ],
          if (showLocation)
            _EventInfoRow(
              icon: AppAssets.buildings,
              text: locationName,
              iconColor: secondaryColor,
              bold: true,
            ),
          if (showOnline) ...[
            if (showLocation) const SizedBox(height: 12),
            _EventInfoRow(
              icon: AppAssets.videoCamera,
              text: context.l10n.connect_online,
              iconColor: secondaryColor,
              bold: true,
            ),
          ],
          for (final link in meetingLinks) ...[
            const SizedBox(height: 10),
            _EventLinkText(link: link, isDark: isDark),
          ],
          if (onParticipationChanged != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _ParticipationChip(
                  label: context.l10n.connect_event_joining_in_person,
                  selected:
                      participation == GroupEventParticipationType.offline,
                  isDark: isDark,
                  onTap:
                      participationBusy
                          ? null
                          : () => onParticipationChanged!(
                            GroupEventParticipationType.offline,
                          ),
                ),
                const SizedBox(width: 8),
                _ParticipationChip(
                  label: context.l10n.connect_event_joining_online,
                  selected:
                      participation == GroupEventParticipationType.online,
                  isDark: isDark,
                  onTap:
                      participationBusy
                          ? null
                          : () => onParticipationChanged!(
                            GroupEventParticipationType.online,
                          ),
                ),
              ],
            ),
          ],
          if (otherLinks.isNotEmpty) ...[
            const SizedBox(height: 16),
            _EventSectionLabel(text: context.l10n.connect_event_links_title),
            for (final link in otherLinks) ...[
              const SizedBox(height: 10),
              _EventLinkText(link: link, isDark: isDark),
            ],
          ],
        ],
      ),
    );
  }

  String? _formatDateText(BuildContext context, GroupEvent event) {
    final start = event.startDate?.toLocal();
    if (start == null) return null;

    final locale = intlFormatLocaleOf(context);
    final date = DateFormat('EEE d MMM y', locale).format(start);
    final startTime = DateFormat.jm(locale).format(start).toLowerCase();
    final end = event.endDate?.toLocal();
    if (end == null || end.isAtSameMomentAs(start)) {
      return '$date\n$startTime ${start.timeZoneName}';
    }

    final endTime = DateFormat.jm(locale).format(end).toLowerCase();
    final endZone = end.timeZoneName;
    // Label the start too when the range crosses a DST change.
    final startLabel =
        start.timeZoneName == endZone
            ? startTime
            : '$startTime ${start.timeZoneName}';
    // Dates on one line, times on the next, so the range stays scannable.
    final isMultiDay = !DateUtils.isSameDay(start, end);
    final dateLine =
        isMultiDay
            ? '$date – ${DateFormat('EEE d MMM y', locale).format(end)}'
            : date;
    return '$dateLine\n$startLabel – $endTime $endZone';
  }

  String? _formatRecurrenceText(BuildContext context, GroupEvent event) {
    final recurrence = event.recurrence;
    if (!event.isRecurring || recurrence == null) return null;

    final anchor = (event.occurrenceDate ?? event.startDate)?.toLocal();
    if (anchor == null) return null;

    final locale = intlFormatLocaleOf(context);
    return switch (recurrence.frequency.toUpperCase()) {
      'DAILY' => context.l10n.connect_event_every_day,
      'WEEKLY' => context.l10n.connect_event_every_weekday(
        DateFormat.EEEE(locale).format(anchor),
      ),
      'MONTHLY' => context.l10n.connect_event_every_month,
      'YEARLY' => context.l10n.connect_event_every_date(
        DateFormat('d MMM', locale).format(anchor),
      ),
      _ => null,
    };
  }
}

/// Pill showing one way to attend a hybrid event; filled when chosen.
class _ParticipationChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback? onTap;

  const _ParticipationChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background =
        selected
            ? (isDark ? AppColors.surfaceWhite : AppColors.textPrimary)
            : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite);
    final foreground =
        selected
            ? (isDark ? AppColors.textPrimary : AppColors.surfaceWhite)
            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);
    final border =
        selected ? background : (isDark ? AppColors.grey800 : AppColors.grey300);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

class _EventSectionLabel extends StatelessWidget {
  final String text;

  const _EventSectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: AppColors.poemAuthor,
      ),
    );
  }
}

class _EventInfoRow extends StatelessWidget {
  const _EventInfoRow({
    required this.icon,
    required this.text,
    required this.iconColor,
    this.leading,
    this.textColor,
    this.bold = false,
  });

  final IconData icon;
  final String text;
  final Color iconColor;

  /// Replaces [icon] when set, e.g. a brand logo image.
  final Widget? leading;
  final Color? textColor;
  final bool bold;

  static const double _iconSize = 16;
  static const double _iconSlotWidth = 18;
  static const TextStyle _textStyle = TextStyle(fontSize: 14, height: 1.35);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _iconSlotWidth,
          height: _textStyle.fontSize! * _textStyle.height!,
          child: Align(
            alignment: Alignment.center,
            child: leading ?? Icon(icon, size: _iconSize, color: iconColor),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: _textStyle.copyWith(
              fontWeight: bold ? FontWeight.w700 : null,
              color: textColor,
            ),
            maxLines: textColor == null ? null : 1,
            overflow: textColor == null ? null : TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Meeting or web link under the "Online" row, shown as its short url with a
/// camera icon for meeting rooms and a globe for everything else.
class _EventLinkText extends StatelessWidget {
  final GroupEventLink link;
  final bool isDark;

  const _EventLinkText({required this.link, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isMeeting =
        GroupEventLinkUtils.kindOf(link) == GroupEventLinkKind.meeting;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final brandIcon = _brandIcon();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openLink(link.url),
      child: _EventInfoRow(
        icon: isMeeting ? AppAssets.videoCamera : AppAssets.globe,
        leading:
            brandIcon == null
                ? null
                : Image.asset(brandIcon, width: 16, height: 16),
        text: GroupEventLinkUtils.shortUrl(link.url),
        iconColor: secondaryColor,
        textColor: isDark ? AppColors.blueDark : AppColors.blue,
        bold: true,
      ),
    );
  }

  String? _brandIcon() {
    final provider = GroupEventLinkUtils.providerName(link) ?? link.type;
    return switch (provider.toLowerCase()) {
      'google meet' || 'google-meet' || 'meet' => AppAssets.googleMeetIcon,
      'zoom' => AppAssets.zoomIcon,
      _ => null,
    };
  }
}

/// Accumulations tab: progress, leaderboard / own count, and a way to log
/// recitations done with the livestream or offline.
class _EventAccumulatorPanel extends ConsumerStatefulWidget {
  final String accumulatorId;
  final String? groupTitle;
  final bool isDark;

  const _EventAccumulatorPanel({
    required this.accumulatorId,
    required this.groupTitle,
    required this.isDark,
  });

  @override
  ConsumerState<_EventAccumulatorPanel> createState() =>
      _EventAccumulatorPanelState();
}

class _EventAccumulatorPanelState
    extends ConsumerState<_EventAccumulatorPanel> {
  bool _showContributions = false;
  bool _isJoining = false;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      groupAccumulatorDetailProvider(widget.accumulatorId),
    );
    void retry() =>
        ref.invalidate(groupAccumulatorDetailProvider(widget.accumulatorId));

    return detailAsync.when(
      loading:
          () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
      error: (error, _) => ErrorStateWidget(error: error, onRetry: retry),
      data:
          (either) => either.fold(
            (failure) => ErrorStateWidget(error: failure, onRetry: retry),
            (detail) => _buildDetail(context, detail),
          ),
    );
  }

  Widget _buildDetail(BuildContext context, GroupAccumulatorDetail detail) {
    final isDark = widget.isDark;
    final localJoinedIds = ref.watch(
      groupAccumulatorJoinCacheProvider(detail.groupId),
    );
    final hasJoined = accumulatorHasJoined(
      detail,
      localJoinedIds: localJoinedIds,
    );
    final numberFormat = NumberFormat.decimalPattern(
      intlFormatLocaleOf(context),
    );
    final primaryColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final progressText =
        '${numberFormat.format(detail.totalCount)} / ${numberFormat.format(detail.targetCount)}';
    // Keep the counts notifier alive while the panel is visible so an offline
    // add is not racing its own dispose during sync.
    if (detail.presetAccumulatorId.isNotEmpty) {
      ref.watch(groupAccumulationCountsProvider(detail.presetAccumulatorId));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _openAccumulator(detail),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    detail.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(AppAssets.caretRight, size: 18, color: secondaryColor),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                progressText,
                style: TextStyle(fontSize: 13, color: secondaryColor),
              ),
            ),
            Text(
              '${detail.progressPercent}%',
              style: TextStyle(fontSize: 13, color: secondaryColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: detail.progressFraction,
            minHeight: 6,
            backgroundColor:
                isDark ? AppColors.cardBorderDark : AppColors.grey300,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _EventSubTabButton(
                label: context.l10n.group_accumulator_leaderboard,
                selected: !_showContributions,
                isDark: isDark,
                onTap: () => setState(() => _showContributions = false),
              ),
            ),
            Expanded(
              child: _EventSubTabButton(
                label: context.l10n.group_accumulator_my_contributions,
                selected: _showContributions,
                isDark: isDark,
                onTap: () => setState(() => _showContributions = true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_showContributions)
          GroupAccumulatorMyContributionsList(
            detail: detail,
            isDark: isDark,
            embedded: true,
          )
        else
          GroupAccumulatorLeaderboardList(
            accumulatorId: detail.id,
            isDark: isDark,
            embedded: true,
          ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child:
              hasJoined
                  ? OutlinedButton.icon(
                    onPressed: () => _addRecitations(detail),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      backgroundColor:
                          isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.grey100,
                      foregroundColor: primaryColor,
                      side: BorderSide(
                        color: isDark ? AppColors.grey800 : AppColors.grey300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    icon: const Icon(AppAssets.plusCircle, size: 20),
                    label: Text(
                      context.l10n.connect_event_add_recitations,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  : ElevatedButton(
                    onPressed: _isJoining ? null : () => _join(detail),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      minimumSize: const Size(0, 50),
                      backgroundColor:
                          isDark
                              ? AppColors.surfaceWhite
                              : AppColors.textPrimary,
                      foregroundColor:
                          isDark
                              ? AppColors.textPrimary
                              : AppColors.surfaceWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child:
                        _isJoining
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Text(
                              context.l10n.group_join_to_contribute,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
        ),
      ],
    );
  }

  void _openAccumulator(GroupAccumulatorDetail detail) {
    context.push(
      '/home/group-accumulator/${detail.id}',
      extra: {'groupTitle': widget.groupTitle},
    );
  }

  bool _requireLogin() {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return false;
    }
    return true;
  }

  Future<void> _join(GroupAccumulatorDetail detail) async {
    if (!_requireLogin()) return;

    setState(() => _isJoining = true);
    final ok = await joinGroupAccumulator(
      ref: ref,
      accumulatorId: detail.id,
      groupId: detail.groupId,
    );
    if (!mounted) return;
    setState(() => _isJoining = false);

    if (ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.group_accumulator_join_error),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Counts go through the mala pipeline so they sync like in-app taps. The
  /// local total is seeded from a fresh server count first, since the sync
  /// posts an absolute total and the screen snapshot may be stale.
  Future<void> _addRecitations(GroupAccumulatorDetail detail) async {
    if (!_requireLogin()) return;
    final presetId = detail.presetAccumulatorId;
    if (presetId.isEmpty) return;

    final l10n = context.l10n;
    final count = await showAddOfflineChantsDialog(
      context,
      title: l10n.connect_event_add_recitations,
      message: l10n.connect_event_add_recitations_message,
    );
    if (count == null || count <= 0 || !mounted) return;

    final countsNotifier = ref.read(
      groupAccumulationCountsProvider(presetId).notifier,
    );
    final serverTotal = await _fetchServerTotal(detail, countsNotifier);
    if (!mounted) return;
    await countsNotifier.mergeFromServerCounts({detail.id: serverTotal});
    if (!mounted) return;
    countsNotifier.addCount(
      groupAccumulatorId: detail.id,
      groups: const [],
      count: count,
    );
    try {
      await ref
          .read(malaSyncManagerProvider)
          .flushAndSettle(SyncReason.roundComplete);
    } catch (_) {}
    if (!mounted) return;
    refreshGroupAccumulatorData(
      ref,
      accumulatorId: detail.id,
      groupId: detail.groupId,
    );
  }

  /// Falls back to the greatest known total so a failed fetch never seeds a
  /// lower count than what was already recorded.
  Future<int> _fetchServerTotal(
    GroupAccumulatorDetail detail,
    GroupAccumulationCountsNotifier countsNotifier,
  ) async {
    final result = await ref
        .read(groupAccumulatorRepositoryProvider)
        .getGroupAccumulator(detail.id);
    return result.fold(
      (_) => math.max(
        detail.user?.totalCount ?? 0,
        countsNotifier.countFor(detail.id),
      ),
      (fresh) => fresh.user?.totalCount ?? 0,
    );
  }
}

class _EventSubTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _EventSubTabButton({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final inactiveColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
          ),
          Container(
            height: 2,
            color:
                selected
                    ? activeColor
                    : (isDark ? AppColors.cardBorderDark : AppColors.grey300),
          ),
        ],
      ),
    );
  }
}

class _EventTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _EventTabButton({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        selected
            ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)
            : (isDark ? AppColors.textTertiaryDark : AppColors.textSecondary);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            Container(
              height: 2,
              color: selected ? textColor : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _VideosPanel extends StatelessWidget {
  final List<GroupEventLink> videos;
  final GroupEvent event;
  final bool isDark;

  const _VideosPanel({
    required this.videos,
    required this.event,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return _VideoLinkCard(
          link: videos[index],
          event: event,
          isDark: isDark,
        );
      },
    );
  }
}

Future<void> _openLink(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// YouTube thumbnail that plays in the in-app full-screen player; any other
/// video host falls back to the event image and opens externally.
class _VideoLinkCard extends StatelessWidget {
  final GroupEventLink link;
  final GroupEvent event;
  final bool isDark;

  const _VideoLinkCard({
    required this.link,
    required this.event,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final videoId = YoutubePlayer.convertUrlToId(link.url);
    final placeholderColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.grey100;
    final label = link.label?.trim() ?? '';

    return GestureDetector(
      onTap: () => _play(context, videoId),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (videoId != null)
              CachedNetworkImageWidget(
                imageUrl: 'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                fit: BoxFit.cover,
                errorWidget: ColoredBox(color: placeholderColor),
              )
            else if (event.image != null && !event.image!.isEmpty)
              ResponsiveCoverImage(image: event.image, fit: BoxFit.cover)
            else
              ColoredBox(color: placeholderColor),
            Container(color: Colors.black.withValues(alpha: 0.18)),
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
            if (label.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _play(BuildContext context, String? videoId) {
    if (videoId == null) {
      _openLink(link.url);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => YoutubeVideoPlayer(
              videoUrl: link.url,
              title: link.label?.trim() ?? '',
            ),
      ),
    );
  }
}

class _AboutPanel extends StatelessWidget {
  final GroupEvent event;
  final bool isDark;

  const _AboutPanel({required this.event, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final description = event.description?.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child:
          description != null && description.isNotEmpty
              ? PlanInlineMarkdownView(
                content: description,
                fontSize: getLocalizedFontSize(AppTextSize.body),
              )
              : Text(
                context.l10n.connect_event_about_empty,
                style: TextStyle(
                  color:
                      isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textSecondary,
                ),
              ),
    );
  }
}
