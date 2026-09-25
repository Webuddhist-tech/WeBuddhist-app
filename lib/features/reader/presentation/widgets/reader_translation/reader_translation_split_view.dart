import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_translation/reader_translation_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReaderTranslationSplitView extends ConsumerWidget {
  final Widget mainContent;
  final ReaderParams params;

  const ReaderTranslationSplitView({
    super.key,
    required this.mainContent,
    required this.params,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readerNotifierProvider(params));

    final isTranslationOpen = state.isTranslationOpen;
    final splitRatio = state.splitRatio;
    final textLanguage = state.textDetail?.language ?? 'en';

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final panelHeight =
            isTranslationOpen ? availableHeight * (1 - splitRatio) : 0.0;
        final mainHeight = availableHeight - panelHeight;

        return Column(
          children: [
            SizedBox(height: mainHeight, child: mainContent),
            if (isTranslationOpen && state.translationSegmentId != null)
              SizedBox(
                height: panelHeight,
                child: ReaderTranslationPanel(
                  segmentId: state.translationSegmentId!,
                  rootText: state.showsRootText,
                  textLanguage: textLanguage,
                  params: params,
                  availableHeight: availableHeight,
                ),
              ),
          ],
        );
      },
    );
  }
}
