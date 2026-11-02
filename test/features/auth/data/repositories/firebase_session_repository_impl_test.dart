import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/config/protected_routes.dart';
import 'package:flutter_pecha/features/auth/data/repositories/firebase_session_repository_impl.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/firebase_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Replies extends Interceptor {
  _Replies(this.status, this.body);

  final int status;
  final Object? body;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (status >= 400) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: status),
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }
    handler.resolve(
      Response(requestOptions: options, statusCode: status, data: body),
    );
  }
}

FirebaseSessionRepositoryImpl _repo(int status, [Object? body]) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
    ..interceptors.add(_Replies(status, body));
  return FirebaseSessionRepositoryImpl(dio: dio);
}

void main() {
  test('parses the token and uid', () async {
    final result =
        await _repo(200, {'token': 'abc', 'uid': 'u1'}).fetchCustomToken();
    final token = result.getOrElse((_) => throw StateError('left'));
    expect(token.token, 'abc');
    expect(token.uid, 'u1');
  });

  test('a 503 means Firebase is disabled', () async {
    final result = await _repo(503).fetchCustomToken();
    expect(result.isLeft(), isTrue);
    result.fold((f) => expect(f, isA<FirebaseDisabledFailure>()), (_) {});
  });

  test('a malformed body is a server failure', () async {
    final result = await _repo(200, {'uid': 'u1'}).fetchCustomToken();
    expect(result.isLeft(), isTrue);
    result.fold(
      (f) => expect(f, isNot(isA<FirebaseDisabledFailure>())),
      (_) {},
    );
  });

  test('the token endpoint carries the bearer', () {
    expect(ProtectedRoutes.paths, contains('/auth/firebase-token'));
  });
}
