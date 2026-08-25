import '../../../../domain/features/student/entities/student_physician.dart';
import '../models/student_physician_models.dart';

/// Translates the data-layer [StudentPhysicianModel] DTO into the pure domain
/// [StudentPhysician] entity.
extension StudentPhysicianModelMapper on StudentPhysicianModel {
  StudentPhysician toEntity() => StudentPhysician(
    code: code,
    firstName: firstName,
    lastName: lastName,
    email: email,
    phoneNumber: phoneNumber,
    address: address,
    specialty: specialty,
    notes: notes,
    status: status,
  );
}
