import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/student_repository.dart';

class UpdatePickupUseCase {
  UpdatePickupUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({
    required String code,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String relation,
    String? clockPin,
    String? relationshipDescription,
    String? pickupType,
    String? carpoolId,
  }) {
    return AppEvents.track(
      AppEvent.studentPickupUpdate,
      () => _repository.updatePickup(
        code: code,
        studentCode: studentCode,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        relation: relation,
        clockPin: clockPin,
        relationshipDescription: relationshipDescription,
        pickupType: pickupType,
        carpoolId: carpoolId,
      ),
    );
  }
}
