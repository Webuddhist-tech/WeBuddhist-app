import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/firebase_session_repository.dart';
import 'package:fpdart/fpdart.dart';

class FirebaseSessionRepositoryImpl implements FirebaseSessionRepository {
  FirebaseSessionRepositoryImpl({required Dio dio}) : _dio = dio;

  /// Bearer is injected by the matching [ProtectedRoutes] entry.
  static const String _tokenPath = '/auth/firebase-token';

  final Dio _dio;

  @override
  Future<Either<Failure, FirebaseCustomToken>> fetchCustomToken() async {
    try {
      final response = await _dio.post(
        _tokenPath,
        options: Options(extra: {'no_cache': true}),
      );
      final data = response.data;
      final token = data is Map ? data['token'] : null;
      final uid = data is Map ? data['uid'] : null;
      if (token is! String || token.isEmpty || uid is! String) {
        return const Left(ServerFailure('Firebase token response malformed'));
      }
      return Right(FirebaseCustomToken(token: token, uid: uid));
    } on DioException catch (e) {
      if (e.response?.statusCode == 503) {
        return const Left(FirebaseDisabledFailure('Firebase not configured'));
      }
      return Left(ExceptionMapper.map(e, context: 'fetchCustomToken'));
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'fetchCustomToken'));
    }
  }
}
