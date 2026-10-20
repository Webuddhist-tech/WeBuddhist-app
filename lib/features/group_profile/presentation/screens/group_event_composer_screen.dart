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
import 'package:flutter_pecha/features/group_profile/data/models/group_event_request_model.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_event_composer_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_post_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_draft_mapper.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_request_builder.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_schedule_utils.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_about_step.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_cover_sheet.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_languages_sheet.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_practices_step.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_published_view.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_review_step.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_settings_sheet.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_when_where_step.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_posting_to_row.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the composer pops with once an event exists.
class GroupEventComposerResult {
  final GroupEvent event;

  /// True when the reader tapped "View event".
  final bool openEvent;

  /// True when the event was saved as a draft on close, not published.
  final bool isDraft;

  const GroupEventComposerResult(
    this.event, {
    this.openEvent = false,
    this.isDraft = false,
  });
}

/// Multi-step event composer. Pops with the created event, or null.
class GroupEventComposerScreen extends ConsumerStatefulWidget {
  final GroupProfile profile;

  /// A draft from the CMS to continue; null composes a new event.
  final GroupEventEditSource? existing;

  const GroupEventComposerScreen({
    super.key,
    required this.profile,
    this.existing,
  });

  static const int stepCount = 4;

  static Future<GroupEventComposerResult?> show(
    BuildContext context,
    GroupProfile profile, {
    GroupEventEditSource? existing,
  }) {
    return Navigator.of(context).push<GroupEventComposerResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        settings: const RouteSettings(name: 'group-event-composer'),
        builder:
            (_) => ClarityMask(
              child: GroupEventComposerScreen(
                profile: profile,
                existing: existing,
              ),
            ),
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
  final TextEditingController _liveLinkController = TextEditingController();

  int _step = 0;
  GroupEventDraft _draft = const GroupEventDraft();
  bool _isPublishing = false;
  GroupEvent? _published;
  String _activeLanguage = AppConfig.englishLanguageCode;
  bool get _isAboutStep => _step == 0;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _liveLinkController.addListener(_onLiveLinkChanged);
    final existing = widget.existing;
    if (existing != null) {
      _draft = existing.draft;
      _liveLinkController.text = existing.draft.liveLink;
      _resolveIntentions(existing.intentionSlugs);
    }
    _seedLanguages();
  }

  bool get _isEditing => widget.existing != null;

  /// The CMS lists an event's intentions by slug; ids come from the catalog.
  Future<void> _resolveIntentions(List<String> slugs) async {
    if (slugs.isEmpty) return;
    try {
      final catalog = await ref.read(groupEventIntentionsProvider.future);
      if (!mounted) return;
      final ids = [
        for (final intention in catalog)
          if (slugs.contains(intention.slug)) intention.id,
      ];
      setState(() => _draft = _draft.copyWith(intentionIds: ids));
    } catch (_) {
      // Leaving them empty allows every intention; the sheet shows that.
    }
  }

