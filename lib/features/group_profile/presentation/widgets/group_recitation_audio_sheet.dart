import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';

/// Lists the recordings for one chant. Returns the track the user picks,
/// or null when they dismiss the sheet.
Future<CollectionAudioTrack?> showGroupRecitationAudioSheet(
  BuildContext context, {
  required List<CollectionAudioTrack> tracks,
  String? selectedTrackId,
}) {
  return showModalBottomSheet<CollectionAudioTrack>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (context) => _GroupRecitationAudioSheet(
          tracks: tracks,
          selectedTrackId: selectedTrackId,
        ),
  );
}

class _GroupRecitationAudioSheet extends StatelessWidget {
  const _GroupRecitationAudioSheet({
    required this.tracks,
    this.selectedTrackId,
  });

  final List<CollectionAudioTrack> tracks;
  final String? selectedTrackId;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.6;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
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
            Row(
              children: [
                IconButton(
                  icon: const Icon(AppAssets.arrowLeft),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    context.l10n.collection_audio_versions,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  final isSelected = track.id == selectedTrackId;
                  return ListTile(
                    title: Text(
                      track.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing:
                        isSelected
                            ? Icon(
                              AppAssets.check,
                              size: 18,
                              color: Theme.of(context).colorScheme.onSurface,
                            )
                            : null,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop(track);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Idle play control for a group-collection chant. Tapping it starts the
/// chant's current recording, which is the first one until the reader menu
/// picks another.
class CollectionAudioPlayButton extends StatelessWidget {
  const CollectionAudioPlayButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Material(
      color: bgColor.withAlpha(235),
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black38,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withAlpha(100), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Icon(AppAssets.play, size: 26, color: color),
        ),
      ),
    );
  }
}
