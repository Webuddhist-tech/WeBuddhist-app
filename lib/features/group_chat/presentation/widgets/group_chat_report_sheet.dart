import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_report_reason.dart';

/// What the member chose to report, once the sheet is done.
class ChatReportSubmission {
  const ChatReportSubmission({required this.reason, this.note});

  final ChatReportReason reason;

  /// Only ever set for the reason that asks for one.
  final String? note;
}

/// The label shown for [reason].
String chatReportReasonLabel(BuildContext context, ChatReportReason reason) {
  final l10n = context.l10n;
  switch (reason) {
    case ChatReportReason.harassment:
      return l10n.group_chat_report_reason_harassment;
    case ChatReportReason.hateSpeech:
      return l10n.group_chat_report_reason_hate;
    case ChatReportReason.sexualContent:
      return l10n.group_chat_report_reason_sexual;
    case ChatReportReason.spam:
      return l10n.group_chat_report_reason_spam;
    case ChatReportReason.offTopic:
      return l10n.group_chat_report_reason_off_topic;
    case ChatReportReason.somethingElse:
      return l10n.group_chat_report_reason_other;
  }
}

/// Asks why a message is being reported.
///
/// Resolves null when dismissed without submitting.
Future<ChatReportSubmission?> showChatReportSheet(BuildContext context) {
  return showModalBottomSheet<ChatReportSubmission>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ReportSheet(),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet();

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final TextEditingController _note = TextEditingController();

  final FocusNode _noteFocus = FocusNode();

  /// Anchors the note field so it can be scrolled to when it appears.
  final GlobalKey _noteKey = GlobalKey();

  ChatReportReason? _reason;

  @override
  void dispose() {
    _noteFocus.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Whether the chosen reason asks for a note.
  bool get _needsNote {
    final reason = _reason;
    return reason != null && chatReportNeedsNote(reason);
  }

  bool get _canSubmit => canSubmitChatReport(reason: _reason, note: _note.text);

  void _onReasonPicked(ChatReportReason reason) {
    final wasNeeded = _needsNote;
    setState(() => _reason = reason);
    if (!chatReportNeedsNote(reason) || wasNeeded) return;

    // The field appears below the list, so it is off screen on a short sheet
    // and behind the keyboard on a tall one. Bring it into view once it has
    // been laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _noteFocus.requestFocus();
      final target = _noteKey.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: 1,
        );
      }
    });
  }

  void _onSubmit() {
    final reason = _reason;
    if (reason == null || !_canSubmit) return;

    Navigator.of(context).pop(
      ChatReportSubmission(
        reason: reason,
        // Only the reason that asked for one carries it; the rest send
        // nothing rather than an empty string.
        note: chatReportNeedsNote(reason) ? _note.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface =
        isDark
            ? AppColors.surfaceVariantDark
            : AppColors.scaffoldBackgroundLight;

    return Padding(
      // Lifts the sheet clear of the keyboard on the note step.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Grabber(isDark: isDark),
              _Header(
                isDark: isDark,
                onClose: () => Navigator.of(context).maybePop(),
              ),
              Flexible(child: _body(context, isDark)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _SubmitButton(
                  isEnabled: _canSubmit,
                  isDark: isDark,
                  onPressed: _onSubmit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, bool isDark) {
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final subtitleColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.group_chat_report_title,
                  strutStyle: context.tibetanStrutStyle(16, compact: true),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.group_chat_report_privacy,
                  strutStyle: context.tibetanStrutStyle(13),
                  style: TextStyle(fontSize: 13, color: subtitleColor),
                ),
              ],
            ),
          ),
          for (final reason in kChatReportReasons)
            _ReasonRow(
              label: chatReportReasonLabel(context, reason),
              isSelected: _reason == reason,
              isDark: isDark,
              onTap: () => _onReasonPicked(reason),
            ),
          // Inline rather than a second screen: the reason stays visible and
          // the note is written in the same breath as choosing it.
          if (_needsNote) _noteField(context, isDark),
        ],
      ),
    );
  }

  Widget _noteField(BuildContext context, bool isDark) {
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final counter = '${_note.text.characters.length} / $kChatReportNoteLimit';

    return Column(
      key: _noteKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(
          height: 1,
          color: isDark ? AppColors.grey800 : AppColors.grey100,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            context.l10n.group_chat_report_note_title,
            strutStyle: context.tibetanStrutStyle(15, compact: true),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: TextField(
            controller: _note,
            focusNode: _noteFocus,
            maxLines: 4,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            // Capped by the field itself, so the counter can never disagree
            // with what gets sent.
            inputFormatters: [
              LengthLimitingTextInputFormatter(kChatReportNoteLimit),
            ],
            onChanged: (_) => setState(() {}),
            strutStyle: context.tibetanStrutStyle(15),
            style: TextStyle(fontSize: 15, color: titleColor),
            decoration: InputDecoration(
              hintText: context.l10n.group_chat_report_note_hint,
              filled: true,
              fillColor: isDark ? AppColors.grey800 : AppColors.surfaceWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              context.isTibetanLocale ? toTibetanDigits(counter) : counter,
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: isDark ? AppColors.grey600 : AppColors.grey900,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isDark, required this.onClose});

  final bool isDark;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            context.l10n.group_chat_report,
            strutStyle: context.tibetanStrutStyle(17, compact: true),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: Icon(
            AppAssets.x,
            size: 20,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final accent = isDark ? AppColors.accentGold : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Divider(
            height: 1,
            color: isDark ? AppColors.grey800 : AppColors.grey100,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    strutStyle: context.tibetanStrutStyle(15),
                    style: TextStyle(fontSize: 15, color: textColor),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isSelected
                              ? accent
                              : (isDark
                                  ? AppColors.grey600
                                  : AppColors.grey400),
                      width: isSelected ? 6 : 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.isEnabled,
    required this.isDark,
    required this.onPressed,
  });

  final bool isEnabled;
  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final background =
        isEnabled
            ? (isDark ? AppColors.accentGold : AppColors.textPrimary)
            : (isDark ? AppColors.grey800 : AppColors.grey100);
    final foreground =
        isEnabled
            ? (isDark ? AppColors.grey900 : AppColors.surfaceWhite)
            : (isDark ? AppColors.grey600 : AppColors.grey500);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          disabledBackgroundColor: background,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          context.l10n.group_chat_report_submit,
          strutStyle: context.tibetanStrutStyle(16, compact: true),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
