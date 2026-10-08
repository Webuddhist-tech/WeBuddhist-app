import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_progress_bar.dart';

/// Shared chrome for the language and tradition onboarding steps:
/// progress, optional back chevron, title, options, and a pill Continue.
class OnboardingChoiceScaffold extends StatelessWidget {
  const OnboardingChoiceScaffold({
    super.key,
    required this.stepIndex,
    required this.title,
    required this.options,
    required this.onContinue,
    this.subtitle,
    this.onBack,
    this.continueEnabled = true,
    this.isSaving = false,
  });

  static const stepCount = 2;

  /// Zero-based index within [stepCount].
  final int stepIndex;
  final String title;
  final String? subtitle;
  final Widget options;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;
  final bool continueEnabled;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final canContinue = continueEnabled && !isSaving && onContinue != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingProgressBar(
                currentStep: stepIndex,
                totalSteps: stepCount,
              ),
              if (onBack != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: onBack,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Icon(
                        Icons.chevron_left,
                        size: 28,
                        color: onSurface,
                      ),
                    ),
                  ),
                ),
              ] else
                const SizedBox(height: 28),
              Text(
                title,
                strutStyle: context.tibetanStrutStyle(26, compact: true),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                  height: 1.25,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  strutStyle: context.tibetanStrutStyle(15),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: onSurface.withValues(alpha: 0.55),
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Expanded(child: SingleChildScrollView(child: options)),
              const SizedBox(height: 12),
              _ContinueButton(
                enabled: canContinue,
                isSaving: isSaving,
                onPressed: onContinue,
              ),
            ],
          ),
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
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandblue,
          disabledBackgroundColor: AppColors.greyLight,
          foregroundColor: Colors.white,
          disabledForegroundColor: AppColors.grey500,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }
}
