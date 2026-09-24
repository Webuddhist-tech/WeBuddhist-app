import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/plans_search_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_plan_list_tile.dart';

class AllPlansScreen extends StatelessWidget {
  const AllPlansScreen({
    super.key,
    required this.seriesList,
    required this.onTap,
  });

  final List<Series> seriesList;
  final ValueChanged<Series> onTap;

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'plans-search'),
        builder: (_) => PlansSearchScreen(onTap: onTap),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.home_shortcut_plans,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.search_for_plans,
            onPressed: () => _openSearch(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: seriesList.length,
        itemBuilder: (context, index) {
          final series = seriesList[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PracticePlanListTile(
              series: series,
              onTap: () => onTap(series),
            ),
          );
        },
      ),
    );
  }
}
