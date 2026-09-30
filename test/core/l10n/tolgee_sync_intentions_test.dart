import 'package:flutter_pecha/features/group_chat/presentation/utils/prayer_intention_l10n.dart'
    show
        prayerIntentionDescriptionKey,
        prayerIntentionKeyPrefix,
        prayerIntentionLabelKey;
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/tolgee_sync.dart'
    show
        PrayerIntention,
        SyncException,
        intentionDescriptionKey,
        intentionKeyPrefix,
        intentionKeysToCreate,
        intentionLabelKey,
        parseIntentions,
        staleIntentionKeys;

const _peace = PrayerIntention(
  slug: 'peace',
  label: 'Peace',
  description: 'Calm, clarity, a peaceful passing',
);
const _healing = PrayerIntention(
  slug: 'healing',
  label: 'Healing',
  description: 'Recovery from illness',
);

void main() {
  test('the sync tool builds the same keys the app looks up', () {
    expect(intentionKeyPrefix, prayerIntentionKeyPrefix);
    expect(intentionLabelKey('peace'), prayerIntentionLabelKey('peace'));
    expect(
      intentionDescriptionKey('peace'),
      prayerIntentionDescriptionKey('peace'),
    );
  });

  test('parseIntentions reads the wrapped list the API returns', () {
    final intentions = parseIntentions({
      'intentions': [
        {
          'slug': 'peace',
          'label': 'Peace',
          'color': '#FFFFFF',
          'description': ' Calm ',
          'display_order': 0,
        },
        {'slug': 'healing', 'label': 'Healing'},
      ],
    });
    expect(intentions.map((i) => i.slug), ['peace', 'healing']);
    expect(intentions.first.description, 'Calm');
    expect(intentions.last.description, '');
  });

  test('parseIntentions also accepts a bare list', () {
    final intentions = parseIntentions([
      {'slug': 'love', 'label': 'Love', 'description': 'Family'},
    ]);
    expect(intentions.single.label, 'Love');
  });

  test('parseIntentions rejects other shapes', () {
    expect(() => parseIntentions('nope'), throwsA(isA<SyncException>()));
    expect(
      () => parseIntentions({'intentions': 'nope'}),
      throwsA(isA<SyncException>()),
    );
    expect(
      () => parseIntentions({
        'intentions': [
          {'label': 'No slug'},
        ],
      }),
      throwsA(isA<SyncException>()),
    );
  });

  test('a new intention gets both keys with the backend English', () {
    final missing = intentionKeysToCreate(<String>{}, [_peace]);
    expect(missing, {
      'prayer_intention_peace_label': 'Peace',
      'prayer_intention_peace_description': 'Calm, clarity, a peaceful passing',
    });
  });

  test('keys Tolgee already has are left alone', () {
    final missing = intentionKeysToCreate(
      {'prayer_intention_peace_label', 'prayer_intention_healing_description'},
      [_peace, _healing],
    );
    expect(missing.keys, [
      'prayer_intention_peace_description',
      'prayer_intention_healing_label',
    ]);
  });

  test('empty texts and unusable slugs create nothing', () {
    final missing = intentionKeysToCreate(<String>{}, const [
      PrayerIntention(slug: 'silence', label: 'Silence', description: ''),
      PrayerIntention(slug: 'Long Life', label: 'Long life', description: 'x'),
      PrayerIntention(slug: 'blank', label: '', description: ''),
    ]);
    expect(missing, {'prayer_intention_silence_label': 'Silence'});
  });

  test('stale keys are the prefixed ones no intention backs', () {
    final stale = staleIntentionKeys(
      {
        'prayer_intention_peace_label',
        'prayer_intention_peace_description',
        'prayer_intention_wealth_label',
        'event_prayer_pray',
        'Peace',
      },
      [_peace],
    );
    expect(stale, {'prayer_intention_wealth_label'});
  });
}
