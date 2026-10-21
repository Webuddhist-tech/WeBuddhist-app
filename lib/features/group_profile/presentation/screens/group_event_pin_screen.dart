import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/place_search_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_event_composer_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Pan the map under a fixed pin; the centre is the venue.
class GroupEventPinScreen extends ConsumerStatefulWidget {
  final PlaceSearchResult? initialPlace;
  final GroupEventVenueDraft? current;

  const GroupEventPinScreen({super.key, this.initialPlace, this.current});

  /// Pops with the pinned venue (named from the lookup when one exists).
  static Future<GroupEventVenueDraft?> show(
    BuildContext context, {
    PlaceSearchResult? initialPlace,
    GroupEventVenueDraft? current,
  }) {
    return Navigator.of(
      context,
      rootNavigator: true,
    ).push<GroupEventVenueDraft>(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'group-event-pin'),
        builder:
            (_) => GroupEventPinScreen(
              initialPlace: initialPlace,
              current: current,
            ),
      ),
    );
  }

  @override
  ConsumerState<GroupEventPinScreen> createState() =>
      _GroupEventPinScreenState();
}

class _GroupEventPinScreenState extends ConsumerState<GroupEventPinScreen> {
  static const _worldCenter = LatLng(20, 78);
  static const _worldZoom = 3.0;
  static const _placeZoom = 15.0;

  final MapController _map = MapController();
  Timer? _lookupTimer;
  int _lookupGeneration = 0;
  LatLng? _center;
  String? _name;
  String? _address;
  bool _isLookingUp = false;

  @override
  void initState() {
    super.initState();
    final place = widget.initialPlace;
    final current = widget.current;
    if (place != null) {
      _center = LatLng(place.latitude, place.longitude);
      _name = place.primary;
      _address = place.label;
    } else if (current != null) {
      _center = LatLng(current.latitude, current.longitude);
      _name = current.name;
      _address = current.address;
    }
  }

  @override
  void dispose() {
    _lookupTimer?.cancel();
    _map.dispose();
    super.dispose();
  }

  void _onMoved(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    final center = camera.center;
    _lookupGeneration++;
    setState(() {
      _center = center;
      _name = null;
      _address = null;
      _isLookingUp = false;
    });
    _lookupTimer?.cancel();
    _lookupTimer = Timer(
      const Duration(milliseconds: 600),
      () => _lookup(center),
    );
  }

  Future<void> _lookup(LatLng point) async {
    final datasource = ref.read(placeSearchDatasourceProvider);
    if (datasource == null) return;
    final generation = ++_lookupGeneration;
    setState(() => _isLookingUp = true);
    final place = await datasource.reverse(point.latitude, point.longitude);
    if (!mounted || generation != _lookupGeneration) return;
    setState(() {
      _isLookingUp = false;
      _name = place?.primary;
      _address = place?.label;
    });
  }

  void _confirm() {
    final center = _center;
    if (center == null) return;
    final fallback = context.l10n.group_event_pin_unnamed;
    Navigator.of(context).pop(
      GroupEventVenueDraft(
        name: (_name?.trim().isNotEmpty ?? false) ? _name!.trim() : fallback,
        latitude: double.parse(center.latitude.toStringAsFixed(6)),
        longitude: double.parse(center.longitude.toStringAsFixed(6)),
        address: _address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final hasPin = _center != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.group_event_drop_pin),
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _center ?? _worldCenter,
                    initialZoom: hasPin ? _placeZoom : _worldZoom,
                    onPositionChanged: _onMoved,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'org.pecha.app',
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(l10n.group_event_map_attribution),
                      ],
                    ),
                  ],
                ),
                IgnorePointer(
                  child: Padding(
                    // Lift the glyph so its tip sits on the centre.
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.group_event_pin_marker,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.surfaceWhite,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(
                          AppAssets.mapPinFill,
                          size: 40,
                          color: AppColors.primaryDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.cardBorderDark : AppColors.grey300,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.group_event_selected_location.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color:
                            isDark
                                ? AppColors.accentGold
                                : AppColors.accentGoldDarkest,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      !hasPin
                          ? l10n.group_event_drop_pin_hint
                          : _isLookingUp
                          ? '…'
                          : (_name ?? l10n.group_event_pin_unnamed),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hasPin)
                      Text(
                        _address ??
                            '${_center!.latitude.toStringAsFixed(5)}, ${_center!.longitude.toStringAsFixed(5)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: secondaryColor),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: hasPin && !_isLookingUp ? _confirm : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark
                                  ? AppColors.surfaceWhite
                                  : AppColors.textPrimary,
                          foregroundColor:
                              isDark
                                  ? AppColors.textPrimary
                                  : AppColors.surfaceWhite,
                          disabledBackgroundColor:
                              isDark
                                  ? AppColors.surfaceVariantDark
                                  : AppColors.grey100,
                          disabledForegroundColor:
                              isDark ? AppColors.grey500 : AppColors.grey600,
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: Text(
                          l10n.group_event_confirm_location,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
