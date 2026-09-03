import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/communication_settings.dart';
import '../repositories/communication_settings_repository.dart';

class GetCommunicationSettingsUseCase {
  GetCommunicationSettingsUseCase(this._repository);

  final CommunicationSettingsRepository _repository;

  Future<Either<Failure, CommunicationSettings>> call(String schoolCode) =>
      _repository.getCommunicationSettings(schoolCode);
}
