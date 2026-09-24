import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/accumulations_search_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_accumulation_item.dart';

class AllAccumulationsScreen extends StatelessWidget {
  const AllAccumulationsScreen({
    super.key,
    required this.mantras,
    required this.language,
    required this.onTap,
  });

  final List<Mantra> mantras;
  final String language;
  final ValueChanged<Mantra> onTap;

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'accumulations-search'),
        builder:
            (_) => AccumulationsSearchScreen(language: language, onTap: onTap),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.accumulations,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.accumulations_search_for,
            onPressed: () => _openSearch(context),
          ),
        ],
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
        ),
        itemCount: mantras.length,
        itemBuilder: (context, index) {
          final mantra = mantras[index];
          return PracticeAccumulationItem(
            mantra: mantra,
            language: language,
            onTap: () => onTap(mantra),
          );
        },
      ),
    );
  }
}
