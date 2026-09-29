import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/share_analytics.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/services/app_share/app_share_service.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/feedback/presentation/widgets/feedback_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Home screen prompt that invites the user to share WeBuddhist with others.
class HomeSharePrompt extends ConsumerWidget {
  const HomeSharePrompt({super.key});

  Future<void> _shareApp(BuildContext context, WidgetRef ref) async {
    final message = await ref
        .read(appShareServiceProvider)
        .buildShareMessage(AppLocalizations.of(context)!.share_app_message);
    final result = await SharePlus.instance.share(ShareParams(text: message));
    if (!context.mounted || !ShareAnalytics.wasUsed(result)) return;
    ref
        .read(shareAnalyticsProvider)
        .contentShared(surface: ShareSurface.app, method: 'link');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PromptLabel(),
          const SizedBox(height: 12.0),
          _PromptButton(
            icon: AppAssets.readerShare,
            label: localizations.share,
            onTap: () => _shareApp(context, ref),
          ),
          const SizedBox(height: 12.0),
          _PromptButton(
            icon: AppAssets.feedback,
            label: localizations.settings_feedback_row,
            onTap: () => FeedbackSheet.show(context),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _PromptLabel extends StatelessWidget {
  const _PromptLabel();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final supportTextColor =
        isDark ? AppColors.grey500 : AppColors.grey600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          localizations.home_share_prompt(localizations.appTitle),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          localizations.home_share_support,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w400,
            color: supportTextColor,
          ),
        ),
      ],
    );
  }
}

class _PromptButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PromptButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.greyLight;

    return Material(
      color: buttonColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: double.infinity,
          height: 52.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22.0, color: colorScheme.onSurface),
              const SizedBox(width: 8.0),
              Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16.0,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
