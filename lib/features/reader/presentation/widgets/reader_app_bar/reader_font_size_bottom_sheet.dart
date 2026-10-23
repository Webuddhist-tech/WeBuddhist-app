import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_text_size_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_text_size.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet for adjusting font size with increase/decrease buttons.
/// They move the original and translation lines' size steps together.
class ReaderFontSizeBottomSheet extends ConsumerWidget {
  const ReaderFontSizeBottomSheet({super.key});

  /// The smaller A is off when no line can get smaller.
  static bool canDecrease(ReaderTextSize size) =>
      size.originalStep > ReaderTextSize.minStep ||
      size.translationStep > ReaderTextSize.minStep;

  /// The larger A is off when no line can get larger.
  static bool canIncrease(ReaderTextSize size) =>
      size.originalStep < ReaderTextSize.maxStep ||
      size.translationStep < ReaderTextSize.maxStep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textSize = ref.watch(readerTextSizeProvider);
    final canDecrease = ReaderFontSizeBottomSheet.canDecrease(textSize);
    final canIncrease = ReaderFontSizeBottomSheet.canIncrease(textSize);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ReaderPanelConstants.dragHandleColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Font size buttons
            Row(
              children: [
                // Decrease font size button (small A)
                Expanded(
                  child: _FontSizeButton(
                    label: 'A',
                    fontSize: 18,
                    isEnabled: canDecrease,
                    onTap:
                        canDecrease
                            ? () => ref
                                .read(readerTextSizeProvider.notifier)
                                .stepBoth(-1)
                            : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Increase font size button (large A)
                Expanded(
                  child: _FontSizeButton(
                    label: 'A',
                    fontSize: 28,
                    isEnabled: canIncrease,
                    onTap:
                        canIncrease
                            ? () => ref
                                .read(readerTextSizeProvider.notifier)
                                .stepBoth(1)
                            : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _FontSizeButton extends StatelessWidget {
  final String label;
  final double fontSize;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _FontSizeButton({
    required this.label,
    required this.fontSize,
    required this.isEnabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color:
                isEnabled
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color:
                  isEnabled
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the font size bottom sheet
void showFontSizeBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => const ReaderFontSizeBottomSheet(),
  );
}
