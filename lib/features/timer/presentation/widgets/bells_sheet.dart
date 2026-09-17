import 'package:flutter/material.dart';
import 'package:flutter_pecha/shared/widgets/app_toggle_switch.dart';
import 'package:flutter_pecha/features/timer/presentation/widgets/timer_sheet_header.dart';

class BellsSelection {
  const BellsSelection({required this.bellAtStart, required this.bellAtEnd});

  final bool bellAtStart;
  final bool bellAtEnd;
}

/// "Bells" bottom sheet — toggles `bell_at_start` / `bell_at_end` directly.
class BellsSheet extends StatefulWidget {
  const BellsSheet({
    super.key,
    required this.bellAtStart,
    required this.bellAtEnd,
  });

  final bool bellAtStart;
  final bool bellAtEnd;

  static Future<BellsSelection?> show(
    BuildContext context, {
    required bool bellAtStart,
    required bool bellAtEnd,
  }) {
    return showModalBottomSheet<BellsSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => BellsSheet(bellAtStart: bellAtStart, bellAtEnd: bellAtEnd),
    );
  }

  @override
  State<BellsSheet> createState() => _BellsSheetState();
}

class _BellsSheetState extends State<BellsSheet> {
  late bool _bellAtStart = widget.bellAtStart;
  late bool _bellAtEnd = widget.bellAtEnd;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final dividerColor = Theme.of(context).dividerColor;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TimerSheetHeader(
            title: 'Bells',
            onDone:
                () => Navigator.of(context).pop(
                  BellsSelection(
                    bellAtStart: _bellAtStart,
                    bellAtEnd: _bellAtEnd,
                  ),
                ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Bell at start',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                AppToggleSwitch(
                  value: _bellAtStart,
                  onChanged: (value) => setState(() => _bellAtStart = value),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: dividerColor, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Bell at end',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                AppToggleSwitch(
                  value: _bellAtEnd,
                  onChanged: (value) => setState(() => _bellAtEnd = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
