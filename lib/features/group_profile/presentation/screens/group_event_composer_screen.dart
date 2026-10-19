import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/localization/app_language.dart';
import 'package:flutter_pecha/core/localization/languages_providers.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/destructive_confirmation_dialog.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_about_step.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_cover_sheet.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_languages_sheet.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_posting_to_row.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Multi-step event composer. Pops with the created event, or null.
class GroupEventComposerScreen extends ConsumerStatefulWidget {
  final GroupProfile profile;

  const GroupEventComposerScreen({super.key, required this.profile});

  static const int stepCount = 4;

  static Future<GroupEvent?> show(BuildContext context, GroupProfile profile) {
    return Navigator.of(context).push<GroupEvent>(
      MaterialPageRoute(
        fullscreenDialog: true,
        settings: const RouteSettings(name: 'group-event-composer'),
        builder:
            (_) =>
                ClarityMask(child: GroupEventComposerScreen(profile: profile)),
      ),
    );
  }

  @override
  ConsumerState<GroupEventComposerScreen> createState() =>
      _GroupEventComposerScreenState();
}

class _GroupEventComposerScreenState
    extends ConsumerState<GroupEventComposerScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  int _step = 0;
  GroupEventDraft _draft = const GroupEventDraft();
  String _activeLanguage = AppConfig.englishLanguageCode;
  bool get _isAboutStep => _step == 0;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _seedLanguages();
  }

  /// English plus the reader's content language, in API list order.
  void _seedLanguages() {
    final contentLanguage = ref.read(contentLanguageProvider);
    final preselected = {AppConfig.englishLanguageCode, contentLanguage};
    final available = ref.read(resolvedContentLanguagesProvider);
    _applyLanguages(_ordered(preselected, available));
    _activeLanguage =
        _draft.languages.contains(contentLanguage)
            ? contentLanguage
            : _draft.languages.first;
    _loadActiveLanguage();
  }

  List<String> _ordered(Set<String> codes, List<AppLanguage> available) {
    final ordered = [
      for (final language in available)
        if (codes.contains(language.code)) language.code,
    ];
    // Codes the list doesn't know yet still get a row.
    for (final code in codes) {
      if (!ordered.contains(code)) ordered.add(code);
    }
    return ordered;
  }

  void _applyLanguages(List<String> languages) {
    _draft = _draft.copyWith(
      metadata: [
        for (final code in languages)
          _draft.metadataFor(code) ?? GroupEventDraftMetadata(language: code),
      ],
    );
  }

  void _onFieldChanged() {
    _saveActiveLanguage();
    setState(() {});
  }

  void _saveActiveLanguage() {
    final current = _draft.metadataFor(_activeLanguage);
    if (current == null) return;
    final updated = current.copyWith(
      name: _nameController.text,
      description: _descriptionController.text,
    );
    _draft = _draft.copyWith(
      metadata: [
        for (final m in _draft.metadata)
          m.language == _activeLanguage ? updated : m,
      ],
    );
  }

  void _loadActiveLanguage() {
    final metadata = _draft.metadataFor(_activeLanguage);
    _nameController.value = TextEditingValue(
      text: metadata?.name ?? '',
      selection: TextSelection.collapsed(offset: metadata?.name.length ?? 0),
    );
    _descriptionController.value = TextEditingValue(
      text: metadata?.description ?? '',
      selection: TextSelection.collapsed(
        offset: metadata?.description.length ?? 0,
      ),
    );
  }

  void _switchLanguage(String code) {
    if (code == _activeLanguage) return;
    setState(() {
      _activeLanguage = code;
      _loadActiveLanguage();
    });
  }

  Future<void> _addLanguage() async {
    final available = ref.read(resolvedContentLanguagesProvider);
    final chosen = await GroupEventLanguagesSheet.show(
      context,
      languages: available,
      selected: _draft.languages.toSet(),
    );
    if (chosen == null || !mounted) return;
    setState(() {
      _applyLanguages(_ordered(chosen, available));
      if (!_draft.languages.contains(_activeLanguage)) {
        _activeLanguage = _draft.languages.first;
        _loadActiveLanguage();
      }
    });
  }

  Future<void> _pickCover() async {
    FocusScope.of(context).unfocus();
    final cover = await GroupEventCoverSheet.show(
      context,
      groupCoverUrl: widget.profile.bannerUrl,
      current: _draft.cover,
    );
    if (cover == null || !mounted) return;
    setState(() => _draft = _draft.copyWith(cover: cover));
  }

  bool get _canContinue {
    return switch (_step) {
      0 => _draft.hasName,
      _ => _step < GroupEventComposerScreen.stepCount - 1,
    };
  }

  void _continue() {
    if (!_canContinue) return;
    FocusScope.of(context).unfocus();
    setState(() => _step += 1);
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step -= 1);
  }

  Future<void> _onClose() async {
    if (!_draft.hasContent) {
      Navigator.of(context).pop();
      return;
    }
    await _confirmDiscard();
  }

  Future<void> _confirmDiscard() async {
    final l10n = context.l10n;
    final discard = await showDestructiveConfirmationDialog(
      context,
      title: l10n.group_event_discard_title,
      message: l10n.group_event_discard_message,
      confirmLabel: l10n.group_post_discard,
      cancelLabel: l10n.group_post_keep_editing,
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final languages = ref.watch(resolvedContentLanguagesProvider);

    return PopScope(
      canPop: !_draft.hasContent,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmDiscard();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(l10n, isDark),
              _StepProgress(
                step: _step,
                total: GroupEventComposerScreen.stepCount,
                isDark: isDark,
                label: _stepLabel(l10n),
              ),
              Divider(height: 1, thickness: 1, color: dividerColor),
              GroupPostingToRow(profile: widget.profile, isDark: isDark),
              Divider(height: 1, thickness: 1, color: dividerColor),
              Expanded(child: _buildStep(languages)),
              _buildBottomBar(l10n, isDark, dividerColor),
            ],
          ),
        ),
      ),
    );
  }

  String _stepLabel(AppLocalizations l10n) {
    final step = l10n.group_event_step_of(
      _step + 1,
      GroupEventComposerScreen.stepCount,
    );
    return _isAboutStep ? '$step · ${l10n.group_event_step_about}' : step;
  }

  Widget _buildStep(List<AppLanguage> languages) {
    if (_isAboutStep) {
      return GroupEventAboutStep(
        cover: _draft.cover,
        languages: languages,
        selectedLanguages: _draft.languages,
        activeLanguage: _activeLanguage,
        nameController: _nameController,
        descriptionController: _descriptionController,
        onPickCover: _pickCover,
        onLanguageTap: _switchLanguage,
        onAddLanguage: _addLanguage,
      );
    }
    // Later steps land here in follow-up work.
    return const SizedBox.expand();
  }

  Widget _buildTopBar(AppLocalizations l10n, bool isDark) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            l10n.group_event_new_title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          if (!_isAboutStep)
            Positioned(
              left: 4,
              child: IconButton(
                onPressed: _back,
                tooltip: l10n.back,
                icon: Icon(AppAssets.arrowLeft, color: secondaryColor),
              ),
            ),
          Positioned(
            right: 4,
            child: IconButton(
              onPressed: _onClose,
              tooltip: l10n.cancel,
              icon: Icon(AppAssets.x, color: secondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    AppLocalizations l10n,
    bool isDark,
    Color dividerColor,
  ) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final showHint = _isAboutStep && !_draft.hasName;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHint) ...[
                Text(
                  l10n.group_event_name_required_hint,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: secondaryColor),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _canContinue ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
                    foregroundColor:
                        isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
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
                    l10n.group_event_continue,
                    strutStyle: context.tibetanStrutStyle(16),
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
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({
    required this.step,
    required this.total,
    required this.isDark,
    required this.label,
  });

  final int step;
  final int total;
  final bool isDark;
  final String label;

  @override
  Widget build(BuildContext context) {
    final doneColor = isDark ? AppColors.surfaceWhite : AppColors.textPrimary;
    final todoColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var index = 0; index < total; index++) ...[
                if (index > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: index <= step ? doneColor : todoColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: secondaryColor)),
        ],
      ),
    );
  }
}
