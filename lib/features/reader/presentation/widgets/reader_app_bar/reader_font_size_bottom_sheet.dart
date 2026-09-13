import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_constants.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/font_size_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet for adjusting font size with increase/decrease buttons
class ReaderFontSizeBottomSheet extends ConsumerWidget {
  const ReaderFontSizeBottomSheet({super.key});

  // Font size steps: 12, 14, 18, 22, 28, 36, 44
  // Default is step 3 (index 2) = 18
  static const List<double> fontSizeSteps = [12, 14, 18, 22, 28, 36, 44];
  static const int defaultStepIndex = 2; // Step 3 = 18
  static const double defaultFontSize = 18.0;

  int _getCurrentStepIndex(double currentFontSize) {
    for (int i = 0; i < fontSizeSteps.length; i++) {
      if ((currentFontSize - fontSizeSteps[i]).abs() < 0.5) {
        return i;
      }
    }
    // Find closest step
    int closestIndex = defaultStepIndex;
    double minDiff = double.infinity;
    for (int i = 0; i < fontSizeSteps.length; i++) {
      final diff = (currentFontSize - fontSizeSteps[i]).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestIndex = i;
      }
    }
    return closestIndex;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);
    final currentStepIndex = _getCurrentStepIndex(fontSize);

    final canDecrease = currentStepIndex > 0;
    final canIncrease = currentStepIndex < fontSizeSteps.length - 1;

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
                            ? () {
                              final newFontSize =
                                  fontSizeSteps[currentStepIndex - 1];
                              ref
                                  .read(fontSizeProvider.notifier)
                                  .setFontSize(newFontSize);
                            }
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
                            ? () {
                              final newFontSize =
                                  fontSizeSteps[currentStepIndex + 1];
                              ref
                                  .read(fontSizeProvider.notifier)
                                  .setFontSize(newFontSize);
                            }
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
