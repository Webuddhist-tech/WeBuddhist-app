import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_recitations_paginated_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_chant_list_tile.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_list_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Multi-select chants screen. Returns the full selected list on confirm.
Future<List<RecitationModel>?> openAddChantsToCollectionScreen(
  BuildContext context, {
  List<RecitationModel> initiallySelected = const [],
}) {
  return Navigator.of(context).push<List<RecitationModel>>(
    MaterialPageRoute(
      builder:
          (_) => AddChantsToCollectionScreen(
            initiallySelected: initiallySelected,
          ),
    ),
  );
}

class AddChantsToCollectionScreen extends ConsumerStatefulWidget {
  const AddChantsToCollectionScreen({
    super.key,
    this.initiallySelected = const [],
  });

  final List<RecitationModel> initiallySelected;

  @override
  ConsumerState<AddChantsToCollectionScreen> createState() =>
      _AddChantsToCollectionScreenState();
}

class _AddChantsToCollectionScreenState
    extends ConsumerState<AddChantsToCollectionScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late final Map<String, RecitationModel> _selectedById;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedById = {
      for (final item in widget.initiallySelected) item.textId: item,
    };
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isSearching) return;
    final languageCode = ref.read(practiceRecitationsLanguageProvider);
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(practiceRecitationsPaginatedProvider(languageCode).notifier)
          .loadMore();
    }
  }

  void _toggle(RecitationModel recitation) {
    setState(() {
      if (_selectedById.containsKey(recitation.textId)) {
        _selectedById.remove(recitation.textId);
      } else {
        _selectedById[recitation.textId] = recitation;
      }
    });
  }

  void _openSearch() {
    setState(() => _isSearching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    final languageCode = ref.read(practiceRecitationsLanguageProvider);
    _searchController.clear();
    ref.read(practiceRecitationSearchProvider(languageCode).notifier).clear();
    setState(() => _isSearching = false);
  }

  void _onSearchChanged(String query) {
    final languageCode = ref.read(practiceRecitationsLanguageProvider);
    ref.read(practiceRecitationSearchProvider(languageCode).notifier).search(
      query,
    );
  }

  void _confirm() {
    Navigator.of(context).pop(_selectedById.values.toList());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageCode = ref.watch(practiceRecitationsLanguageProvider);
    final buttonBg = isDark ? AppColors.surfaceWhite : AppColors.textPrimary;
    final buttonFg = isDark ? AppColors.textPrimary : AppColors.onPrimary;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed:
              _isSearching
                  ? _closeSearch
                  : () => Navigator.of(context).pop(),
        ),
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        context.l10n.my_recitation_collection_search_chants,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                )
                : Text(
                  context.l10n.my_recitation_collection_add_chants,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        centerTitle: !_isSearching,
        scrolledUnderElevation: 0,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _openSearch,
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child:
                _isSearching
                    ? _buildSearchBody(languageCode)
                    : _buildListBody(languageCode),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16 + bottomInset,
            child: Material(
              color: buttonBg,
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.25),
              shape: const StadiumBorder(),
              child: InkWell(
                onTap: _confirm,
                customBorder: const StadiumBorder(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    context.l10n.my_recitation_collection_add_to_collection,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: buttonFg,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListBody(String languageCode) {
    final state = ref.watch(practiceRecitationsPaginatedProvider(languageCode));

    if (state.isLoading && state.recitations.isEmpty) {
      return const RecitationListSkeleton(
        variant: RecitationListSkeletonVariant.chantTile,
      );
    }

    if (state.error != null && state.recitations.isEmpty) {
      return ErrorStateWidget(
        error: state.error!,
        onRetry:
            () =>
                ref
                    .read(
                      practiceRecitationsPaginatedProvider(
                        languageCode,
                      ).notifier,
                    )
                    .retry(),
      );
    }

    if (state.recitations.isEmpty) {
      return Center(child: Text(context.l10n.recitations_no_content));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: state.recitations.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.recitations.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child:
                  state.isLoadingMore
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
            ),
          );
        }

        final recitation = state.recitations[index];
        return _selectableTile(recitation);
      },
    );
  }

  Widget _buildSearchBody(String languageCode) {
    final searchState = ref.watch(
      practiceRecitationSearchProvider(languageCode),
    );
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      return const SizedBox.shrink();
    }

    if (searchState.isLoading && searchState.results.isEmpty) {
      return const RecitationListSkeleton(
        variant: RecitationListSkeletonVariant.chantTile,
      );
    }

    if (searchState.error != null && searchState.results.isEmpty) {
      return ErrorStateWidget(
        error: searchState.error!,
        onRetry: () => _onSearchChanged(query),
      );
    }

    if (searchState.results.isEmpty) {
      return Center(child: Text(context.l10n.recitations_no_content));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: searchState.results.length,
      itemBuilder: (context, index) {
        return _selectableTile(searchState.results[index]);
      },
    );
  }

  Widget _selectableTile(RecitationModel recitation) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedById.containsKey(recitation.textId);
    final iconColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return PracticeChantListTile(
      recitation: recitation,
      onTap: () => _toggle(recitation),
      trailing: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: iconColor.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Icon(
            isSelected ? AppAssets.check : AppAssets.plus,
            size: 18,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
