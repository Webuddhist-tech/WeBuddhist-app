import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/data/datasource/home_local_datasource.dart';
import 'package:flutter_pecha/features/home/data/datasource/series_remote_datasource.dart';
import 'package:flutter_pecha/features/home/data/repositories/series_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory stand-in for the Hive-backed store.
class _FakeLocal extends HomeLocalDatasource {
  Set<String>? enrollments;
  Set<String> pending = {};

  @override
  Future<String?> currentUserId() async => 'user-1';

  @override
  Set<String>? readEnrollments(String userId) => enrollments;

  @override
  Future<void> saveEnrollments(String userId, Set<String> ids) async {
    enrollments = {...ids};
  }

  @override
  Set<String> readPendingEnrollments(String userId) => {...pending};

  @override
  Future<void> enqueueEnrollment(String userId, String seriesId) async {
    pending = {...pending, seriesId};
    enrollments = {...?enrollments, seriesId};
  }

  @override
  Future<void> removePendingEnrollment(String userId, String seriesId) async {
    pending = {...pending}..remove(seriesId);
  }
}

/// Answers each enroll call with the error queued for that series, if any.
class _FakeRemote extends SeriesRemoteDatasource {
  _FakeRemote() : super(dio: Dio());

  final Map<String, Exception> errors = {};
  final List<(String, String?)> calls = [];

  /// Runs at the start of every enroll call, while the request is in flight.
  void Function()? onCall;

  @override
  Future<void> enrollInSeries(String seriesId, {String? groupId}) async {
    calls.add((seriesId, groupId));
    onCall?.call();
    final error = errors[seriesId];
    if (error != null) throw error;
  }
}

