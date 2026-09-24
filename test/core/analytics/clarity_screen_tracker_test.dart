import 'package:flutter_pecha/core/analytics/clarity_screen_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> reported;
  late ClarityScreenTracker tracker;
  final Object root = Object();
  final Object shell = Object();

  setUp(() {
    reported = [];
    tracker = ClarityScreenTracker(onScreenChanged: reported.add);
  });

  test('reports named pages on the root navigator', () {
    tracker.push(navigator: root, depth: 0, route: Object(), name: 'splash');
    tracker.push(navigator: root, depth: 0, route: Object(), name: 'login');

    expect(reported, ['splash', 'login']);
  });

  test('descends through the shell host page and reports the tab', () {
    tracker.push(navigator: root, depth: 0, route: Object(), isHost: true);
    expect(reported, isEmpty);

    tracker.push(navigator: shell, depth: 1, route: Object(), name: 'home');
    tracker.setTab('practice');
    tracker.push(
      navigator: shell,
      depth: 1,
      route: Object(),
      name: 'home-settings',
    );

    expect(reported, ['tab-home', 'tab-practice', 'home-settings']);
  });

  test('a root page above the shell wins until it is popped', () {
    tracker.push(navigator: root, depth: 0, route: Object(), isHost: true);
    tracker.push(navigator: shell, depth: 1, route: Object(), name: 'home');
    final Object chats = Object();
    tracker.push(navigator: root, depth: 0, route: chats, name: 'chats');
    tracker.remove(chats);

    expect(reported, ['tab-home', 'chats', 'tab-home']);
  });

  test('replace swaps the entry in place', () {
    final Object newTimer = Object();
    tracker.push(
      navigator: root,
      depth: 0,
      route: newTimer,
      name: 'home-timer-new',
    );
    tracker.replace(
      oldRoute: newTimer,
      navigator: root,
      depth: 0,
      route: Object(),
      name: 'home-timer-active',
    );

    expect(reported, ['home-timer-new', 'home-timer-active']);
  });

  test('a rebuilt shell navigator drops the stale stack', () {
    tracker.push(navigator: root, depth: 0, route: Object(), isHost: true);
    tracker.push(
      navigator: shell,
      depth: 1,
      route: Object(),
      name: 'home-settings',
    );
    final Object newShell = Object();
    final Object home = Object();
    tracker.push(navigator: newShell, depth: 1, route: home, name: 'home');
    tracker.remove(home);

    expect(reported, ['home-settings', 'tab-home']);
  });

  test('unnamed page routes are reported as unnamed', () {
    tracker.push(navigator: root, depth: 0, route: Object(), name: 'about');
    tracker.push(navigator: root, depth: 0, route: Object());
    tracker.setTab('me');

    expect(reported, ['about', unnamedScreen]);
    expect(tracker.currentScreen, unnamedScreen);
  });
}
