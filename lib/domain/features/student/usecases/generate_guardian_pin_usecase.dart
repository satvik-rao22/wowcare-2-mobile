import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/student_repository.dart';

/// Asks the server to generate a new clock PIN for a guardian.
class GenerateGuardianPinUseCase {
  GenerateGuardianPinUseCase(this._repository);

  final StudentRepository _repository;

  Future<({String message, String newClockPin})> call({
    required String guardianCode,
    required String studentCode,
  }) {
    return AppEvents.track(
      AppEvent.guardianPinGenerate,
      () => _repository.generateGuardianPin(
        guardianCode: guardianCode,
        studentCode: studentCode,
      ),
    );
  }
}
