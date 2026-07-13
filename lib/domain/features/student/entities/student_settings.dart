/// School-level student settings from `GET /api/v1/student-settings`.
///
/// Drives who may edit a student's Health tab and Documents:
/// - [canParentEditChildHealthRecords] → guardian/parent persona may edit.
/// - [canStaffEditTheirOwnHealthRecords] → staff persona may edit.
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
