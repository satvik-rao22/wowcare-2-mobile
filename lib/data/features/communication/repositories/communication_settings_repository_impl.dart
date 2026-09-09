import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/api_error_handler.dart';
import '../../../../domain/features/communication/entities/communication_settings.dart';
import '../../../../domain/features/communication/repositories/communication_settings_repository.dart';
import '../datasources/communication_settings_remote_data_source.dart';

class CommunicationSettingsRepositoryImpl
    implements CommunicationSettingsRepository {
  CommunicationSettingsRepositoryImpl({required this.remoteDataSource});

  final CommunicationSettingsRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, CommunicationSettings>> getCommunicationSettings(
    String schoolCode,
  ) async {
    try {
      final model = await remoteDataSource.getCommunicationSettings(
        schoolCode,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(ApiErrorHandler.extractErrorMessage(e)));
    }
  }
}
