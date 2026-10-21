import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/place_search_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_event_composer_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/screens/group_event_pin_screen.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_sheet.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_venue_name_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the search sheet pops with: a place to refine on the map, or the map.
sealed class _VenueChoice {
  const _VenueChoice();
}

class _PlaceChoice extends _VenueChoice {
  final PlaceSearchResult place;
  const _PlaceChoice(this.place);
}

class _PinChoice extends _VenueChoice {
  const _PinChoice();
}

/// Search an address (when LocationIQ is configured) or drop a pin.
class GroupEventVenueSheet extends ConsumerStatefulWidget {
  const GroupEventVenueSheet({super.key});

  /// Runs search/pin → map → name; null when the reader backed out.
  static Future<GroupEventVenueDraft?> pick(
    BuildContext context, {
    GroupEventVenueDraft? current,
  }) async {
    while (true) {
      final choice = await GroupEventSheet.show<_VenueChoice>(
        context,
        builder: (_) => const GroupEventVenueSheet(),
      );
      if (choice == null || !context.mounted) return null;

      final pinned = await GroupEventPinScreen.show(
        context,
        initialPlace: choice is _PlaceChoice ? choice.place : null,
        current: choice is _PinChoice ? current : null,
      );
      if (pinned == null || !context.mounted) return null;

      var changePlace = false;
      final named = await GroupEventVenueNameSheet.show(
        context,
        venue: pinned,
        onChangePlace: () => changePlace = true,
      );
      if (named != null) return named;
      if (!changePlace || !context.mounted) return null;
    }
  }

  @override
  ConsumerState<GroupEventVenueSheet> createState() =>
      _GroupEventVenueSheetState();
}

class _GroupEventVenueSheetState extends ConsumerState<GroupEventVenueSheet> {
  final TextEditingController _query = TextEditingController();
  Timer? _debounce;
  int _generation = 0;
  List<PlaceSearchResult> _results = const [];
  bool _isSearching = false;
  bool _hasError = false;
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.length < PlaceSearchRemoteDatasource.minQueryLength) {
      _generation++;
      setState(() {
        _results = const [];
        _isSearching = false;
        _hasError = false;
        _searched = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(
      const Duration(milliseconds: 600),
      () => _search(trimmed),
    );
  }

  Future<void> _search(String query) async {
    final datasource = ref.read(placeSearchDatasourceProvider);
    if (datasource == null) return;
    final generation = ++_generation;
    try {
      final results = await datasource.search(query);
      if (!mounted || generation != _generation) return;
      setState(() {
        _results = results;
        _isSearching = false;
        _hasError = false;
        _searched = true;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _results = const [];
        _isSearching = false;
        _hasError = true;
        _searched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final canSearch = ref.watch(placeSearchDatasourceProvider) != null;

    return GroupEventSheet(
      title: l10n.group_event_venue,
      child: ListView(
        shrinkWrap: true,
        children: [
          if (canSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: TextField(
                controller: _query,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: l10n.group_event_venue_search_hint,
                  hintStyle: TextStyle(fontSize: 15, color: secondaryColor),
                  prefixIcon: Icon(
                    AppAssets.exploreUnselected,
                    size: 18,
                    color: secondaryColor,
                  ),
                  filled: true,
                  fillColor:
                      isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceWhite,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_hasError || (_searched && _results.isEmpty))
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: Text(
                _hasError
                    ? l10n.group_event_venue_search_error
                    : l10n.group_event_venue_no_results,
                style: TextStyle(fontSize: 14, color: secondaryColor),
              ),
            )
          else
            for (final place in _results)
              _VenueRow(
                icon: AppAssets.mapPin,
                title: place.primary,
                subtitle: place.secondary,
                onTap: () => Navigator.of(context).pop(_PlaceChoice(place)),
              ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          _VenueRow(
            icon: AppAssets.plus,
            title: l10n.group_event_drop_pin,
            subtitle: l10n.group_event_drop_pin_hint,
            accent: true,
            onTap: () => Navigator.of(context).pop(const _PinChoice()),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _VenueRow extends StatelessWidget {
  const _VenueRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final titleColor =
        accent
            ? (isDark ? AppColors.accentGold : AppColors.accentGoldDarkest)
            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: accent ? titleColor : secondaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: secondaryColor),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
