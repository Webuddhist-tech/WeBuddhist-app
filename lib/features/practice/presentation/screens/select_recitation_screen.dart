import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/screen_cache_builder.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_list_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SelectRecitationScreen extends ConsumerWidget {
  const SelectRecitationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final recitationsAsync = ref.watch(recitationsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(
          localizations.routine_add_recitation,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      body: ScreenCacheBuilder<List<RecitationModel>>(
        value: recitationsAsync,
        skeleton: const RecitationListSkeleton(),
        onRetry: () => ref.invalidate(recitationsFutureProvider),
        data: (recitations) {
          if (recitations.isEmpty) {
            return Center(
              child: Text(
                localizations.recitations_no_content,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            itemCount: recitations.length,
            itemBuilder: (context, index) {
              final recitation = recitations[index];
              return _SelectableRecitationCard(
                title: recitation.title,
                onTap: () => Navigator.of(context).pop(recitation),
              );
            },
          );
        },
      ),
    );
  }
}

class _SelectableRecitationCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SelectableRecitationCard({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
