import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/student_repository.dart';

class AddPickupUseCase {
  AddPickupUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String relation,
    String? relationshipDescription,
    required String pickupType,
    String? carpoolId,
  }) {
    return AppEvents.track(
      AppEvent.studentPickupAdd,
      () => _repository.addPickup(
        studentCode: studentCode,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        relation: relation,
        relationshipDescription: relationshipDescription,
        pickupType: pickupType,
        carpoolId: carpoolId,
      ),
    );
  }
}
