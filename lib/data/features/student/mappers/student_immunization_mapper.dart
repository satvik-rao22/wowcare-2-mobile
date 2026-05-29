import '../../../../domain/features/student/entities/student_immunization.dart';
import '../models/student_models.dart';

/// Translates the data-layer [StudentImmunizationModel] DTO into the pure domain
/// [StudentImmunization] entity.
extension StudentImmunizationModelMapper on StudentImmunizationModel {
  StudentImmunization toEntity() => StudentImmunization(
        code: code,
        studentCode: studentCode,
        vaccineName: vaccineName,
        vaccineDoseCode: vaccineDoseCode,
        doseNumber: doseNumber,
        dueDate: dueDate,
        administeredDate: administeredDate,
        status: status,
        exemptionReason: exemptionReason,
        notes: notes,
      );
}
