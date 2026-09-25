import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/onboarding/application/tradition_selection_provider.dart';
import 'package:flutter_pecha/features/onboarding/application/tradition_selection_state.dart';
import 'package:flutter_pecha/features/onboarding/data/models/tradition_models.dart';
import 'package:flutter_pecha/features/onboarding/presentation/utils/onboarding_analytics.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_back_button.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Onboarding screen: select a Buddhist tradition path.
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
    // Only a count reaches analytics: one tradition, or none for "show all".
    final isShowAll = ref.read(traditionSelectionProvider).isShowAllSelected;
    ref.read(onboardingAnalyticsProvider).traditionsChosen(
      count: isShowAll ? 0 : 1,
    );
    onNext();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selectionState = ref.watch(traditionSelectionProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final subtitleColor = onSurface.withValues(alpha: 0.65);

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              OnboardingBackButton(onBack: onBack),
              const SizedBox(height: 16),
              Text(
                l10n.onboarding_tradition_title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.onboarding_tradition_subtitle,
                strutStyle: context.tibetanStrutStyle(16),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _buildOptions(context, ref, selectionState, onSurface),
              ),
              _ContinueButton(
                isEnabled: selectionState.hasSelection,
                isSaving: selectionState.isSaving,
                onContinue: () => _handleContinue(context, ref),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptions(
    BuildContext context,
    WidgetRef ref,
    TraditionSelectionState selectionState,
    Color onSurface,
  ) {
    if (selectionState.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
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

    return ListView(
      children: [
        ...selectionState.paths.map(
          (path) => _TraditionRadioOption(
            id: path.code,
            title: path.title,
            description: path.description,
            selectedId: selectionState.selectedCode,
            onSelect:
                ref.read(traditionSelectionProvider.notifier).selectTradition,
          ),
        ),
        _TraditionRadioOption(
          id: traditionShowAllCode,
          title: l10n.onboarding_tradition_show_all_title,
          description: l10n.onboarding_tradition_show_all_description,
          selectedId: selectionState.selectedCode,
          onSelect:
              ref.read(traditionSelectionProvider.notifier).selectTradition,
        ),
      ],
    );
  }
}

class _TraditionRadioOption extends StatelessWidget {
  const _TraditionRadioOption({
    required this.id,
    required this.title,
    required this.description,
    required this.selectedId,
    required this.onSelect,
  });

  final String id;
  final String title;
  final String description;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  bool get isSelected => selectedId == id;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final descriptionColor = onSurface.withValues(alpha: 0.65);

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: () => onSelect(id),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _RadioIndicator(isSelected: isSelected),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                      height: 1.4,
                    ),
                  ),
                  if (description.isNotEmpty)
                    Text(
                      strutStyle: context.tibetanStrutStyle(15),
                      description,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: descriptionColor,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  const _RadioIndicator({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.brandblue : AppColors.greyMedium,
          width: 2,
        ),
        color: isSelected ? AppColors.brandblue : Colors.transparent,
      ),
      child:
          isSelected
              ? const Center(
                child: Icon(Icons.circle, size: 10, color: Colors.white),
              )
              : null,
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.isEnabled,
    required this.isSaving,
    required this.onContinue,
  });

  final bool isEnabled;
  final bool isSaving;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isEnabled && !isSaving ? onContinue : null,
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
                  width: 24,
                  height: 24,
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
