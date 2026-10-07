import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/group_search_provider.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/group_search_result_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupSearchScreen extends ConsumerStatefulWidget {
  const GroupSearchScreen({super.key});

  @override
  ConsumerState<GroupSearchScreen> createState() => _GroupSearchScreenState();
}

class _GroupSearchScreenState extends ConsumerState<GroupSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
    _scrollController.removeListener(_onScroll);
    _searchController.removeListener(_onSearchTextChanged);
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(groupSearchProvider.notifier).loadMore();
    }
  }

  void _onQueryChanged(String query) {
    ref.read(groupSearchProvider.notifier).search(query);
  }

  void _onClear() {
    _searchController.clear();
    ref.read(groupSearchProvider.notifier).clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final searchState = ref.watch(groupSearchProvider);
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
                    onPressed: () {
                      ref.read(groupSearchProvider.notifier).clear();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      onChanged: _onQueryChanged,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: context.l10n.search_groups,
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: subtitleColor,
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          AppAssets.exploreUnselected,
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
            Expanded(child: _buildBody(context, searchState, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    GroupSearchState searchState,
    bool isDark,
  ) {
    if (searchState.query.trim().isEmpty) {
      return _EmptySearchState(
        title: context.l10n.search_for_groups,
        isDark: isDark,
      );
    }

    if (searchState.isLoading && searchState.results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.error != null && searchState.results.isEmpty) {
      return _ErrorSearchState(
        message: context.l10n.connect_failed_load_discover_groups_error,
        onRetry: () => ref.read(groupSearchProvider.notifier).retry(),
      );
    }

    if (searchState.results.isEmpty && !searchState.isLoading) {
      return _EmptySearchState(
        title: context.l10n.no_groups_found,
        isDark: isDark,
        icon: Icons.search_off,
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: searchState.results.length + (searchState.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == searchState.results.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child:
                  searchState.isLoadingMore
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
            ),
          );
        }

        return GroupSearchResultCard(group: searchState.results[index]);
      },
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({
    required this.title,
    required this.isDark,
    this.icon = Icons.search,
  });

  final String title;
  final bool isDark;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: subtitleColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: subtitleColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorSearchState extends StatelessWidget {
  const _ErrorSearchState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}
