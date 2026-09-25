import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/core/utils/url_opener.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_inline_format.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_link_spans.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_message_blocks.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_message_time.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_link_preview_card.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_quoted_message.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_reaction_badges.dart';
import 'package:intl/intl.dart';

/// One message row: self on the right in a warm-tinted bubble, everyone else
/// on the left in a white one with a coloured sender name.
///
/// Every row carries its avatar on the side the bubble is on; only the sender
/// name is limited to the first row of a same-sender run.
class GroupChatMessageBubble extends StatelessWidget {
  const GroupChatMessageBubble({
    super.key,
    required this.message,
    required this.isSelf,
    required this.isRunStart,
    this.selfAvatarUrl,
    this.selfDisplayName,
    this.isHighlighted = false,
    this.isSelected = false,
    this.isParentDeleted = false,
    this.isParentOwn = false,
    this.onShowReactions,
    this.onTapQuote,
  });

  final ChatMessageDTO message;
  final bool isSelf;
  final bool isRunStart;

  /// Own avatar and name from the session, used only for messages this API
  /// has not yet stamped with `sender_name` / `sender_avatar_url`.
  final String? selfAvatarUrl;
  final String? selfDisplayName;

  /// Briefly tinted after a quote jumped to this message.
  final bool isHighlighted;

  /// Held in the selection: the same tint as [isHighlighted], kept until the
  /// selection is cleared.
  final bool isSelected;

  /// The quoted original has been deleted, so the quote is a tombstone. The
  /// thread decides this: it can read `parent.deleted_at` and, until the
  /// server sends that, look the original up among the loaded rows.
  final bool isParentDeleted;

  /// The quoted original is the viewer's own message, so the quote's header
  /// reads "You".
  final bool isParentOwn;

  /// Deleted, per the server's own `deleted_at`. A deleted message can still
  /// arrive carrying its body, so this — never an empty body — is what decides
  /// that the bubble becomes a tombstone.
  bool get isDeleted => message.deletedAt != null;
  final VoidCallback? onShowReactions;

  /// Scrolls to the quoted original when it is still on screen.
  final VoidCallback? onTapQuote;

  static const double _avatarSize = 32;
  static const double _maxWidthFactor = 0.68;

  /// A tombstone is one line — icon, label and the time after it — and that
  /// line does not fit under the ordinary cap once the font scales up. It
  /// gets more room so it stays one line rather than wrapping "deleted" onto
  /// a second.
  static const double _tombstoneMaxWidthFactor = 0.82;

  /// How far the chip rides up over the bubble's bottom edge. Less than the
  /// bubble's 10dp bottom padding, so it overlaps the bubble but stays clear
  /// of the time label.
  static const double _chipOverlap = 8;

  /// Strip kept under the bubble for the reaction chip: what is left of it
  /// below the overlap.
  static const double _chipReserve =
      GroupChatReactionBadges.height - _chipOverlap;

  /// How far the chip is inset from the bubble's inner corner.
  static const double _chipInset = 8;
  static const double _rowPadding = 12;

  /// A deleted message's bubble, background and label alike.
  static const double _tombstoneOpacity = 0.5;
  static const double _avatarGap = 8;

