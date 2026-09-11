import '../../../../domain/features/student/entities/student_guardian.dart';
import '../models/student_models.dart';

/// Translates the data-layer [StudentGuardianModel] DTO into the pure domain
/// [StudentGuardian] entity.
extension StudentGuardianModelMapper on StudentGuardianModel {
  StudentGuardian toEntity() => StudentGuardian(
        guardianCode: guardianCode,
        userCode: userCode,
        firstName: firstName,
        lastName: lastName,
        mobile: mobile,
        email: email,
        clockPin: clockPin,
        relationToStudent: relationToStudent,
        primaryContact: primaryContact,
        legalCustody: legalCustody,
        profilePhotoUrl: profilePhotoUrl,
        profilePhotoAssetCode: profilePhotoAssetCode,
        displayNameOverride: displayNameOverride,
      );
}
