import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_live_utils.dart';

/// Video / audio-only switch for the event live stream.
class GroupEventMediaToggle extends StatelessWidget {
  final bool audioOnly;
  final ValueChanged<bool> onChanged;

  const GroupEventMediaToggle({
    super.key,
    required this.audioOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _PillSegments(
      selectedIndex: audioOnly ? 1 : 0,
      onSelected: (index) => onChanged(index == 1),
      segments: [
        _Segment(
          icon: AppAssets.monitorPlay,
          tooltip: context.l10n.event_live_video_mode,
        ),
        _Segment(
          icon: AppAssets.headphones,
          tooltip: context.l10n.event_live_audio_mode,
        ),
      ],
    );
  }
}

/// Stream language switch (en / bo / zh).
class GroupEventLanguageToggle extends StatelessWidget {
  final String language;
  final ValueChanged<String> onChanged;

  const GroupEventLanguageToggle({
    super.key,
    required this.language,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const languages = GroupEventLiveUtils.languages;
    return _PillSegments(
      selectedIndex: languages.indexOf(language).clamp(0, languages.length - 1),
      onSelected: (index) => onChanged(languages[index]),
      segments: [
        for (final code in languages)
          _Segment(
            label: GroupEventLiveUtils.languageLabels[code] ?? code,
            tooltip: code,
          ),
      ],
    );
  }
}

class _Segment {
  final IconData? icon;
  final String? label;
  final String tooltip;

  const _Segment({this.icon, this.label, required this.tooltip});
}

class _PillSegments extends StatelessWidget {
  final int selectedIndex;
  final List<_Segment> segments;
  final ValueChanged<int> onSelected;

  const _PillSegments({
    required this.selectedIndex,
    required this.segments,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark ? AppColors.surfaceVariantDark : AppColors.grey100;
    final thumbColor = isDark ? AppColors.grey800 : AppColors.surfaceWhite;
    final activeColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final inactiveColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < segments.length; i++)
            Tooltip(
              message: segments[i].tooltip,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selectedIndex ? thumbColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child:
                      segments[i].icon != null
                          ? Icon(
                            segments[i].icon,
                            size: 18,
                            color:
                                i == selectedIndex
                                    ? activeColor
                                    : inactiveColor,
                          )
                          : Text(
                            segments[i].label ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.2,
                              fontWeight:
                                  i == selectedIndex
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                              color:
                                  i == selectedIndex
                                      ? activeColor
                                      : inactiveColor,
                            ),
                          ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