  /// Distance from the row's edge to the bubble's near edge: row padding, the
  /// avatar and the gap after it. The thread aligns the emoji pill to it.
  static const double bubbleEdgeInset = _rowPadding + _avatarSize + _avatarGap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxWidth =
        MediaQuery.sizeOf(context).width *
        (isDeleted ? _tombstoneMaxWidthFactor : _maxWidthFactor);
    // Identity travels with the message, so there is nothing to wait for.
    final displayName =
        (isSelf
            ? (message.senderName ??
                selfDisplayName ??
                chatSenderDisplayName(senderEmail: message.senderEmail))
            : chatSenderDisplayName(
              messageName: message.senderName,
              senderEmail: message.senderEmail,
            )) ??
        context.l10n.group_chat_unknown_sender;
    final avatarUrl =
        message.senderAvatarUrl ?? (isSelf ? selfAvatarUrl : null);
    final avatar = _Avatar(
      avatarUrl: avatarUrl,
      displayName: displayName,
      isDark: isDark,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      // Dark needs both the brighter gold and more of it: a low-alpha tint
      // over a near-black background is almost no shift at all, where the same
      // alpha over the cream light background reads clearly.
      color:
          isHighlighted || isSelected
              ? (isDark
                  ? AppColors.accentGold.withValues(alpha: 0.26)
                  : AppColors.accentGoldDark.withValues(alpha: 0.14))
              : Colors.transparent,
      padding: const EdgeInsets.fromLTRB(_rowPadding, 5, _rowPadding, 5),
      child: Row(
        mainAxisAlignment:
            isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSelf)
            Padding(
              padding: const EdgeInsets.only(right: _avatarGap),
              child: avatar,
            ),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              // The reaction chip is its own element, hung under the bubble
              // rather than drawn inside it — so a Stack, with a strip
              // reserved under the bubble only when there is a chip to fill
              // it. Selection gestures live on the row, in the thread, so a
              // press beside the bubble counts too.
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      bottom:
                          message.reactions.isEmpty || isDeleted
                              ? 0
                              : _chipReserve,
                    ),
                    child:
                        isDeleted
                            // Faded as a whole, so the placeholder reads as
                            // something that is no longer there.
                            ? Opacity(
                              opacity: _tombstoneOpacity,
                              child: _bubble(context, isDark, displayName),
                            )
                            : _bubble(context, isDark, displayName),
                  ),
                  if (message.reactions.isNotEmpty && !isDeleted)
                    Positioned(
                      bottom: 0,
                      // The inner corner: bottom-right under an incoming
                      // bubble, bottom-left under one of the viewer's own.
                      left: isSelf ? _chipInset : null,
                      right: isSelf ? null : _chipInset,
                      child: GroupChatReactionBadges(
                        reactions: message.reactions,
                        onShowAll: onShowReactions ?? () {},
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isSelf)
            Padding(
              padding: const EdgeInsets.only(left: _avatarGap),
              child: avatar,
            ),
        ],
      ),
    );
  }

  Widget _bubble(BuildContext context, bool isDark, String? displayName) {
    // One step apart rather than a hard contrast: the old charcoal outgoing
    // bubble was too heavy, and an identical fill left only the alignment to
    // tell the two apart. Outgoing is a warm tint of the incoming fill in
    // light, and one step lighter than it in dark.
    final background =
        isSelf
            ? (isDark
                ? AppColors.chatOutgoingBubbleDark
                : AppColors.chatOutgoingBubble)
            : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite);
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final previewUrl = firstChatLinkUrl(message.body);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        // Uniform corners and a soft shadow, per the mocks: no tail, the
        // avatar alone says whose bubble it is.
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // IntrinsicWidth so the trailing time can sit against the right edge of
      // the text. An Align or a full-width Row would expand to the maxWidth
      // constraint instead, stretching every reacted bubble across the screen.
      //
      // A reply is the exception, on purpose: the mocks give every quoting
      // bubble the full width, with the quote panel spanning it, however
      // short the answer underneath. Without IntrinsicWidth the stretched
      // column takes the whole width cap.
      child: _maybeIntrinsic(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSelf && isRunStart) ...[
              Text(
                displayName ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                strutStyle: context.tibetanStrutStyle(13, compact: true),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: chatSenderColor(
                    seed: chatSenderSeed(
                      senderId: message.senderId,
                      senderEmail: message.senderEmail,
                      name: message.senderName,
                    ),
                    onDark: isDark,
                  ),
                ),
              ),
              const SizedBox(height: 2),
            ],
            if (isDeleted)
              _tombstone(context, isDark)
            else ...[
              if (message.parent != null)
                GroupChatQuotedMessage(
                  parent: message.parent!,
                  onOutgoing: isSelf,
                  isOwnOriginal: isParentOwn,
                  isDeleted:
                      isParentDeleted || message.parent!.deletedAt != null,
                  onTap: onTapQuote,
                ),
              _body(context, textColor, isDark),
              if (previewUrl != null)
                GroupChatLinkPreviewCard(url: previewUrl, onOpen: _openUrl),
            ],
            // A tombstone carries its time on the same line (see
            // `_tombstone`), so the bubble stays one line tall.
            if (!isDeleted) ...[
              const SizedBox(height: 2),
              Text(
                timeLabel(context, message),
                textAlign: TextAlign.right,
                style: _timeStyle(isDark),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _maybeIntrinsic(Widget column) {
    final isReply = message.parent != null && !isDeleted;
    return isReply ? column : IntrinsicWidth(child: column);
  }

  TextStyle _timeStyle(bool isDark) {
    return TextStyle(
      fontSize: 11,
      color: isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
    );
  }

  /// Stands in for a deleted message.
  ///
  /// The quote, link preview and reaction badges all go with the body: none of
  /// them describes anything that still exists. One label for everyone, in the
  /// ordinary text colour — the bubble's side already says whose message it
  /// was. The caller fades the whole bubble (see [_tombstoneOpacity]).
  ///
  /// One line: the time sits after the label rather than under it, its
  /// baseline a touch lower, so a deleted message is shorter than a live one.
  Widget _tombstone(BuildContext context, bool isDark) {
    final color = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            // The icon stays centred on the label even if a very large font
            // scale still forces a wrap.
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(AppAssets.prohibit, size: 15, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  context.l10n.group_chat_message_deleted_by_sender,
                  strutStyle: context.tibetanStrutStyle(14),
                  style: TextStyle(fontSize: 14, color: color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(timeLabel(context, message), style: _timeStyle(isDark)),
      ],
    );
  }

  /// A message with no markers stays a single [Text]; only one that needs
  /// block layout pays for it.
  Widget _body(BuildContext context, Color textColor, bool isDark) {
    if (!chatBodyNeedsBlocks(message.body)) {
      return ChatFormattedText(
        body: message.body,
        textColor: textColor,
        isDark: isDark,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final block in parseChatMessageBlocks(message.body))
          _block(block, textColor, isDark),
      ],
    );
  }

  Widget _block(ChatTextBlock block, Color textColor, bool isDark) {
    final text = ChatFormattedText(
      body: block.text,
      textColor: textColor,
      isDark: isDark,
    );

    switch (block.kind) {
      case ChatBlockKind.paragraph:
        return text;

      case ChatBlockKind.bullet:
      case ChatBlockKind.numbered:
        // A fixed gutter, so a marked line that wraps hangs under its own text
        // rather than under the marker.
        return Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: block.kind == ChatBlockKind.bullet ? 16 : 22,
                child: Text(
                  block.marker ?? '\u2022',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    color: textColor,
                  ),
                ),
              ),
              Flexible(child: text),
            ],
          ),
        );

      case ChatBlockKind.quote:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Container(
            padding: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color:
                      isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textSecondary,
                  width: 3,
                ),
              ),
            ),
            child: text,
          ),
        );

      case ChatBlockKind.code:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? AppColors.surfaceWhite.withValues(alpha: 0.06)
                      : AppColors.textPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            // Literal on purpose: a fenced block is shown exactly as typed.
            child: Text(
              block.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: textColor,
                fontFamily: 'monospace',
                fontFamilyFallback: const ['Courier New', 'Courier'],
              ),
            ),
          ),
        );
    }
  }

  /// The time as the bubble paints it. Public so a multi-message copy can
  /// prefix each line with the same value the reader sees.
  static String timeLabel(BuildContext context, ChatMessageDTO message) {
    final formatted = DateFormat.jm(
      intlFormatLocaleOf(context),
    ).format(message.createdAtLocal);
    return context.isTibetanLocale ? toTibetanDigits(formatted) : formatted;
  }

  static Future<void> _openUrl(String url) => openUrl(url);
}

