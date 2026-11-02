import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitation_live_settings_remote_datasource.dart';
import 'package:flutter_pecha/features/recitation/data/models/edition_live_settings.dart';
import 'package:flutter_pecha/features/recitation/data/repositories/recitation_live_settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recitationLiveSettingsRepositoryProvider =
    Provider<RecitationLiveSettingsRepository>(
      (ref) => RecitationLiveSettingsRepository(
        datasource: RecitationLiveSettingsRemoteDatasource(
          dio: ref.watch(dioProvider),
        ),
      ),
    );

/// The parts of an edition a live room reads more than once. A failed
/// fetch counts as none: the round then shows without its total.
final editionReturnJumpsProvider = FutureProvider.autoDispose
    .family<List<ReturnJump>, String>((ref, editionId) async {
      final result = await ref
          .watch(recitationLiveSettingsRepositoryProvider)
          .getEditionLiveSettings(editionId);
      return result.fold((_) => const [], (settings) => settings.returnJumps);
    });
