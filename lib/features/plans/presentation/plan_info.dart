import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/onboarding/presentation/providers/event_enrollment_providers.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_date_format.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/author_detail_screen.dart';
import 'package:flutter_pecha/shared/extensions/typography_extensions.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PlanInfo extends ConsumerStatefulWidget {
  const PlanInfo({super.key, required this.plan, this.author});
  final Plan plan;
  final String? author;
  @override
  ConsumerState<PlanInfo> createState() => _PlanInfoState();
}

class _PlanInfoState extends ConsumerState<PlanInfo> {
  bool _isEnrolling = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isGuest = authState.isGuest;
    final isLoggedIn = authState.isLoggedIn;

    // Get enrolled plan IDs
    List<String> enrolledPlanIds = [];
    if (!isGuest && isLoggedIn) {
      final subscribedPlans = ref.watch(userPlansFutureProvider);
      enrolledPlanIds =
          subscribedPlans.valueOrNull?.fold(
            (failure) => <String>[],
            (response) => response.userPlans.map((e) => e.id).toList(),
          ) ??
          <String>[];
    }

    final language = widget.plan.language.toLowerCase();
    final localizations = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        title: Text(localizations.plan_info, style: TextStyle(fontSize: 20)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlanImage(context),
              _buildPlanTitleDays(context, language),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildPlanDescription(context),
              ),
              const SizedBox(height: 16),
              _buildAuthorAvatar(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildActionButtons(
                  context,
                  enrolledPlanIds,
                  isGuest,
                  language,
                  localizations,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanImage(BuildContext context) {
    return ResponsiveCoverImage(
      image: widget.plan.coverImage,
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.25,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _buildPlanTitleDays(BuildContext context, String language) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.plan.title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: context.languageTitleStyle(language),
                ),
                SizedBox(height: 4),
                Text(
                  context.l10n.days_count(widget.plan.totalDays),
                  style: context.languageTextStyle(
                    language,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          _buildAuthorAvatar(context),
        ],
      ),
    );
  }

  Widget _buildPlanDescription(BuildContext context) {
    return Text(
      widget.plan.description,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildAuthorAvatar(BuildContext context) {
    final authorId = widget.plan.authorId;

    // Handle null author case
    if (authorId.isEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, color: Colors.grey[600], size: 20),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: 'author-detail'),
            builder: (context) => AuthorDetailScreen(authorId: authorId),
          ),
        );
      },
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, color: Colors.grey[600], size: 20),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    List<String> enrolledPlanIds,
    bool isGuest,
    String language,
    AppLocalizations localizations,
  ) {
    final isSubscribed = enrolledPlanIds.contains(widget.plan.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enrollBackgroundColor =
        isDark ? AppColors.surfaceWhite : AppColors.scaffoldBackgroundDark;
    final enrollForegroundColor =
        isDark ? AppColors.textPrimary : AppColors.textPrimaryDark;
    final subscribedBackgroundColor = isDark ? AppColors.grey800 : Colors.grey;
    final subscribedForegroundColor = AppColors.onPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tags
        if (widget.plan.tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                widget.plan.tags.take(3).map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainer,
                  );
                }).toList(),
          ),
        const SizedBox(height: 16),
        // Enroll/Start button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                _isEnrolling
                    ? null
                    : () {
                      if (isSubscribed) {
                        context.push('/practice');
                      } else {
                        _handleEnroll(context);
                      }
                    },
            style: FilledButton.styleFrom(
              backgroundColor:
                  isSubscribed
                      ? subscribedBackgroundColor
                      : enrollBackgroundColor,
              foregroundColor:
                  isSubscribed
                      ? subscribedForegroundColor
                      : enrollForegroundColor,
              disabledBackgroundColor: enrollBackgroundColor.withValues(
                alpha: 0.5,
              ),
              disabledForegroundColor: enrollForegroundColor.withValues(
                alpha: 0.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                _isEnrolling
                    ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: enrollForegroundColor,
                      ),
                    )
                    : Text(
                      isSubscribed
                          ? localizations.plan_go_to_practice
                          : localizations.plan_enroll,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleEnroll(BuildContext context) async {
    final localizations = context.l10n;
    setState(() => _isEnrolling = true);
    try {
      final service = ref.read(eventEnrollmentServiceProvider);
      await service.enrollInEvents([widget.plan.id]);
      ref.invalidate(userPlansFutureProvider);

      if (!context.mounted) return;

      final startDate = widget.plan.startDate;
      if (startDate != null) {
        final today = DateUtils.dateOnly(DateTime.now());
        final normalizedStart = DateUtils.dateOnly(startDate.toLocal());
        final formattedDate = PlanDateFormat.formatDate(normalizedStart);

        if (today.isBefore(normalizedStart)) {
          await showDialog<void>(
            context: context,
            builder:
                (ctx) => AlertDialog(
                  title: Text(localizations.plan_starts_soon_title),
                  content: Text(
                    localizations.plan_starts_soon_message(formattedDate),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(localizations.got_it),
                    ),
                  ],
                ),
          );
        } else if (today.isAfter(normalizedStart)) {
          await showDialog<void>(
            context: context,
            builder:
                (ctx) => AlertDialog(
                  title: Text(localizations.plan_joining_late_title),
                  content: Text(
                    localizations.plan_joining_late_message(formattedDate),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(localizations.got_it),
                    ),
                  ],
                ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(localizations.enrollError)));
      }
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }
}
