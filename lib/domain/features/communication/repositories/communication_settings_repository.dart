import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/communication_settings.dart';

abstract class CommunicationSettingsRepository {
  Future<Either<Failure, CommunicationSettings>> getCommunicationSettings(
    String schoolCode,
  );
}
