import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';

/// Why something could not be loaded, as the person should be told it.
enum LoadErrorKind {
  /// The phone could not reach the server: "check your connection".
  connection,

  /// The server answered with an error, or the app is set up wrong: the
  /// connection is fine, so it is worth trying again later.
  server,

  /// There is nothing there: "no content".
  missing,
}

/// The [LoadErrorKind] of [error]: a [DioException] (by the domain exception
/// the error interceptor puts in it, else by its own type), an
/// [AppException], a [Failure], or anything else thrown. Only a missing
/// resource or a failed connection says so; every other error is the
/// server's or the setup's, never the person's connection.
LoadErrorKind loadErrorKindOf(Object? error) {
  final inner =
      error is DioException && error.error != null ? error.error : error;
  if (inner is NetworkException ||
      inner is NetworkFailure ||
      inner is SocketException ||
      inner is TimeoutException) {
    return LoadErrorKind.connection;
  }
  if (inner is NotFoundException || inner is NotFoundFailure) {
    return LoadErrorKind.missing;
  }
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return LoadErrorKind.connection;
      case DioExceptionType.badResponse:
        return error.response?.statusCode == 404
            ? LoadErrorKind.missing
            : LoadErrorKind.server;
      default:
        break;
    }
  }
  return LoadErrorKind.server;
}
