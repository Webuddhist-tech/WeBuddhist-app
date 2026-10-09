import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';

/// One pickable item in the composer's in-app content sheet and the deep
/// link it posts: the same `/open/...` link the item's share button shortens,
/// kept long here so the feed can route it in-app.
class GroupPostInAppContent {
  final String id;
  final String title;
  final Uri link;

  const GroupPostInAppContent({
    required this.id,
    required this.title,
    required this.link,
  });

  static GroupPostInAppContent event(GroupEvent event) => GroupPostInAppContent(
    id: 'event:${event.id}',
    title: event.title,
    link: DeepLinkUrlBuilder.eventLink(eventId: event.id),
  );

  /// Null when the practice payload lacks its typed body.
  static GroupPostInAppContent? practice(GroupPractice practice) {
    final groupId = practice.groupId?.trim() ?? '';
    switch (practice.type) {
      case GroupPracticeType.series:
        final series = practice.series;
        if (series == null) return null;
        return GroupPostInAppContent(
          id: 'series:${series.id}',
          title: series.title,
          link: DeepLinkUrlBuilder.seriesLink(seriesId: series.id),
        );
      case GroupPracticeType.accumulator:
        final accumulator = practice.accumulator;
        if (accumulator == null) return null;
        return GroupPostInAppContent(
          id: 'accumulator:${accumulator.id}',
          title: accumulator.title,
          link: DeepLinkUrlBuilder.groupAccumulatorLink(
            accumulatorId: accumulator.id,
            groupId: groupId.isNotEmpty ? groupId : accumulator.groupId,
          ),
        );
      case GroupPracticeType.plan:
        final plan = practice.plan;
        if (plan == null) return null;
        return GroupPostInAppContent(
          id: 'plan:${plan.id}',
          title: plan.title,
          link: DeepLinkUrlBuilder.planLink(planId: plan.id),
        );
      case GroupPracticeType.collection:
        final collection = practice.collection;
        if (collection == null) return null;
        return GroupPostInAppContent(
          id: 'collection:${collection.id}',
          title: collection.name,
          link: DeepLinkUrlBuilder.groupRecitationCollectionLink(
            groupId: groupId.isNotEmpty ? groupId : collection.groupId,
            collectionId: collection.id,
          ),
        );
    }
  }

  static GroupPostInAppContent chant(RecitationModel chant) =>
      GroupPostInAppContent(
        id: 'chant:${chant.textId}',
        title: chant.title,
        link: DeepLinkUrlBuilder.readerLink(textId: chant.textId),
      );
}
