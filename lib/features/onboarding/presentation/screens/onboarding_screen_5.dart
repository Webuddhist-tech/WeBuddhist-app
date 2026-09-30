import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Last onboarding screen: "You're all set".
class OnboardingScreen5 extends StatelessWidget {
  const OnboardingScreen5({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Column(
            children: [
              Image.asset(AppAssets.weBuddhistLogo, height: 112),
              const SizedBox(height: 28),
              Text(
                l10n.onboarding_all_set,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.onboarding_all_set_description,
                textAlign: TextAlign.center,
                strutStyle: context.tibetanStrutStyle(15),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: onSurface.withValues(alpha: 0.55),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 28),
              _FeatureCard(
                icon: PhosphorIconsRegular.bell,
                title: l10n.onboarding_all_set_practice_title,
                body: l10n.onboarding_all_set_practice_body,
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: PhosphorIconsRegular.users,
                title: l10n.onboarding_all_set_connect_title,
                body: l10n.onboarding_all_set_connect_body,
              ),
              const Spacer(),
              _PillButton(
                label: l10n.onboarding_find_peace,
                onPressed: onComplete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : const Color(0xFFE6E4DE),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: onSurface),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  strutStyle: context.tibetanStrutStyle(16),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  strutStyle: context.tibetanStrutStyle(14),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: onSurface.withValues(alpha: 0.55),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandblue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
