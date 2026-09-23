import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';

/// Drag-handle + title row shared by the New Timer bottom sheets.
///
/// Pass either [onClose] (renders an "X" button, e.g. Duration / Ambient
/// Sound) or [onDone] (renders a "Done" text button) — not both.
class TimerSheetHeader extends StatelessWidget {
  const TimerSheetHeader({
    super.key,
    required this.title,
    this.onClose,
    this.onDone,
  });

  final String title;
  final VoidCallback? onClose;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onDone != null)
                TextButton(
                  onPressed: onDone,
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                )
              else if (onClose != null)
                IconButton(
                  icon: Icon(AppAssets.x, color: textColor),
                  onPressed: onClose,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
