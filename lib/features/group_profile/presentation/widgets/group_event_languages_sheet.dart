import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/localization/app_language.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Checkbox list of the languages an event can be written in.
class GroupEventLanguagesSheet extends StatefulWidget {
  final List<AppLanguage> languages;
  final Set<String> selected;

  const GroupEventLanguagesSheet({
    super.key,
    required this.languages,
    required this.selected,
  });

  /// Pops with the chosen codes, or null when dismissed.
  static Future<Set<String>?> show(
    BuildContext context, {
    required List<AppLanguage> languages,
    required Set<String> selected,
  }) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder:
          (_) => GroupEventLanguagesSheet(
            languages: languages,
            selected: selected,
          ),
    );
  }

  @override
  State<GroupEventLanguagesSheet> createState() =>
      _GroupEventLanguagesSheetState();
}

class _GroupEventLanguagesSheetState extends State<GroupEventLanguagesSheet> {
  late final Set<String> _selected = {...widget.selected};

  void _toggle(String code) {
    setState(() {
      if (_selected.contains(code)) {
        // At least one language must stay.
        if (_selected.length > 1) _selected.remove(code);
      } else {
        _selected.add(code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.group_event_languages_title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(AppAssets.x),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: dividerColor),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.languages.length,
                separatorBuilder:
                    (_, _) =>
                        Divider(height: 1, thickness: 1, color: dividerColor),
                itemBuilder: (context, index) {
                  final language = widget.languages[index];
                  final checked = _selected.contains(language.code);
                  return InkWell(
                    onTap: () => _toggle(language.code),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 16, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              language.nativeName,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          Checkbox(
                            value: checked,
                            onChanged: (_) => _toggle(language.code),
                            activeColor:
                                isDark
                                    ? AppColors.surfaceWhite
                                    : AppColors.textPrimary,
                            checkColor:
                                isDark
                                    ? AppColors.textPrimary
                                    : AppColors.surfaceWhite,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Divider(height: 1, thickness: 1, color: dividerColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Text(
                l10n.group_event_languages_hint,
                style: TextStyle(fontSize: 12, color: secondaryColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
                    foregroundColor:
                        isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.done,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
