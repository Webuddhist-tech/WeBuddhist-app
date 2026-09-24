import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_explore_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/all_recitations_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/utils/recitation_reader_navigation.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_chant_list_tile.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_section_container.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_section_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PracticeChantsSection extends ConsumerWidget {
  const PracticeChantsSection({super.key});

  static const _previewCount = practiceExploreRecitationsPreviewLimit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final recitationsAsync = ref.watch(practiceExploreRecitationsProvider);

    return recitationsAsync.when(
      data:
          (either) =>
              either.fold((_) => const SizedBox.shrink(), (page) {
                if (page.recitations.isEmpty) return const SizedBox.shrink();
                final preview = page.recitations;
                final showSeeAll = page.total > _previewCount;
                return PracticeSectionContainer(
                  title: l10n.home_chants,
                  seeAllLabel: showSeeAll ? l10n.see_all : null,
                  onSeeAll:
                      showSeeAll ? () => _showAllRecitations(context) : null,
                  child: Column(
                    children:
                        preview
                            .map(
                              (r) => PracticeChantListTile(
                                recitation: r,
                                onTap:
                                    () => openRecitationReader(context, r),
                              ),
                            )
                            .toList(),
                  ),
                );
              }),
      loading:
          () => const PracticeSectionSkeleton(
            height: 176,
            itemCount: 2,
            itemSpacing: 8,
            cardBorderRadius: 12,
            style: PracticeSectionSkeletonStyle.chantTile,
          ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showAllRecitations(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'all-recitations'),
        builder: (_) => const AllRecitationsScreen(),
      ),
    );
  }
}
