import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_recitations_paginated_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/utils/recitation_reader_navigation.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_chant_list_tile.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitation_search_provider.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_list_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecitationsSearchScreen extends ConsumerStatefulWidget {
  const RecitationsSearchScreen({super.key, required this.languageCode});

  final String languageCode;

  @override
  ConsumerState<RecitationsSearchScreen> createState() =>
      _RecitationsSearchScreenState();
}

class _RecitationsSearchScreenState
    extends ConsumerState<RecitationsSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  RecitationSearchNotifier _searchNotifier(String languageCode) =>
      ref.read(practiceRecitationSearchProvider(languageCode).notifier);

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
    // No clear() here: `ref` cannot be used in dispose, and the search
    // provider is autoDispose, so its results are dropped once this screen
    // stops watching it.
    super.dispose();
  }

  void _onQueryChanged(String query, String languageCode) {
    _searchNotifier(languageCode).search(query);
  }

  void _onClear(String languageCode) {
    _searchController.clear();
    _searchNotifier(languageCode).clear();
    _focusNode.requestFocus();
  }

  void _onBack(String languageCode) {
    _searchNotifier(languageCode).clear();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final languageCode = widget.languageCode;
    final searchState = ref.watch(
      practiceRecitationSearchProvider(languageCode),
    );
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
                    onPressed: () => _onBack(languageCode),
                    icon: const Icon(AppAssets.arrowLeft),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      onChanged: (query) => _onQueryChanged(query, languageCode),
                      textInputAction: TextInputAction.search,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: context.l10n.recitations_search,
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
                                  onPressed: () => _onClear(languageCode),
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
              child: _buildBody(
                context,
                searchState,
                subtitleColor,
                languageCode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    RecitationSearchState searchState,
    Color subtitleColor,
    String languageCode,
  ) {
    final l10n = context.l10n;

    if (searchState.query.trim().length <
        RecitationSearchNotifier.minQueryLength) {
      return const SizedBox.shrink();
    }

    if (searchState.isLoading && searchState.results.isEmpty) {
      return const RecitationListSkeleton(
        variant: RecitationListSkeletonVariant.chantTile,
      );
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
                onPressed:
                    () => _searchNotifier(languageCode).retry(),
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
          l10n.recitations_no_found,
          style: TextStyle(color: subtitleColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: searchState.results.length,
      itemBuilder: (context, index) {
        final recitation = searchState.results[index];
        return PracticeChantListTile(
          recitation: recitation,
          onTap: () => openRecitationReader(
            context,
            recitation,
            listLanguage: widget.languageCode,
          ),
        );
      },
    );
  }
}
