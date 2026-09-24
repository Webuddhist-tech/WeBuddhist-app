/// Screen name reported for a page route that was pushed without a name.
const String unnamedScreen = 'unnamed';

/// Prefix of the screen name reported while the tab shell is on top.
const String tabScreenPrefix = 'tab-';

class _ScreenEntry {
  const _ScreenEntry(this.route, this.name, {required this.isHost});

  final Object route;
  final String? name;

  /// An unnamed page that only hosts a nested navigator (the tab shell).
  final bool isHost;
}

class _NavigatorStack {
  _NavigatorStack(this.navigator);

  final Object navigator;
  final List<_ScreenEntry> entries = [];

  _ScreenEntry? get top => entries.isEmpty ? null : entries.last;
}

/// Resolves the visible screen across nested navigators and reports every
/// change to [onScreenChanged]. Clarity groups heatmaps by that name.
class ClarityScreenTracker {
  ClarityScreenTracker({
    required this.onScreenChanged,
    this.tabHostRoute = 'home',
    String initialTab = 'home',
  }) : _tab = initialTab;

  final void Function(String screenName) onScreenChanged;

  /// Route whose screen name is replaced by the selected bottom tab.
  final String tabHostRoute;

  final Map<int, _NavigatorStack> _stacks = {};
  String _tab;
  String? _current;

  String? get currentScreen => _current;

  void setTab(String tab) {
    _tab = tab;
    _refresh();
  }

  void push({
    required Object navigator,
    required int depth,
    required Object route,
    String? name,
    bool isHost = false,
  }) {
    final _NavigatorStack stack = _stackFor(navigator, depth);
    stack.entries.add(_ScreenEntry(route, name, isHost: isHost));
    _refresh();
  }

  void remove(Object route) {
    for (final stack in _stacks.values) {
      stack.entries.removeWhere((entry) => identical(entry.route, route));
    }
    _refresh();
  }

  void replace({
    required Object oldRoute,
    required Object navigator,
    required int depth,
    required Object route,
    String? name,
    bool isHost = false,
  }) {
    final entry = _ScreenEntry(route, name, isHost: isHost);
    for (final stack in _stacks.values) {
      final index = stack.entries.indexWhere(
        (candidate) => identical(candidate.route, oldRoute),
      );
      if (index == -1) continue;
      stack.entries[index] = entry;
      _refresh();
      return;
    }
    push(
      navigator: navigator,
      depth: depth,
      route: route,
      name: name,
      isHost: isHost,
    );
  }

  /// The screen currently on top, or null while nothing is resolvable.
  String? resolve() {
    String? resolved;
    for (var depth = 0; ; depth++) {
      final top = _stacks[depth]?.top;
      if (top == null) break;
      if (top.isHost) continue;
      resolved = top.name ?? unnamedScreen;
      break;
    }
    if (resolved == tabHostRoute) return '$tabScreenPrefix$_tab';
    return resolved;
  }

  // A new navigator at an already tracked depth replaces the stale one, so a
  // rebuilt tab shell never resolves against routes of the disposed one.
  _NavigatorStack _stackFor(Object navigator, int depth) {
    final existing = _stacks[depth];
    if (existing != null && identical(existing.navigator, navigator)) {
      return existing;
    }
    return _stacks[depth] = _NavigatorStack(navigator);
  }

  void _refresh() {
    final next = resolve();
    if (next == null || next == _current) return;
    _current = next;
    onScreenChanged(next);
  }
}
