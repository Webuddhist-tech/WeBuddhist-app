import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_progress_bar.dart';

/// Shared chrome for the profile, language and tradition onboarding steps:
/// progress with an optional back chevron, title, options, and a pill
/// Continue.
///
/// Sizes follow the Figma "Onboarding" frames (390 × 844). Their top bar sits
/// 76 pt and the button bottom 74 pt from the frame edges; the iPhone safe
/// area takes 47 and 34 of that, so the rest is padding here.
class OnboardingChoiceScaffold extends StatelessWidget {
  const OnboardingChoiceScaffold({
    super.key,
    required this.stepIndex,
    required this.title,
    required this.options,
    required this.onContinue,
    this.stepCount = 2,
    this.subtitle,
    this.note,
    this.onBack,
    this.continueEnabled = true,
    this.isSaving = false,
  });

  /// Title color on light backgrounds (Figma "dark-bg").
  static const _titleColor = Color(0xFF020C1D);

  /// Steps in the progress bar: 3 for phone accounts, which also set their
  /// name, otherwise 2.
  final int stepCount;

  /// Zero-based index within [stepCount].
  final int stepIndex;
  final String title;
  final String? subtitle;

  /// Smaller line under [subtitle].
  final String? note;
  final Widget options;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;
  final bool continueEnabled;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? onSurface.withValues(alpha: 0.6) : AppColors.textSecondary;
    final canContinue = continueEnabled && !isSaving && onContinue != null;
    // The back chevron needs a 48-tall tap target. It is centred on the
    // 24-tall progress row, so that row grows by 12 on each side and the
    // padding around it shrinks by the same amount: the bar and the title
    // stay where Figma puts them.
    final hasBack = onBack != null;
    final rowHeight = hasBack ? 48.0 : 24.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The whole page scrolls, not just the options: with the keyboard
            // open a small phone has less height than the heading needs.
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(20, hasBack ? 17 : 29, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: rowHeight,
                      child: Row(
                        children: [
                          if (hasBack)
                            GestureDetector(
                              onTap: onBack,
                              behavior: HitTestBehavior.opaque,
                              // 40 wide: the 24 glyph plus the 16 gap to the
                              // bar, so both keep their place.
                              child: SizedBox(
                                width: 40,
                                height: rowHeight,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Icon(
                                    Icons.chevron_left,
                                    size: 24,
                                    color: onSurface,
                                  ),
                                ),
                              ),
                            ),
                          Expanded(
                            child: OnboardingProgressBar(
                              currentStep: stepIndex,
                              totalSteps: stepCount,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: hasBack ? 32 : 44),
                    Text(
                      title,
                      strutStyle: context.tibetanStrutStyle(34, compact: true),
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: isDark ? onSurface : _titleColor,
                        height: 42 / 34,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        strutStyle: context.tibetanStrutStyle(18),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: secondary,
                          height: 22 / 18,
                        ),
                      ),
                    ],
                    if (note != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        note!,
                        strutStyle: context.tibetanStrutStyle(14),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: secondary,
                          height: 20 / 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    options,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 12, 30, 40),
              child: _ContinueButton(
                enabled: canContinue,
                isSaving: isSaving,
                onPressed: onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.enabled,
    required this.isSaving,
    required this.onPressed,
  });

  final bool enabled;
  final bool isSaving;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandblue,
          disabledBackgroundColor: AppColors.greyLight,
          foregroundColor: Colors.white,
          disabledForegroundColor: AppColors.grey500,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child:
            isSaving
                ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Text(
                  context.l10n.onboarding_continue,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 22 / 18,
                  ),
                ),
      ),
    );
  }
}
