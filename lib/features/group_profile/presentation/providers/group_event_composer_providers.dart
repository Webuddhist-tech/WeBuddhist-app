import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/env.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_event_composer_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/place_search_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/repositories/group_event_composer_repository_impl.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_cms_item.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_event_composer_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Null when no LocationIQ token is configured; the venue sheet then offers
/// the map pin only.
final placeSearchDatasourceProvider = Provider<PlaceSearchRemoteDatasource?>((
  ref,
) {
  final token = Env.locationIqToken;
  if (token == null) return null;
  // A plain client: the app's Dio adds auth headers meant for our API.
  return PlaceSearchRemoteDatasource(
    dio: Dio(BaseOptions(receiveTimeout: const Duration(seconds: 10))),
    token: token,
  );
});

/// Everything the group's practices feed lists, across every page, so the
/// picker can filter by kind and search locally.
final groupEventPracticeOptionsProvider = FutureProvider.autoDispose
    .family<List<GroupPractice>, String>((ref, groupId) async {
      final repository = ref.watch(groupProfileRepositoryProvider);
      final language = ref.watch(contentLanguageProvider);
      const limit = 50;
      const maxItems = 300;
      final all = <GroupPractice>[];
      var skip = 0;
      while (all.length < maxItems) {
        final result = await repository.getGroupPractices(
          groupId,
          language: language,
          skip: skip,
          limit: limit,
        );
        final page = result.fold((failure) => throw failure, (page) => page);
        all.addAll(page.practices);
        if (!page.hasMore || page.practices.isEmpty) break;
        skip += page.practices.length;
      }
      return all;
    });

final groupEventComposerRemoteDatasourceProvider =
    Provider<GroupEventComposerRemoteDatasource>((ref) {
      return GroupEventComposerRemoteDatasource(dio: ref.watch(dioProvider));
    });

final groupEventComposerRepositoryProvider =
    Provider<GroupEventComposerRepositoryInterface>((ref) {
      return GroupEventComposerRepositoryImpl(
        remote: ref.watch(groupEventComposerRemoteDatasourceProvider),
      );
    });

final groupEventIntentionsProvider =
    FutureProvider.autoDispose<List<GroupEventIntention>>((ref) async {
      final result =
          await ref.watch(groupEventComposerRepositoryProvider).getIntentions();
      return result.fold(
        (failure) => throw failure,
        (intentions) => intentions,
      );
    });

/// The CMS view of a group's events, drafts included; for people who may post.
final groupCmsEventsProvider = FutureProvider.autoDispose
    .family<List<GroupEventCmsItem>, String>((ref, groupId) async {
      final result = await ref
          .watch(groupEventComposerRepositoryProvider)
          .getCmsEvents(groupId);
      return result.fold((failure) => throw failure, (items) => items);
    });
