import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_feed_item.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_analytics.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_event_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_practice_card.dart';

/// One unified-feed row: a post, event or practice card.
class ConnectFeedItemView extends StatelessWidget {
  const ConnectFeedItemView({
    super.key,
    required this.item,
    required this.includeUnfollowed,
    required this.placement,
  });

  final ConnectFeedItem item;

  /// Which feed the item came from, so likes update that list.
  final bool includeUnfollowed;

  /// Where this row sits, for tracking a post card.
  final ConnectPostPlacement placement;

  @override
  Widget build(BuildContext context) {
    final post = item.post;
    if (item.type == ConnectFeedItemType.post && post != null) {
      return ConnectPostCard(
        post: post,
        includeUnfollowed: includeUnfollowed,
        placement: placement,
      );
    }

    final event = item.event;
    if (item.type == ConnectFeedItemType.event && event != null) {
      return ConnectEventCard(event: event);
    }

    final practice = item.practice;
    if (item.type == ConnectFeedItemType.practice && practice != null) {
      return ConnectPracticeCard(practice: practice);
    }

    return const SizedBox.shrink();
  }
}
