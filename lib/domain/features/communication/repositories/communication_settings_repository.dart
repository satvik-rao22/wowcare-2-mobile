import 'package:dartz/dartz.dart';

import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/communication_settings.dart';

abstract class CommunicationSettingsRepository {
  Future<Either<Failure, CommunicationSettings>> getCommunicationSettings(
    String schoolCode,
  );
}
