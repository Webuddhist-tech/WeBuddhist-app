import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/firebase_session_repository.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/firebase_session_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../helpers/fake_firebase_auth_gateway.dart';

class _FakeRepository implements FirebaseSessionRepository {
  int calls = 0;
  Failure? failure;

  /// Failures returned before a success; null entries succeed.
  final queue = <Failure?>[];

  @override
  Future<Either<Failure, FirebaseCustomToken>> fetchCustomToken() async {
    calls++;
    final next = queue.isNotEmpty ? queue.removeAt(0) : failure;
    if (next != null) return Left(next);
    return const Right(FirebaseCustomToken(token: 'token-for-u1', uid: 'u1'));
  }
}

Future<void> _settle() => pumpEventQueue();

void main() {
  late _FakeRepository repository;
  late FakeFirebaseAuthGateway gateway;
  late List<bool> published;
  late FirebaseSessionNotifier notifier;

  setUp(() {
    repository = _FakeRepository();
    gateway = FakeFirebaseAuthGateway();
    published = [];
    notifier = FirebaseSessionNotifier(
      repository: repository,
      gateway: gateway,
      publish: published.add,
      backoff: (_) => const Duration(milliseconds: 10),
      maxAttempts: 2,
    );
    addTearDown(notifier.dispose);
  });

  test('a login mints a token and signs in', () async {
    notifier.onAuthChanged(loggedIn: true);
    await _settle();

    expect(repository.calls, 1);
    expect(gateway.signedInTokens, ['token-for-u1']);
    expect(notifier.state.signedIn, isTrue);
    expect(notifier.state.uid, 'u1');
    expect(published, [true]);
  });

  test('an existing Firebase user skips the token endpoint', () async {
    gateway.uid = 'u1';
    notifier.onAuthChanged(loggedIn: true);
    await _settle();

    expect(repository.calls, 0);
    expect(notifier.state.signedIn, isTrue);
  });

  test('a uid mismatch still signs in', () async {
    gateway.uidToReturn = 'other';
    notifier.onAuthChanged(loggedIn: true);
    await _settle();

    expect(notifier.state.signedIn, isTrue);
    expect(notifier.state.uid, 'other');
  });

  test('a 503 switches live off without retrying', () async {
    repository.failure = const FirebaseDisabledFailure('off');
    notifier.onAuthChanged(loggedIn: true);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(repository.calls, 1);
    expect(notifier.state.disabled, isTrue);
    expect(notifier.state.signedIn, isFalse);
    expect(published, isEmpty);
  });

  test('a transient failure is retried with backoff', () async {
    repository.queue.addAll([const NetworkFailure('offline'), null]);
    notifier.onAuthChanged(loggedIn: true);
    await _settle();
    expect(notifier.state.signedIn, isFalse);

    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(repository.calls, 2);
    expect(notifier.state.signedIn, isTrue);
  });

  test('gives up after the allowed attempts and resumes on request', () async {
    repository.failure = const NetworkFailure('offline');
    notifier.onAuthChanged(loggedIn: true);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(repository.calls, 3);
    expect(notifier.state.signedIn, isFalse);

    repository.failure = null;
    notifier.resume();
    await _settle();
    expect(notifier.state.signedIn, isTrue);
  });

  test('a logout signs out of Firebase, flag first', () async {
    notifier.onAuthChanged(loggedIn: true);
    await _settle();

    notifier.onAuthChanged(loggedIn: false);
    expect(published, [true, false]);
    await _settle();
    expect(gateway.signOutCalls, 1);
    expect(notifier.state.signedIn, isFalse);
  });

  test('the Firebase user vanishing while logged in signs in again', () async {
    notifier.onAuthChanged(loggedIn: true);
    await _settle();

    gateway.setUser(null);
    await _settle();

    expect(repository.calls, 2);
    expect(notifier.state.signedIn, isTrue);
    expect(published, [true, false, true]);
  });

  test('repeated auth snapshots with the same answer are ignored', () async {
    notifier.onAuthChanged(loggedIn: true);
    notifier.onAuthChanged(loggedIn: true);
    await _settle();

    expect(repository.calls, 1);
  });

  test('a logout mid-mint drops the sign-in', () async {
    notifier.onAuthChanged(loggedIn: true);
    notifier.onAuthChanged(loggedIn: false);
    await _settle();

    expect(gateway.signedInTokens, isEmpty);
    expect(notifier.state.signedIn, isFalse);
  });
}
