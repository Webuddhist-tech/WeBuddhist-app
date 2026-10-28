import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_settings_scope.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_transliteration.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/segment_type_style.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_verse_frame.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/segment_number.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_html_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SegmentItem extends ConsumerWidget {
  final Segment segment;
  final int depth;
  final String language;

  /// The reader this line is shown in; decides which script pick applies.
  final ReaderSettingsScope scope;
  final bool isSelected;
  final bool isGreyedOut;

  /// The line the puja leader is on right now.
  final bool isLive;

  /// A live room is being followed: verses other than [isLive]'s are muted.
  final bool followingLive;
  final VoidCallback? onTap;

  const SegmentItem({
    super.key,
    required this.segment,
    required this.depth,
    required this.language,
    required this.scope,
    this.isSelected = false,
    this.isGreyedOut = false,
    this.isLive = false,
    this.followingLive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ReaderStyle.of(context, ref);
    final primary = primarySegmentHtml(
      ref,
      content: segment.content,
      language: language,
      scope: scope,
    );
    final typeStyle = SegmentTypeStyle.of(segment.type);
    final script = ReaderScript.of(
      primary.html,
      language: primary.fontLanguage,
    );
    final metrics = style.type.line(ReaderTextRole.originalAlone, script);
    final gaps = style.type.gaps(style.type.settings.originalStep);
    final colors = readerVerseColors(
      style.palette,
      isLive: isLive,
      followingLive: followingLive,
      translationUnderOriginal: false,
    );

    return ReaderVerseFrame(
      key: Key(segment.segmentId),
      style: style,
      verseGap: gaps.verse,
      isLive: isLive,
      isGreyedOut: isGreyedOut,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentHtmlWidget(
            htmlContent: primary.html,
            segmentIndex: segment.segmentNumber,
            fontSize: metrics.fontSize,
            lineHeight: metrics.height,
            language: primary.fontLanguage,
            isSelected: isSelected,
            textColor: colors.original,
            fontStyle: typeStyle.fontStyle ?? metrics.fontStyle,
            fontWeight: typeStyle.fontWeight ?? metrics.fontWeight,
            fontFamily: style.type.family(primary.fontLanguage, script: script),
          ),
          Padding(
            padding: EdgeInsets.only(top: gaps.inPair),
            child: SegmentNumber(
              label: segment.displayNumber,
              language: language,
            ),
          ),
        ],
      ),
    );
  }
}
