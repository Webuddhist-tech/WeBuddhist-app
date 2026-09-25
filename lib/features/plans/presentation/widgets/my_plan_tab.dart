import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/home/presentation/providers/routine_info_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/plans_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/my_plans_paginated_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/utils/plan_analytics.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/user_plan_card.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MyPlansTab extends ConsumerStatefulWidget {
  final TabController controller;
  const MyPlansTab({super.key, required this.controller});

  @override
  ConsumerState<MyPlansTab> createState() => _MyPlansTabState();
}

class _MyPlansTabState extends ConsumerState<MyPlansTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when 200px from bottom
      ref.read(myPlansPaginatedProvider.notifier).loadMore();
    }
  }

  Future<void> _handleUnenroll(
    BuildContext context,
    UserPlansModel plan,
  ) async {
    try {
      // Call the provider to unenroll
      final resultEither = await ref.read(
        userPlanUnsubscribeFutureProvider(plan.id).future,
      );

      final success = resultEither.fold(
        (failure) => false,
        (success) => success,
      );
      if (!mounted) return;

      if (success) {
        // The card's status badge keeps the completion status loaded.
        final completion =
            ref.exists(userPlanDaysCompletionStatusProvider(plan.id))
                ? ref
                    .read(userPlanDaysCompletionStatusProvider(plan.id))
                    .valueOrNull
                    ?.fold((_) => null, (status) => status)
                : null;
        ref
            .read(planAnalyticsProvider)
            .planUnenrolled(
              planId: plan.id,
              planName: plan.title,
              daysCompleted: completion?.values.where((v) => v).length,
              daysSinceEnrolled: PlanUtils.daysBetween(
                plan.startedAt,
                DateTime.now(),
              ),
            );
        // Refresh the plans list and home stats
        ref.invalidate(myPlansPaginatedProvider);
        ref.invalidate(findPlansPaginatedProvider);
        ref.invalidate(userPlansFutureProvider);
        ref.invalidate(routineInfoFutureProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.unenrollSuccess(plan.title)),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.unenrollError),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.unenrollGenericError),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Check if user is guest - show login prompt instead of calling APIs
    if (authState.isGuest) {
      return _GuestLoginPrompt(
        onLogin: () {
          LoginDrawer.show(context, ref);
        },
      );
    }

    final myPlansState = ref.watch(myPlansPaginatedProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(myPlansPaginatedProvider.notifier).refresh(),
      child: _buildContent(context, myPlansState),
    );
  }

  Widget _buildContent(BuildContext context, MyPlansState myPlansState) {
    if (myPlansState.isLoading && myPlansState.plans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (myPlansState.error != null && myPlansState.plans.isEmpty) {
      return ErrorStateWidget(
        error: myPlansState.error!,
        onRetry: () => ref.read(myPlansPaginatedProvider.notifier).retry(),
        customMessage: context.l10n.unableToLoad,
      );
    }

    if (myPlansState.plans.isEmpty && !myPlansState.isLoading) {
      return _EmptyMyPlansState(
        onBrowsePlans: () {
          widget.controller.animateTo(1);
        },
      );
    }

    return ListView.separated(
      controller: _scrollController,
      separatorBuilder: (context, index) => const SizedBox(height: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      itemCount: myPlansState.plans.length + (myPlansState.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == myPlansState.plans.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child:
                  myPlansState.isLoadingMore
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
            ),
          );
        }

        final plan = myPlansState.plans[index];
        final effectiveStart = plan.effectiveStartDate;
        final selectedDay = PlanUtils.calculateSelectedDay(
          effectiveStart,
          plan.totalDays,
        );

        return UserPlanCard(
          plan: plan,
          onTap: () {
            context.push(
              '/plans/details',
              extra: {
                'plan': plan,
                'selectedDay': selectedDay,
                'startDate': effectiveStart,
              },
            );
          },
          onDelete: () => _handleUnenroll(context, plan),
        );
      },
    );
  }
}

/// Login prompt widget shown to guest users
class _GuestLoginPrompt extends StatelessWidget {
  const _GuestLoginPrompt({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 60,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.my_plans_sign_in_prompt,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onLogin,
              icon: const Icon(Icons.login),
              label: Text(l10n.signIn),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMyPlansState extends ConsumerWidget {
  final VoidCallback onBrowsePlans;

  const _EmptyMyPlansState({required this.onBrowsePlans});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = getLocalizedFontSize(AppTextSize.body);
    final localizations = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              localizations.practice_plan,
              style: TextStyle(color: Colors.grey[600], fontSize: fontSize),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onBrowsePlans,
              icon: const Icon(Icons.explore),
              label: Text(
                localizations.browse_plans,
                style: TextStyle(fontSize: fontSize),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
