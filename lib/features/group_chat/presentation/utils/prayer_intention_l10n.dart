import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/tolgee/tolgee_bridge.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_intention_dto.dart';

/// Intention copy comes from the backend in English. Its Tolgee keys are
/// derived from the intention's slug, so a label edit in the backend never
/// orphans a translation and a new intention only needs its two keys created
/// (`dart run tool/tolgee_sync.dart intentions`, weekly in CI). The backend
/// text is the fallback: no payload loaded yet, an empty translation, or a
/// slug the key rule cannot take.
const String prayerIntentionKeyPrefix = 'prayer_intention_';

/// Slugs are lowercase ASCII words; anything else gets no key.
final RegExp _slugPattern = RegExp(r'^[a-z0-9_-]+$');

/// Tolgee key of an intention's label, or null for an unusable slug.
String? prayerIntentionLabelKey(String slug) => _keyFor(slug, 'label');

/// Tolgee key of an intention's description, or null for an unusable slug.
String? prayerIntentionDescriptionKey(String slug) =>
    _keyFor(slug, 'description');

String? _keyFor(String slug, String part) =>
    _slugPattern.hasMatch(slug)
        ? '$prayerIntentionKeyPrefix${slug}_$part'
        : null;

extension PrayerIntentionL10n on ChatPrayerIntentionDTO {
  String localizedLabel(BuildContext context) =>
      _translate(context, prayerIntentionLabelKey(slug), label);

  String localizedDescription(BuildContext context) =>
      _translate(context, prayerIntentionDescriptionKey(slug), description);
}

String _translate(BuildContext context, String? key, String fallback) {
  if (key == null) return fallback;
  return TolgeeBridge.get(context.l10n.localeName, key, () => fallback);
}
