import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/localization/app_language.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_markdown_editor.dart';

/// Step 1 of the event composer: cover, languages, name and description.
class GroupEventAboutStep extends StatelessWidget {
  final GroupEventCover? cover;
  final List<AppLanguage> languages;
  final List<String> selectedLanguages;
  final String activeLanguage;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final bool enabled;
  final VoidCallback onPickCover;
  final ValueChanged<String> onLanguageTap;
  final VoidCallback onAddLanguage;

  const GroupEventAboutStep({
    super.key,
    required this.cover,
    required this.languages,
    required this.selectedLanguages,
    required this.activeLanguage,
    required this.nameController,
    required this.descriptionController,
    required this.onPickCover,
    required this.onLanguageTap,
    required this.onAddLanguage,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(l10n.group_event_cover_image, isDark: isDark),
          const SizedBox(height: 8),
          _CoverField(
            cover: cover,
            isDark: isDark,
            onTap: enabled ? onPickCover : null,
          ),
          const SizedBox(height: 20),
          _SectionLabel(l10n.group_event_name_and_description, isDark: isDark),
          const SizedBox(height: 10),
          _LanguageChips(
            languages: languages,
            selected: selectedLanguages,
            active: activeLanguage,
            isDark: isDark,
            onTap: enabled ? onLanguageTap : null,
            onAdd: enabled ? onAddLanguage : null,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.group_event_name_label,
            style: TextStyle(fontSize: 13, color: secondaryColor),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nameController,
            enabled: enabled,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 16),
            decoration: _fieldDecoration(
              context,
              hint: l10n.group_event_name_hint,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 16),
          GroupEventMarkdownEditor(
            controller: descriptionController,
            label: l10n.group_event_description_label,
            hint: l10n.group_event_description_hint,
            enabled: enabled,
          ),
        ],
      ),
    );
  }

  static InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hint,
    required bool isDark,
  }) {
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 16,
        color: isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
      ),
      filled: true,
      fillColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
      enabledBorder: border(borderColor),
      disabledBorder: border(borderColor),
      focusedBorder: border(
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: isDark ? AppColors.accentGold : AppColors.accentGoldDarkest,
      ),
    );
  }
}

class _CoverField extends StatelessWidget {
  const _CoverField({
    required this.cover,
    required this.isDark,
    required this.onTap,
  });

  final GroupEventCover? cover;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cover = this.cover;

    return AspectRatio(
      aspectRatio: 16 / 7,
      child:
          cover == null
              ? _EmptyCover(isDark: isDark, onTap: onTap)
              : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    switch (cover) {
                      GroupEventCoverFile(:final file) => Image.file(
                        file,
                        fit: BoxFit.cover,
                      ),
                      GroupEventCoverUrl(:final url) =>
                        CachedNetworkImageWidget(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          errorWidget: ColoredBox(
                            color:
                                isDark
                                    ? AppColors.surfaceVariantDark
                                    : AppColors.grey100,
                          ),
                        ),
                    },
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Material(
                        color: AppColors.textPrimary,
                        shape: const StadiumBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: onTap,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              l10n.group_event_change_cover,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.surfaceWhite,
                              ),
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

class _EmptyCover extends StatelessWidget {
  const _EmptyCover({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.grey500 : AppColors.grey600;
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: isDark ? AppColors.cardBorderDark : AppColors.grey400,
        radius: 12,
      ),
      child: Material(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppAssets.image, size: 28, color: color),
                const SizedBox(height: 8),
                Text(
                  context.l10n.group_event_add_cover_photo,
                  style: TextStyle(fontSize: 14, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    const dash = 6.0;
    const gap = 4.0;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius;
}

class _LanguageChips extends StatelessWidget {
  const _LanguageChips({
    required this.languages,
    required this.selected,
    required this.active,
    required this.isDark,
    required this.onTap,
    required this.onAdd,
  });

  final List<AppLanguage> languages;
  final List<String> selected;
  final String active;
  final bool isDark;
  final ValueChanged<String>? onTap;
  final VoidCallback? onAdd;

  String _labelFor(String code) {
    return languages
            .where((language) => language.code == code)
            .firstOrNull
            ?.nativeName ??
        code;
  }

  @override
  Widget build(BuildContext context) {
    final activeBackground =
        isDark ? AppColors.surfaceWhite : AppColors.textPrimary;
    final activeForeground =
        isDark ? AppColors.textPrimary : AppColors.surfaceWhite;
    final idleBackground =
        isDark ? AppColors.surfaceVariantDark : AppColors.grey100;
    final idleForeground =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    Widget chip({
      required Widget child,
      required bool isActive,
      required VoidCallback? onPressed,
      String? tooltip,
    }) {
      final button = Material(
        color: isActive ? activeBackground : idleBackground,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? activeForeground : idleForeground,
              ),
              child: IconTheme.merge(
                data: IconThemeData(color: idleForeground, size: 16),
                child: child,
              ),
            ),
          ),
        ),
      );
      return tooltip == null
          ? button
          : Tooltip(message: tooltip, child: button);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final code in selected)
          chip(
            isActive: code == active,
            onPressed: onTap == null ? null : () => onTap!(code),
            child: Text(_labelFor(code)),
          ),
        chip(
          isActive: false,
          onPressed: onAdd,
          tooltip: context.l10n.group_event_languages_add,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Icon(AppAssets.plus),
          ),
        ),
      ],
    );
  }
}
