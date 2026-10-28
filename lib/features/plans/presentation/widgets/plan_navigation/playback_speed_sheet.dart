import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_audio_progress.dart';

/// Lists playback speeds and returns the one the user picks.
Future<double?> showPlaybackSpeedSheet(
  BuildContext context, {
  required double selected,
}) {
  return showModalBottomSheet<double>(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _PlaybackSpeedSheet(selected: selected),
  );
}

class _PlaybackSpeedSheet extends StatelessWidget {
  const _PlaybackSpeedSheet({required this.selected});

  final double selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 8, 48, 12),
              child: Text(
                context.l10n.playback_speed,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final speed in planPlaybackSpeeds)
              ListTile(
                title: Text(_speedLabel(context, speed)),
                trailing:
                    (speed - selected).abs() < 0.001
                        ? Icon(
                          AppAssets.check,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface,
                        )
                        : null,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop(speed);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

String _speedLabel(BuildContext context, double speed) {
  final label = formatPlaybackSpeed(speed);
  return context.isTibetanLocale ? toTibetanDigits(label) : label;
}
