import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/localization/content_language_picker_sheet.dart';
import 'package:flutter_pecha/core/localization/languages_providers.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_recitations_paginated_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/recitations_search_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/utils/recitation_reader_navigation.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/new_collection_dialog.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_chant_list_tile.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_my_chants_collection_list_tile.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_list_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AllRecitationsScreen extends ConsumerStatefulWidget {
  const AllRecitationsScreen({super.key});

  @override
  ConsumerState<AllRecitationsScreen> createState() =>
      _AllRecitationsScreenState();
}

class _AllRecitationsScreenState extends ConsumerState<AllRecitationsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _languageRestored = false;
  bool _isCreateFlowOpen = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Prefetch so the language picker usually opens already resolved.
    ref.read(recitationContentLanguagesProvider);
    _restoreLanguage();
  }

  // Waits for the persisted pick so the first page is not fetched in the app
  // language and immediately refetched.
  Future<void> _restoreLanguage() async {
    await ref
        .read(practiceRecitationsLanguageProvider.notifier)
        .ensureInitialized();
    if (!mounted) return;
    setState(() => _languageRestored = true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final languageCode = ref.read(practiceRecitationsLanguageProvider);
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(practiceRecitationsPaginatedProvider(languageCode).notifier)
          .loadMore();
    }
  }

  // Both actions resolve the language themselves: tapping before the persisted
  // pick has loaded must not fall back to the app content language.
  Future<void> _openSearch() async {
    await _ensureLanguageRestored();
    if (!mounted) return;
    final languageCode = ref.read(practiceRecitationsLanguageProvider);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecitationsSearchScreen(languageCode: languageCode),
      ),
    );
  }

  Future<void> _openLanguagePicker() async {
    await _ensureLanguageRestored();
    if (!mounted) return;
    final selectedCode = ref.read(practiceRecitationsLanguageProvider);
    showContentLanguagePickerSheet(
      context,
      selectedCode: selectedCode,
      recitationOnly: true,
      onSelected: (code) {
        ref
            .read(practiceRecitationsLanguageProvider.notifier)
            .setLanguage(code);
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      },
    );
  }

  Future<void> _ensureLanguageRestored() => ref
          .read(practiceRecitationsLanguageProvider.notifier)
          .ensureInitialized();

  Future<void> _onCreateCollectionPressed() async {
    // Guests and expired sessions both lack credentials for the protected
    // collection endpoints. This screen is pushed imperatively, so the route
    // guard does not re-run if auth changes underneath it.
    final auth = ref.read(authProvider);
    if (auth.isGuest || !auth.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    setState(() => _isCreateFlowOpen = true);
    try {
      await showNewCollectionDialog(context);
    } finally {
      // Restore the FAB even if the flow throws, not just when it completes.
      if (mounted) {
        setState(() => _isCreateFlowOpen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = ref.watch(practiceRecitationsLanguageProvider);
    final recitationsState =
        _languageRestored
            ? ref.watch(practiceRecitationsPaginatedProvider(languageCode))
            : const PracticeRecitationsState(isLoading: true);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.home_chants,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.recitations_search_for,
            onPressed: _openSearch,
          ),
          IconButton(
            icon: const Icon(AppAssets.language),
            tooltip: l10n.language,
            onPressed: _openLanguagePicker,
          ),
        ],
      ),
      body: _buildBody(context, recitationsState, languageCode),
      floatingActionButton:
          _isCreateFlowOpen
              ? null
              : _CreateCollectionButton(
                onPressed: _onCreateCollectionPressed,
              ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PracticeRecitationsState state,
    String languageCode,
  ) {
    if (state.isLoading && state.isEmpty) {
      return const RecitationListSkeleton(
        variant: RecitationListSkeletonVariant.chantTile,
      );
    }

    if (state.error != null && state.isEmpty) {
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

    if (state.isEmpty) {
      return Center(child: Text(context.l10n.recitations_no_content));
    }

    final collectionCount = state.collections.length;
    final recitationCount = state.recitations.length;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      itemCount: collectionCount + recitationCount + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < collectionCount) {
          final collection = state.collections[index];
          return PracticeMyChantsCollectionListTile(
            collection: collection,
            onTap: () {
              context.pushNamed(
                'my-recitation-collection',
                pathParameters: {'collectionId': collection.collectionId},
                extra: {'title': collection.name},
              );
            },
          );
        }

        final recitationIndex = index - collectionCount;
        if (recitationIndex == recitationCount) {
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

        final recitation = state.recitations[recitationIndex];
        return PracticeChantListTile(
          recitation: recitation,
          onTap:
              () => openRecitationReader(
                context,
                recitation,
                listLanguage: languageCode,
              ),
        );
      },
    );
  }
}

class _CreateCollectionButton extends StatelessWidget {
  const _CreateCollectionButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.surfaceWhite : AppColors.textPrimary;
    final foregroundColor =
        isDark ? AppColors.textPrimary : AppColors.onPrimary;

    return Material(
      color: backgroundColor,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.25),
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.my_recitation_collection_create_button,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(AppAssets.plus, size: 20, color: foregroundColor),
            ],
          ),
        ),
      ),
    );
  }
}
