import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitation_live_settings_remote_datasource.dart';
import 'package:flutter_pecha/features/recitation/data/models/edition_live_settings.dart';
import 'package:fpdart/fpdart.dart';

class RecitationLiveSettingsRepository {
  RecitationLiveSettingsRepository({required this.datasource});

  final RecitationLiveSettingsRemoteDatasource datasource;

  Future<Either<Failure, EditionLiveSettings>> getEditionLiveSettings(
    String editionId,
  ) async {
    try {
      return Right(await datasource.fetchEditionLiveSettings(editionId));
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'getEditionLiveSettings'));
    }
  }
}
