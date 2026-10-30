import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_explore_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_accumulations_section.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_chants_section.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_plans_section.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_tab_button.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_timers_section.dart';
import 'package:flutter_pecha/shared/widgets/main_tab_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PracticeExploreScreen extends ConsumerStatefulWidget {
  const PracticeExploreScreen({super.key});

  @override
  ConsumerState<PracticeExploreScreen> createState() =>
      _PracticeExploreScreenState();
}

class _PracticeExploreScreenState extends ConsumerState<PracticeExploreScreen> {
  Future<void> _refreshAll() async {
    final repo = ref.read(practiceExploreRepositoryProvider);
    final language = ref.read(contentLanguageProvider);
    await Future.wait([
      repo.refreshSeries(language),
      repo.refreshRecitations(language),
      repo.refreshAccumulators(language),
      repo.refreshTimers(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: MainTabAppBar(title: l10n.nav_practice),
      body: _buildExploreContent(context),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: PracticeTabButton(
              label: l10n.routine_title,
              variant: PracticeActionButtonVariant.filled,
              backgroundColor: AppColors.myPracticesBackground,
              onTap: () => context.pushNamed('my-practices'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PracticeTabButton(
              label: l10n.bookmarks,
              icon: Icons.bookmark_border,
              variant: PracticeActionButtonVariant.outlined,
              onTap: () {
                if (ref.read(authProvider).isGuest) {
                  LoginDrawer.show(context, ref);
                  return;
                }
                context.pushNamed('bookmarks');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreContent(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: PracticePlansSection()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: _buildActionButtons(context),
            ),
          ),
          const SliverToBoxAdapter(child: PracticeChantsSection()),
          const SliverToBoxAdapter(child: PracticeAccumulationsSection()),
          const SliverToBoxAdapter(child: PracticeTimersSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