  /// English plus the reader's content language, in API list order.
  void _seedLanguages() {
    final contentLanguage = ref.read(contentLanguageProvider);
    final available = ref.read(resolvedContentLanguagesProvider);
    // A draft keeps the languages it was saved with.
    final preselected =
        _draft.metadata.isNotEmpty
            ? _draft.languages.toSet()
            : {AppConfig.englishLanguageCode, contentLanguage};
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

  void _onLiveLinkChanged() {
    setState(
      () => _draft = _draft.copyWith(liveLink: _liveLinkController.text),
    );
  }

  bool get _isWhenWhereStep => _step == 1;

  bool get _isPracticesStep => _step == 2;

  bool get _isReviewStep => _step == 3;

  GroupEventScheduleIssue? get _scheduleIssue =>
      GroupEventScheduleUtils.validateSchedule(_draft.schedule);

  GroupEventWhereIssue? get _whereIssue =>
      GroupEventScheduleUtils.validateWhere(_draft);

  bool get _canContinue {
    if (_isPublishing) return false;
    return switch (_step) {
      0 => _draft.hasName,
      1 => _scheduleIssue == null && _whereIssue == null,
      2 => true,
      3 => _draft.hasName,
      _ => false,
    };
  }

  /// Why Continue is disabled on the current step, if it is.
  String? _continueHint(AppLocalizations l10n) {
    if (_isAboutStep) {
      return _draft.hasName ? null : l10n.group_event_name_required_hint;
    }
    if (!_isWhenWhereStep) return null;
    switch (_scheduleIssue) {
      case GroupEventScheduleIssue.missingDate:
        return l10n.group_event_pick_date_hint;
      case GroupEventScheduleIssue.missingRecurrence:
        return l10n.group_event_pick_repeats_hint;
      case GroupEventScheduleIssue.endDateBeforeStart:
        return l10n.group_event_end_date_hint;
      case GroupEventScheduleIssue.endTimeBeforeStart:
        return l10n.group_event_end_time_hint;
      case null:
        break;
    }
    return switch (_whereIssue) {
      GroupEventWhereIssue.missingVenue => l10n.group_event_venue_hint,
      GroupEventWhereIssue.missingLink ||
      GroupEventWhereIssue.invalidLink => l10n.group_event_link_required_hint,
      null => null,
    };
  }

  void _continue() {
    if (!_canContinue) return;
    FocusScope.of(context).unfocus();
    if (_isReviewStep) {
      _publish();
      return;
    }
    setState(() => _step += 1);
  }

  void _back() {
    if (_step == 0 || _isPublishing) return;
    setState(() => _step -= 1);
  }

  /// The API needs only a name for a draft; a half-set schedule is skipped.
  bool get _canSaveDraft =>
      _draft.hasName &&
      (_draft.schedule.startDate == null || _scheduleIssue == null);

  Future<void> _onReviewEdit(GroupEventReviewTarget target) async {
    if (_isPublishing) return;
    switch (target) {
      case GroupEventReviewTarget.about:
        setState(() => _step = 0);
      case GroupEventReviewTarget.whenWhere:
        setState(() => _step = 1);
      case GroupEventReviewTarget.practices:
        setState(() => _step = 2);
      case GroupEventReviewTarget.settings:
        final updated = await GroupEventSettingsSheet.show(
          context,
          draft: _draft,
        );
        if (updated == null || !mounted) return;
        setState(() => _draft = updated);
    }
  }

  Future<void> _publish() async {
    final event = await _submit(status: 'published');
    if (event == null || !mounted) return;
    setState(() {
      _isPublishing = false;
      _published = event;
    });
  }

  /// True when the draft was saved and the composer closed.
  Future<bool> _saveDraft() async {
    final event = await _submit(status: 'draft');
    if (event == null || !mounted) return false;
    Navigator.of(context).pop(GroupEventComposerResult(event, isDraft: true));
    return true;
  }

  /// Cover upload, then the venue, then the event; each failure is reported
  /// and the reader can retry. Returns null on failure.
  Future<GroupEvent?> _submit({required String status}) async {
    final l10n = context.l10n;
    final existing = widget.existing;
    setState(() => _isPublishing = true);

    String? imageUrl;
    switch (_draft.cover) {
      case GroupEventCoverFile(:final file):
        final upload = await ref
            .read(groupPostRepositoryProvider)
            .uploadMedia(file);
        imageUrl = upload.fold((_) => null, (key) => key);
        if (imageUrl == null) {
          _publishFailed(l10n.group_post_upload_error);
          return null;
        }
      case GroupEventCoverUrl(:final url):
        // The stored cover is resent only when it changed.
        imageUrl = existing?.imageUrl == url ? null : url;
      case null:
        break;
    }

    final repository = ref.read(groupEventComposerRepositoryProvider);
    String? locationId;
    final venue = _draft.venue;
    if (_draft.format.needsVenue && venue != null) {
      if (existing != null && existing.sameVenue(venue)) {
        locationId = existing.locationId;
      } else {
        final created = await repository.createLocation(
          widget.profile.id,
          CreateGroupLocationRequest(
            name: venue.name,
            latitude: venue.latitude,
            longitude: venue.longitude,
          ),
        );
        locationId = created.fold((_) => null, (id) => id);
        if (locationId == null) {
          _publishFailed(created.fold((f) => f.message, (_) => ''));
          return null;
        }
      }
    }

    final request = GroupEventRequestBuilder.build(
      _draft,
      groupId: widget.profile.id,
      status: status,
      imageUrl: imageUrl,
      locationId: locationId,
    );
    final result =
        existing == null
            ? await repository.createEvent(request)
            : await repository.updateEvent(existing.eventId, request);
    if (!mounted) return null;
    return result.fold((failure) {
      _publishFailed(
        failure.message.isNotEmpty
            ? failure.message
            : status == 'draft'
            ? l10n.group_event_draft_save_error
            : l10n.group_event_publish_error,
      );
      return null;
    }, (event) => event);
  }

  void _publishFailed(String message) {
    if (!mounted) return;
    setState(() => _isPublishing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.isNotEmpty ? message : context.l10n.group_event_publish_error,
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _finish({required bool openEvent}) {
    final event = _published;
    if (event == null) return;
    Navigator.of(
      context,
    ).pop(GroupEventComposerResult(event, openEvent: openEvent));
  }

  /// Like a mail draft: closing keeps the event when the API can hold it.
  Future<void> _onClose() async {
    if (_isPublishing) return;
    if (_published != null) {
      _finish(openEvent: false);
      return;
    }
    if (_canSaveDraft && await _saveDraft()) return;
    if (!mounted) return;
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
    _liveLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final languages = ref.watch(resolvedContentLanguagesProvider);

    final published = _published;

    return PopScope(
      canPop: !_draft.hasContent && published == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onClose();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child:
              published != null
                  ? GroupEventPublishedView(
                    event: published,
                    draft: _draft,
                    groupTitle: widget.profile.title,
                    onViewEvent: () => _finish(openEvent: true),
                    onClose: () => _finish(openEvent: false),
                  )
                  : Column(
                    children: [
                      _buildTopBar(l10n, isDark),
                      _StepProgress(
                        step: _step,
                        total: GroupEventComposerScreen.stepCount,
                        isDark: isDark,
                        label: _stepLabel(l10n),
                      ),
                      Divider(height: 1, thickness: 1, color: dividerColor),
                      GroupPostingToRow(
                        profile: widget.profile,
                        isDark: isDark,
                      ),
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
    final name =
        _isAboutStep
            ? l10n.group_event_step_about
            : _isWhenWhereStep
            ? l10n.group_event_step_when_where
            : _isPracticesStep
            ? l10n.group_event_step_practices
            : _isReviewStep
            ? l10n.group_event_step_review
            : null;
    return name == null ? step : '$step · $name';
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
    if (_isWhenWhereStep) {
      return GroupEventWhenWhereStep(
        draft: _draft,
        profile: widget.profile,
        liveLinkController: _liveLinkController,
        onScheduleChanged:
            (schedule) =>
                setState(() => _draft = _draft.copyWith(schedule: schedule)),
        onFormatChanged:
            (format) =>
                setState(() => _draft = _draft.copyWith(format: format)),
        onVenueChanged:
            (venue) => setState(
              () =>
                  _draft = _draft.copyWith(
                    venue: venue,
                    clearVenue: venue == null,
                  ),
            ),
      );
    }
    if (_isPracticesStep) {
      return GroupEventPracticesStep(
        draft: _draft,
        groupId: widget.profile.id,
        onPracticesChanged:
            (practices) =>
                setState(() => _draft = _draft.copyWith(practices: practices)),
        onVideosChanged:
            (videos) =>
                setState(() => _draft = _draft.copyWith(videos: videos)),
      );
    }
    return GroupEventReviewStep(
      draft: _draft,
      languages: languages,
      onEdit: _onReviewEdit,
    );
  }

  Widget _buildTopBar(AppLocalizations l10n, bool isDark) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            _isEditing
                ? l10n.group_event_edit_draft_title
                : l10n.group_event_new_title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          if (!_isAboutStep)
            Positioned(
              left: 4,
              child: IconButton(
                onPressed: _isPublishing ? null : _back,
                tooltip: l10n.back,
                icon: Icon(AppAssets.arrowLeft, color: secondaryColor),
              ),
            ),
          Positioned(
            right: 4,
            child: IconButton(
              onPressed: _isPublishing ? null : _onClose,
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
    final hint =
        _isReviewStep
            ? (_draft.notificationsEnabled
                ? l10n.group_event_review_notify_hint
                : null)
            : _continueHint(l10n);

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
              if (hint != null) ...[
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: secondaryColor),
                ),
                const SizedBox(height: 8),
              ],
              if (_isPracticesStep &&
                  _draft.practices.isEmpty &&
                  _draft.videos.isEmpty)
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _continue,
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                      side: BorderSide(
                        color: isDark ? AppColors.grey800 : AppColors.grey400,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      l10n.group_event_skip,
                      strutStyle: context.tibetanStrutStyle(16),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _canContinue ? _continue : null,
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
                    child:
                        _isPublishing
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    isDark
                                        ? AppColors.textPrimary
                                        : AppColors.surfaceWhite,
                              ),
                            )
                            : Text(
                              _isReviewStep
                                  ? l10n.group_event_publish
                                  : l10n.group_event_continue,
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
