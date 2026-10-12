import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/student_repository.dart';

class DeletePickupUseCase {
  DeletePickupUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({required String code, required String studentCode}) {
    return AppEvents.track(
      AppEvent.studentPickupDelete,
      () => _repository.deletePickup(code: code, studentCode: studentCode),
    );
  }
}
