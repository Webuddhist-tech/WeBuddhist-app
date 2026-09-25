import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/utils/auth_analytics.dart';
import 'package:flutter_pecha/features/more/domain/entities/user_stats.dart';
import 'package:flutter_pecha/shared/widgets/main_tab_app_bar.dart';
import 'package:flutter_pecha/features/more/presentation/providers/use_case_providers.dart';
import 'package:flutter_pecha/features/more/presentation/providers/user_stats_provider.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/me_profile_header.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/me_stats_section.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/me_stats_section_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: MainTabAppBar(
        title: localizations.nav_me,
        actions: [
          IconButton(
            icon: Icon(
              AppAssets.settings,
              size: 24,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () => context.push('/home/settings'),
          ),
        ],
      ),
      body:
          (authState.isLoggedIn && !authState.isGuest)
              ? const _LoggedInProfile()
              : const _GuestView(),
    );
  }
}

class _LoggedInProfile extends ConsumerStatefulWidget {
  const _LoggedInProfile();

  @override
  ConsumerState<_LoggedInProfile> createState() => _LoggedInProfileState();
}

class _LoggedInProfileState extends ConsumerState<_LoggedInProfile>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshStatsInBackground();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatsInBackground();
    }
  }

  void _refreshStatsInBackground() {
    unawaited(ref.read(userStatsRepositoryProvider).refreshUserStats());
  }

  Future<void> _refreshStats() async {
    await ref.read(userStatsRepositoryProvider).refreshUserStats();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).user;
    final statsAsync = ref.watch(userStatsFutureProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = statsAsync.maybeWhen(
      data: (either) => either.fold((_) => UserStats.empty, (stats) => stats),
      orElse: () => UserStats.empty,
    );

    return RefreshIndicator(
      onRefresh: _refreshStats,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MeProfileHeader(user: user),
                  if (statsAsync.isLoading && !statsAsync.hasValue)
                    const MeStatsSectionSkeleton()
                  else
                    MeStatsSection(stats: stats),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GuestView extends ConsumerWidget {
  const _GuestView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    void startLogin(String connection) {
      ref
          .read(authAnalyticsProvider)
          .loginStarted(method: connection, source: AuthSource.meScreen);
      authNotifier.login(connection: connection, source: AuthSource.meScreen);
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIOS = Platform.isIOS;

    final localizations = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            // Keeps the column vertically centred when it fits, and lets it
            // scroll instead of overflowing on short screens or at large text
            // scales, where three sign-in buttons no longer fit.
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.grey300,
                  child: Icon(
                    AppAssets.profile,
                    size: 44,
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  localizations.me_guest_headline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 34,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  localizations.me_guest_subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.grey600),
                ),
                const SizedBox(height: 40),
                if (authState.isLoading)
                  const SizedBox(
                    height: 52,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _SocialButton(
                    onTap: () => startLogin('google'),
                    backgroundColor: isDark ? AppColors.cardDark : Colors.white,
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    borderColor:
                        isDark ? AppColors.cardBorderDark : AppColors.grey300,
                    label: localizations.continueWithGoogle,
                    icon: Image.asset(
                      AppAssets.googleIcon,
                      width: 23,
                      height: 23,
                    ),
                  ),
                  if (isIOS) ...[
                    const SizedBox(height: 14),
                    _SocialButton(
                      onTap: () => startLogin('apple'),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      borderColor: Colors.transparent,
                      label: localizations.continueWithApple,
                      icon: const Icon(
                        AppAssets.apple,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _SocialButton(
                    onTap: () => startLogin('sms'),
                    backgroundColor: isDark ? AppColors.cardDark : Colors.white,
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    borderColor:
                        isDark ? AppColors.cardBorderDark : AppColors.grey300,
                    label: localizations.continueWithPhone,
                    icon: Icon(
                      Icons.phone_android,
                      color: isDark ? Colors.white : Colors.black87,
                      size: 23,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.label,
    required this.icon,
  });

  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final String label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