/// Message body with tappable links and inline formatting.
///
/// Stateful so the [TapGestureRecognizer]s it creates are disposed with the
/// row rather than leaking on every rebuild.
class ChatFormattedText extends StatefulWidget {
  const ChatFormattedText({
    super.key,
    required this.body,
    required this.textColor,
    required this.isDark,
  });

  final String body;
  final Color textColor;
  final bool isDark;

  @override
  State<ChatFormattedText> createState() => _ChatFormattedTextState();
}

class _ChatFormattedTextState extends State<ChatFormattedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: 15,
      height: 1.35,
      color: widget.textColor,
    );
    final links = findChatLinks(widget.body);
    // Nothing to mark up: the cheapest path stays a plain Text.
    if (links.isEmpty && !chatTextHasInlineMarkers(widget.body)) {
      return Text(
        widget.body,
        strutStyle: context.tibetanStrutStyle(15),
        style: baseStyle,
      );
    }

    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    // Links are carved out first and only the text *between* them is scanned
    // for inline markers. The other way round silently rewrites URLs: the
    // underscores in `.../Foo_(bar)_baz` parse as an italic run, so they are
    // eaten out of the text and the only thing left to link is the truncated
    // prefix before the first one.
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final link in links) {
      if (link.start > cursor) {
        _appendFormatted(
          spans,
          widget.body.substring(cursor, link.start),
          baseStyle,
        );
      }
      _appendLink(spans, link, baseStyle);
      cursor = link.end;
    }
    if (cursor < widget.body.length) {
      _appendFormatted(spans, widget.body.substring(cursor), baseStyle);
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      strutStyle: context.tibetanStrutStyle(15),
    );
  }

  /// Styles one stretch of text that holds no link.
  void _appendFormatted(
    List<InlineSpan> spans,
    String text,
    TextStyle baseStyle,
  ) {
    for (final run in parseChatInlineRuns(text)) {
      spans.add(TextSpan(text: run.text, style: _runStyle(run, baseStyle)));
    }
  }

  TextStyle _runStyle(ChatInlineRun run, TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontWeight: run.bold ? FontWeight.w700 : null,
      fontStyle: run.italic ? FontStyle.italic : null,
      decoration: run.strike ? TextDecoration.lineThrough : null,
      fontFamily: run.code ? 'monospace' : null,
      fontFamilyFallback: run.code ? const ['Courier New', 'Courier'] : null,
      backgroundColor:
          run.code
              ? (widget.isDark
                  ? AppColors.surfaceWhite.withValues(alpha: 0.08)
                  : AppColors.textPrimary.withValues(alpha: 0.06))
              : null,
    );
  }

  void _appendLink(
    List<InlineSpan> spans,
    ChatLinkMatch link,
    TextStyle baseStyle,
  ) {
    final linkColor = widget.isDark ? AppColors.brandblue : AppColors.blue;
    final recognizer =
        TapGestureRecognizer()
          ..onTap = () => GroupChatMessageBubble._openUrl(link.url);
    _recognizers.add(recognizer);
    spans.add(
      TextSpan(
        text: link.text,
        recognizer: recognizer,
        style: baseStyle.copyWith(
          color: linkColor,
          decoration: TextDecoration.underline,
          decorationColor: linkColor,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.avatarUrl,
    required this.displayName,
    required this.isDark,
  });

  final String? avatarUrl;

  /// Identity travels with the message, so this is only null when the API sent
  /// no name and there is no email to fall back on.
  final String? displayName;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    final hasUrl = url != null && url.isNotEmpty;

    return ClipOval(
      child: SizedBox(
        width: GroupChatMessageBubble._avatarSize,
        height: GroupChatMessageBubble._avatarSize,
        child:
            hasUrl
                ? CachedNetworkImageWidget(
                  key: ValueKey(url),
                  imageUrl: url,
                  width: GroupChatMessageBubble._avatarSize,
                  height: GroupChatMessageBubble._avatarSize,
                  fit: BoxFit.cover,
                  errorWidget: _initials(),
                )
                : _initials(),
      ),
    );
  }

  Widget _initials() {
    final name = displayName;
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child:
          name == null
              ? const SizedBox.shrink()
              : Center(
                child: Text(
                  chatSenderInitials(name),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.grey500 : AppColors.grey600,
                  ),
                ),
              ),
    );
  }
}
