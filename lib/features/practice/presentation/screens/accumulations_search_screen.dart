import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/accumulation_search_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_accumulation_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccumulationsSearchScreen extends ConsumerStatefulWidget {
  const AccumulationsSearchScreen({
    super.key,
    required this.language,
    required this.onTap,
  });

  final String language;
  final ValueChanged<Mantra> onTap;

  @override
  ConsumerState<AccumulationsSearchScreen> createState() =>
      _AccumulationsSearchScreenState();
}

class _AccumulationsSearchScreenState
    extends ConsumerState<AccumulationsSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onSearchTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _focusNode.dispose();
    ref.read(accumulationSearchProvider.notifier).clear();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    ref.read(accumulationSearchProvider.notifier).search(query);
  }

  void _onClear() {
    _searchController.clear();
    ref.read(accumulationSearchProvider.notifier).clear();
    _focusNode.requestFocus();
  }

  void _onBack() {
    ref.read(accumulationSearchProvider.notifier).clear();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final searchState = ref.watch(accumulationSearchProvider);
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _onBack,
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      onChanged: _onQueryChanged,
                      textInputAction: TextInputAction.search,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: context.l10n.accumulations_search,
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: subtitleColor,
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 20,
                          color: subtitleColor,
                        ),
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                  onPressed: _onClear,
                                  icon: Icon(
                                    Icons.clear,
                                    size: 20,
                                    color: subtitleColor,
                                  ),
                                )
                                : null,
                        filled: true,
                        fillColor:
                            isDark
                                ? AppColors.surfaceDark
                                : AppColors.surfaceWhite,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(context, searchState, subtitleColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AccumulationSearchState searchState,
    Color subtitleColor,
  ) {
    final l10n = context.l10n;

    if (searchState.query.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    if (searchState.isLoading && searchState.results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.error != null && searchState.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                searchState.error!,
                style: TextStyle(color: subtitleColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(accumulationSearchProvider.notifier).retry(),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (searchState.results.isEmpty && !searchState.isLoading) {
      return Center(
        child: Text(
          l10n.accumulations_no_found,
          style: TextStyle(color: subtitleColor),
        ),
      );
    }

    return LayoutBuilder(
      builder:
          (context, constraints) => GridView.builder(
            gridDelegate: PracticeAccumulationItem.gridDelegate(
              widget.language,
              constraints.maxWidth,
            ),
            itemCount: searchState.results.length,
            itemBuilder: (context, index) {
              final mantra = searchState.results[index];
              return PracticeAccumulationItem(
                mantra: mantra,
                language: widget.language,
                onTap: () => widget.onTap(mantra),
              );
            },
          ),
    );
  }
}
