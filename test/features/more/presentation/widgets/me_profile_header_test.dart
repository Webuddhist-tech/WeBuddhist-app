import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/me_profile_header.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpHeader(WidgetTester tester, User user) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: MeProfileHeader(user: user))),
  );
}

void main() {
  testWidgets('does not show the email; it lives in Settings', (tester) async {
    await _pumpHeader(
      tester,
      const User(
        id: 'me',
        displayName: 'Tenzin Dolma',
        username: 'tenzin',
        email: 'tenzin@example.com',
      ),
    );

    expect(find.text('tenzin@example.com'), findsNothing);
  });

  testWidgets('shows the bio, not the display name or username', (
    tester,
  ) async {
    await _pumpHeader(
      tester,
      const User(
        id: 'me',
        displayName: 'Tenzin Dolma',
        username: 'tenzin',
        aboutMe: 'Practising compassion daily',
      ),
    );

    expect(find.text('Practising compassion daily'), findsOneWidget);
    expect(find.text('Tenzin Dolma'), findsNothing);
    expect(find.text('tenzin'), findsNothing);
  });

  testWidgets('shows no text beside the avatar without a bio', (tester) async {
    await _pumpHeader(
      tester,
      const User(id: 'me', displayName: 'Tenzin Dolma', username: 'tenzin'),
    );

    expect(find.byType(Text), findsNothing);
  });
}
