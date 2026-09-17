import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/features/timer/domain/entities/ambient_sound.dart';
import 'package:flutter_pecha/features/timer/presentation/providers/timers_providers.dart';
import 'package:flutter_pecha/features/timer/presentation/services/ambient_sound_preview_player.dart';
import 'package:flutter_pecha/features/timer/presentation/widgets/timer_sheet_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AmbientSoundSelection {
  const AmbientSoundSelection({this.id, this.name});

  final String? id;
  final String? name;
}

/// "Ambient sounds" bottom sheet.
///
/// Tapping a row selects it and starts a looping preview (stopping any
/// previous preview). The volume slider only controls preview playback here
/// — it is local UI state and is never sent to the backend.
class AmbientSoundSheet extends ConsumerStatefulWidget {
  const AmbientSoundSheet({super.key, required this.selectedId});

  final String? selectedId;

  static Future<AmbientSoundSelection?> show(
    BuildContext context, {
    required String? selectedId,
  }) {
    return showModalBottomSheet<AmbientSoundSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AmbientSoundSheet(selectedId: selectedId),
    );
  }

  @override
  ConsumerState<AmbientSoundSheet> createState() => _AmbientSoundSheetState();
}

class _AmbientSoundSheetState extends ConsumerState<AmbientSoundSheet> {
  late String? _selectedId = widget.selectedId;
  String? _selectedName;
  double _volume = 1;
  final _player = AmbientSoundPreviewPlayer();

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  void _selectDefault() {
    unawaited(_player.stop());
    setState(() {
      _selectedId = null;
      _selectedName = null;
    });
  }

  void _selectSound(AmbientSound sound) {
    setState(() {
      _selectedId = sound.id;
      _selectedName = sound.name;
    });
    unawaited(_player.play(sound.url, volume: _volume));
  }

  void _onVolumeChanged(double value) {
    setState(() => _volume = value);
    unawaited(_player.setVolume(value));
  }

  void _close() {
    Navigator.of(
      context,
    ).pop(AmbientSoundSelection(id: _selectedId, name: _selectedName));
  }

  @override
  Widget build(BuildContext context) {
    final soundsAsync = ref.watch(ambientSoundsFutureProvider);
    final textColor = Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TimerSheetHeader(title: 'Ambient sounds', onClose: _close),
            Flexible(
              child: soundsAsync.when(
                data:
                    (sounds) => ListView(
                      shrinkWrap: true,
                      children: [
                        _SoundTile(
                          icon: AppAssets.timerAmbientSound,
                          label: 'Default (no sound)',
                          selected: _selectedId == null,
                          onTap: _selectDefault,
                        ),
                        for (final sound in sounds)
                          _SoundTile(
                            icon: AppAssets.timerAmbientSound,
                            label: sound.name,
                            selected: _selectedId == sound.id,
                            onTap: () => _selectSound(sound),
                          ),
                      ],
                    ),
                loading:
                    () => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                error:
                    (error, _) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Failed to load ambient sounds',
                            style: TextStyle(color: textColor),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed:
                                () => ref.invalidate(
                                  ambientSoundsFutureProvider,
                                ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VOLUME',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                  Slider(
                    value: _volume,
                    onChanged: _onVolumeChanged,
                    activeColor: textColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundTile extends StatelessWidget {
  const _SoundTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, size: 20, color: textColor.withValues(alpha: 0.7)),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: textColor,
        ),
      ),
      trailing:
          selected
              ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
              : null,
      onTap: onTap,
    );
  }
}
