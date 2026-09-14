import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poem.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:share_plus/share_plus.dart';

Future<void> sharePoem(BuildContext context, Poem poem) async {
  final shareMessage = context.l10n.share_poem_message;
  final sharePositionOrigin = getSharePositionOrigin(context: context);
  final longUrl = DeepLinkUrlBuilder.poemLink(poemId: poem.id).toString();
  final shareUrl = await resolveShareUrl(context, longUrl);
  if (!context.mounted) return;

  final title = poem.title.trim();
  final formattedTitle =
      title.isNotEmpty ? context.l10n.share_poem_title(title) : null;
  final message =
      formattedTitle != null
          ? '$shareMessage\n\n$formattedTitle\n\n$shareUrl'
          : '$shareMessage\n\n$shareUrl';
  await SharePlus.instance.share(
    ShareParams(
      text: message,
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}
