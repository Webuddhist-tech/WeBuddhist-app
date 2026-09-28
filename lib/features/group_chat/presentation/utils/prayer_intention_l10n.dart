import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/tolgee/tolgee_bridge.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_intention_dto.dart';

/// Intention copy comes from the backend in English. Each string doubles as
/// its own Tolgee key, with the backend text as the default when Tolgee has
/// no translation for it (MVP arrangement).
extension PrayerIntentionL10n on ChatPrayerIntentionDTO {
  String localizedLabel(BuildContext context) => _translate(context, label);

  String localizedDescription(BuildContext context) =>
      _translate(context, description);
}

String _translate(BuildContext context, String text) {
  if (text.isEmpty) return text;
  return TolgeeBridge.get(context.l10n.localeName, text, () => text);
}