/// Answers every request with [status] and no body.
class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.status);

  final int status;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString('', status);

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeLocal local;
  late _FakeRemote remote;
  late SeriesRepository repository;

  setUp(() {
    local = _FakeLocal();
    remote = _FakeRemote();
    repository = SeriesRepository(remote: remote, local: local);
  });

  group('enrollInSeries', () {
    test('success clears the queue and keeps the enrollment', () async {
      final result = await repository.enrollInSeries('s1');

      expect(result.isRight(), isTrue);
      expect(local.pending, isEmpty);
      expect(local.enrollments, {'s1'});
    });

    test(
      'offline personal enrollment stays queued and reports success',
      () async {
        remote.errors['s1'] = const NetworkException('No internet connection');

        final result = await repository.enrollInSeries('s1');

        expect(result.isRight(), isTrue);
        expect(local.pending, {'s1'});
        expect(local.enrollments, {'s1'});
      },
    );

    test('a server rejection is reported and undone locally', () async {
      remote.errors['s1'] = const ServerException('Failed: 500');

      final result = await repository.enrollInSeries('s1');

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
      expect(local.pending, isEmpty);
      expect(local.enrollments, isEmpty);
    });

    test('an offline group enrollment fails instead of queueing', () async {
      remote.errors['s1'] = const NetworkException('No internet connection');

      final result = await repository.enrollInSeries('s1', groupId: 'g1');

      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
      expect(local.pending, isEmpty);
      expect(local.enrollments ?? const <String>{}, isEmpty);
    });

    test('a failed group attempt keeps a queued personal enrollment', () async {
      local.pending = {'s1'};
      local.enrollments = {'s1'};
      remote.errors['s1'] = const ServerException('Failed: 500');

      final result = await repository.enrollInSeries('s1', groupId: 'g1');

      expect(result.isLeft(), isTrue);
      expect(local.pending, {'s1'});
      expect(local.enrollments, {'s1'});
    });

    test('a group enrollment is never in the queue while it is sent', () async {
      Set<String>? pendingDuringRequest;
      remote.onCall = () => pendingDuringRequest = {...local.pending};

      final result = await repository.enrollInSeries('s1', groupId: 'g1');

      expect(result.isRight(), isTrue);
      expect(pendingDuringRequest, isEmpty);
      expect(remote.calls, [('s1', 'g1')]);
      expect(local.enrollments, {'s1'});
    });

    test(
      'a group enrollment that succeeds clears a queued personal one',
      () async {
        local.pending = {'s1'};
        local.enrollments = {'s1'};

        await repository.enrollInSeries('s1', groupId: 'g1');

        expect(local.pending, isEmpty);
        expect(local.enrollments, {'s1'});
      },
    );

    test(
      'a server error keeps an enrollment that was already queued',
      () async {
        local.pending = {'s1'};
        local.enrollments = {'s1'};
        remote.errors['s1'] = const ServerException('Failed: 500');

        final result = await repository.enrollInSeries('s1');

        expect(result.isLeft(), isTrue);
        expect(local.pending, {'s1'});
        expect(local.enrollments, {'s1'});
      },
    );

    test('a refusal drops an enrollment that was already queued', () async {
      local.pending = {'s1'};
      local.enrollments = {'s1'};
      remote.errors['s1'] = const AuthorizationException('Failed: 403');

      final result = await repository.enrollInSeries('s1');

      expect(result.getLeft().toNullable(), isA<AuthorizationFailure>());
      expect(local.pending, isEmpty);
      expect(local.enrollments, isEmpty);
    });

    test('a failed retry keeps an enrollment the user already had', () async {
      local.enrollments = {'s1'};
      remote.errors['s1'] = const ServerException('Failed: 500');

      await repository.enrollInSeries('s1');

      expect(local.enrollments, {'s1'});
    });
  });

  group('flushPendingEnrollments', () {
    test('a rejected series does not block the ones after it', () async {
      local.pending = {'a', 'b'};
      local.enrollments = {'a', 'b'};
      remote.errors['a'] = const ServerException('Failed: 500');

      await repository.flushPendingEnrollments();

      expect(remote.calls.map((c) => c.$1), containsAll(['a', 'b']));
      expect(local.pending, {'a'});
    });

    test(
      'a deleted series is dropped from the queue and enrollments',
      () async {
        local.pending = {'gone'};
        local.enrollments = {'gone'};
        remote.errors['gone'] = const NotFoundException('Series not found');

        await repository.flushPendingEnrollments();

        expect(local.pending, isEmpty);
        expect(local.enrollments, isEmpty);
      },
    );

    test('a refused series is dropped instead of retried forever', () async {
      local.pending = {'a', 'b'};
      local.enrollments = {'a', 'b'};
      remote.errors['a'] = const ValidationException('Failed: 400');

      await repository.flushPendingEnrollments();

      expect(local.pending, isEmpty);
      expect(local.enrollments, {'b'});
    });

    test('an auth error keeps everything queued', () async {
      local.pending = {'a', 'b'};
      local.enrollments = {'a', 'b'};
      remote.errors['a'] = const AuthenticationException('Unauthorized');

      await repository.flushPendingEnrollments();

      expect(local.pending, {'a', 'b'});
      expect(local.enrollments, {'a', 'b'});
    });

    test('still offline stops and keeps everything queued', () async {
      local.pending = {'a', 'b'};
      remote.errors['a'] = const NetworkException('No internet connection');

      await repository.flushPendingEnrollments();

      expect(remote.calls, hasLength(1));
      expect(local.pending, {'a', 'b'});
    });
  });

  group('SeriesRemoteDatasource.enrollInSeries 403', () {
    SeriesRemoteDatasource remoteAnswering403({String? token}) {
      final dio = Dio()..httpClientAdapter = _StatusAdapter(403);
      if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
      return SeriesRemoteDatasource(dio: dio);
    }

    test('without a bearer is an auth error, so it stays queued', () async {
      await expectLater(
        remoteAnswering403().enrollInSeries('s1'),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('with a bearer is a refusal', () async {
      await expectLater(
        remoteAnswering403(token: 't').enrollInSeries('s1'),
        throwsA(isA<AuthorizationException>()),
      );
    });
  });
}
