import '../../../../domain/features/student/entities/student_health.dart';
import '../models/student_models.dart';

/// Translates the data-layer [StudentHealthModel] DTO into the pure domain
/// [StudentHealth] entity.
extension StudentHealthModelMapper on StudentHealthModel {
  StudentHealth toEntity() => StudentHealth(
    allergy: allergy,
    medications: medications,
    dietRestrictions: dietRestrictions,
    photoPermission: photoPermission,
  );
}
