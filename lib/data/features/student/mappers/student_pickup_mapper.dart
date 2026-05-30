import '../../../../domain/features/student/entities/student_pickup.dart';
import '../models/student_pickup_models.dart';

/// Translates the data-layer [StudentPickupModel] (JSON DTO) into the pure
/// domain [StudentPickup] entity. Keeps serialisation out of the domain layer.
extension StudentPickupModelMapper on StudentPickupModel {
  StudentPickup toEntity() => StudentPickup(
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
      );
}
