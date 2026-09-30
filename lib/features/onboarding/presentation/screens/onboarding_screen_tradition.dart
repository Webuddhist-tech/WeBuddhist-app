import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/onboarding/application/tradition_selection_provider.dart';
import 'package:flutter_pecha/features/onboarding/application/tradition_selection_state.dart';
import 'package:flutter_pecha/features/onboarding/presentation/utils/onboarding_analytics.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_checkbox_option.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_choice_scaffold.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Onboarding screen: check one or more Buddhist tradition paths.
class OnboardingScreenTradition extends ConsumerWidget {
  const OnboardingScreenTradition({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  Future<void> _handleContinue(BuildContext context, WidgetRef ref) async {
    final saved =
        await ref.read(traditionSelectionProvider.notifier).submitSelection();
    if (!context.mounted || !saved) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.something_went_wrong)),
        );
      }
      return;
    }
    // Only a count reaches analytics, never which traditions.
    ref
        .read(onboardingAnalyticsProvider)
        .traditionsChosen(
          count: ref.read(traditionSelectionProvider).selectedCodes.length,
        );
    onNext();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selectionState = ref.watch(traditionSelectionProvider);

    ref.listen<TraditionSelectionState>(traditionSelectionProvider, (
      previous,
      next,
    ) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.something_went_wrong)));
      }
    });

    return OnboardingChoiceScaffold(
      stepIndex: 1,
      title: l10n.onboarding_tradition_title,
      subtitle: l10n.onboarding_tradition_subtitle,
      onBack: onBack,
      continueEnabled: selectionState.hasSelection,
      isSaving: selectionState.isSaving,
      onContinue: () => _handleContinue(context, ref),
      options: _buildOptions(context, ref, selectionState),
    );
  }

  Widget _buildOptions(
    BuildContext context,
    WidgetRef ref,
    TraditionSelectionState selectionState,
  ) {
    if (selectionState.isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (selectionState.error != null && selectionState.paths.isEmpty) {
      return Center(
        child: TextButton(
          onPressed:
              () => ref.read(traditionSelectionProvider.notifier).loadPaths(),
          child: Text(context.l10n.something_went_wrong),
        ),
      );
    }

    final l10n = context.l10n;
    final notifier = ref.read(traditionSelectionProvider.notifier);

    return Column(
      children: [
        for (final path in selectionState.paths)
          OnboardingCheckboxOption(
            label: path.title,
            isChecked: selectionState.selectedCodes.contains(path.code),
            onTap: () => notifier.toggleTradition(path.code),
          ),
        OnboardingCheckboxOption(
          label: l10n.onboarding_tradition_show_all_title,
          isChecked: selectionState.isAllSelected,
          onTap: notifier.toggleAll,
          bordered: false,
        ),
      ],
    );
  }
}
