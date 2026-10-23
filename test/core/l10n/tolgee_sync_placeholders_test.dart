import 'package:flutter_test/flutter_test.dart';

import '../../../tool/tolgee_sync.dart' show placeholderNames;

void main() {
  group('placeholderNames', () {
    test('keeps arguments that follow ordinary words', () {
      // `Phone` and `Done` end in `one`, which is also a plural case name.
      expect(placeholderNames('Phone {number}'), <String>{'number'});
      expect(placeholderNames('Done {date}'), <String>{'date'});
      expect(placeholderNames('Hello {name}, {count} new'), <String>{
        'name',
        'count',
      });
    });

    test('treats plural and select case bodies as text', () {
      expect(
        placeholderNames('{count, plural, =1 {round} other {rounds}}'),
        <String>{'count'},
      );
      expect(
        placeholderNames('{count, plural,\n=1 {1 day}\nother {{count} days}\n}'),
        <String>{'count'},
      );
      expect(
        placeholderNames('{gender, select, male {he} female {she} other {they}}'),
        <String>{'gender'},
      );
    });

    test('finds arguments nested inside case bodies', () {
      expect(
        placeholderNames(
          '{people, plural, =1 {{count} from 1 person} '
          'other {{count} from {people} people}}',
        ),
        <String>{'people', 'count'},
      );
    });

    test('handles typed arguments and plain text', () {
      expect(placeholderNames('{n, number, integer} items'), <String>{'n'});
      expect(placeholderNames('{when, date, yMd}'), <String>{'when'});
      expect(placeholderNames('No placeholders here'), isEmpty);
    });
  });
}
