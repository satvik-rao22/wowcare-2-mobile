import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/student_repository.dart';

class DeletePhysicianUseCase {
  DeletePhysicianUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({required String code, required String studentCode}) {
    return AppEvents.track(
      AppEvent.studentPhysicianDelete,
      () => _repository.deletePhysician(code: code, studentCode: studentCode),
    );
  }
}
