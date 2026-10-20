import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_sheet.dart';

/// Names a pinned spot; pops with the finished venue.
class GroupEventVenueNameSheet extends StatefulWidget {
  final GroupEventVenueDraft venue;
  final VoidCallback onChangePlace;

  const GroupEventVenueNameSheet({
    super.key,
    required this.venue,
    required this.onChangePlace,
  });

  /// Pops with the venue, or null to go back and change the place.
  static Future<GroupEventVenueDraft?> show(
    BuildContext context, {
    required GroupEventVenueDraft venue,
    required VoidCallback onChangePlace,
  }) {
    return GroupEventSheet.show<GroupEventVenueDraft>(
      context,
      builder:
          (_) => GroupEventVenueNameSheet(
            venue: venue,
            onChangePlace: onChangePlace,
          ),
    );
  }

  @override
  State<GroupEventVenueNameSheet> createState() =>
      _GroupEventVenueNameSheetState();
}

class _GroupEventVenueNameSheetState extends State<GroupEventVenueNameSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.venue.name,
  );

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final name = _name.text.trim();
    final address = widget.venue.address?.trim() ?? '';

    return GroupEventSheet(
      title: l10n.group_event_name_location,
      footer: GroupEventSheet.primaryButton(
        context,
        label: l10n.group_event_save_venue,
        onPressed:
            name.isEmpty
                ? null
                : () => Navigator.of(
                  context,
                ).pop(widget.venue.copyWith(name: name)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(AppAssets.mapPin, size: 20, color: secondaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.venue.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (address.isNotEmpty)
                          Text(
                            address,
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onChangePlace();
                    },
                    child: Text(
                      l10n.group_event_change_cover,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentGoldDarkest,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: dividerColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.group_event_venue_name,
                    style: TextStyle(fontSize: 13, color: secondaryColor),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _name,
                    autofocus: true,
                    maxLength: 255,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: l10n.group_event_venue_name_hint,
                      hintStyle: TextStyle(fontSize: 16, color: secondaryColor),
                      filled: true,
                      fillColor:
                          isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.surfaceWhite,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
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
                        vertical: 14,
                      ),
                    ),
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
