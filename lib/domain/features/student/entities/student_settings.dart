/// School-level student settings from `GET /api/v1/student-settings`.
///
/// Drives who may edit a student's Health tab and Documents tab:
/// - [canParentEditChildHealthRecords] → guardian may edit Health and
///   Documents; staff may edit Health (shared toggle, per backend contract).
/// - [canStaffEditTheirOwnHealthRecords] → despite its name, this is the
///   toggle for whether staff may add/edit a student's Documents.
class StudentSettings {
  const StudentSettings({
    this.code = '',
    this.schoolCode = '',
    this.organizationCode = '',
    this.canParentEditChildHealthRecords = false,
    this.canStaffEditTheirOwnHealthRecords = false,
  });

  final String code;
  final String schoolCode;
  final String organizationCode;
  final bool canParentEditChildHealthRecords;
  final bool canStaffEditTheirOwnHealthRecords;
}
