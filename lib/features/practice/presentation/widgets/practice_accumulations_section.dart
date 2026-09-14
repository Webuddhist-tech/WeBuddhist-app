import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_explore_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/all_accumulations_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_accumulation_circle_item.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_section_container.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_section_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PracticeAccumulationsSection extends ConsumerWidget {
  const PracticeAccumulationsSection({super.key});

  static const _previewCount = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final language = ref.watch(localeProvider).languageCode;
    final accumulatorsAsync = ref.watch(practiceExploreAccumulatorsProvider);

    return accumulatorsAsync.when(
      data:
          (either) => either.fold((_) => const SizedBox.shrink(), (mantras) {
            if (mantras.isEmpty) return const SizedBox.shrink();
            final preview = mantras.take(_previewCount).toList();
            final rowHeight = PracticeAccumulationCircleItem.heightOf(context);
            return PracticeSectionContainer(
              title: l10n.accumulations,
              seeAllLabel:
                  mantras.length >= _previewCount ? l10n.see_all : null,
              onSeeAll:
                  mantras.length >= _previewCount
                      ? () =>
                          _showAllAccumulations(context, ref, mantras, language)
                      : null,
              child: SizedBox(
                height: rowHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: preview.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final mantra = preview[index];
                    return Align(
                      alignment: Alignment.topCenter,
                      child: PracticeAccumulationCircleItem(
                        mantra: mantra,
                        language: language,
                        onTap: () => _navigateToMala(context, ref, mantra),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
      loading:
          () => PracticeSectionSkeleton(
            height: PracticeAccumulationCircleItem.heightOf(context),
            axis: Axis.horizontal,
            itemCount: 5,
            itemWidth: 84,
            itemSpacing: 16,
            cardBorderRadius: 42,
          ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _navigateToMala(BuildContext context, WidgetRef ref, Mantra mantra) {
    final isGuest = ref.read(authProvider).isGuest;
    if (isGuest) {
      LoginDrawer.show(context, ref);
      return;
    }
    context.push('/mala', extra: {'presetId': mantra.presetId});
  }

  void _showAllAccumulations(
    BuildContext context,
    WidgetRef ref,
    List<Mantra> mantras,
    String language,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => AllAccumulationsScreen(
              mantras: mantras,
              language: language,
              onTap: (mantra) => _navigateToMala(context, ref, mantra),
            ),
      ),
    );
  }
}
