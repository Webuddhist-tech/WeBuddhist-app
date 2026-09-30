import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// Welcome screen: "Welcome to WeBuddhist".
class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          // Scrolls only when the content cannot fit (short screens, large
          // text); otherwise the spacers spread it over the full height.
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    Text(
                      l10n.onboarding_welcome,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      l10n.appTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        fontFamily: getFontFamily('en'),
                        color: onSurface,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(flex: 2),
                    Image.asset(
                      AppAssets.weBuddhistLogo,
                      height: 168,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.self_improvement_rounded,
                          size: 120,
                          color: AppColors.primary,
                        );
                      },
                    ),
                    const Spacer(flex: 3),
                    _PillButton(
                      label: l10n.onboarding_find_peace,
                      onPressed: onNext,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
