import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/analytics/share_analytics.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the share sheet for [post]; does nothing once [context] is unmounted.
Future<void> shareConnectPost(
  BuildContext context,
  WidgetRef ref,
  ConnectPost post,
) async {
  final caption = post.caption.trim();
  final longUrl =
      post.groupId.isNotEmpty
          ? DeepLinkUrlBuilder.groupLink(groupId: post.groupId).toString()
          : '';
  final shareUrl =
      longUrl.isNotEmpty ? await resolveShareUrlRef(ref, longUrl) : '';
  if (!context.mounted) return;

  final message =
      caption.isNotEmpty && shareUrl.isNotEmpty
          ? '$caption\n\n$shareUrl'
          : caption.isNotEmpty
          ? caption
          : shareUrl;
  if (message.isEmpty) return;
  final shareAnalytics = ref.read(shareAnalyticsProvider);
  final result = await SharePlus.instance.share(ShareParams(text: message));
  if (ShareAnalytics.wasUsed(result)) {
    shareAnalytics.contentShared(
      surface: ShareSurface.post,
      targetId: post.id,
      format: 'text',
      groupId: post.groupId,
    );
  }
}
