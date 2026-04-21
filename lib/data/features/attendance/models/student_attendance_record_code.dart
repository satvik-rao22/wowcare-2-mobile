String? _trimmedString(dynamic v) {
  if (v == null) return null;
  final t = v.toString().trim();
  return t.isEmpty ? null : t;
}

String? _codeFromNestedObject(dynamic v) {
  if (v is! Map) return null;
  final m = Map<String, dynamic>.from(v);
  return _trimmedString(m['code']) ??
      _trimmedString(m['attendanceRecordCode']) ??
      _trimmedString(m['studentAttendanceRecordCode']);
}

/// Resolves the identifier that student attendance mutation APIs expect
/// (`PATCH`/`DELETE` `/api/v1/student-attendance-records/{code}`).
///
/// Contract: use the daily list entry `code` as mutation id whenever present.
String? resolveStudentAttendanceRecordCodeForMutations(
  Map<String, dynamic> json,
) {
  String? s(dynamic v) => _trimmedString(v);

  final code = s(json['code']);
  // Daily mutation APIs expect rowCode from daily view list entry.
  if (code != null) return code;

  final studentAttendanceRecord = s(json['studentAttendanceRecordCode']) ??
      s(json['student_attendance_record_code']) ??
      _codeFromNestedObject(json['studentAttendanceRecord']) ??
      _codeFromNestedObject(json['studentAttendance']) ??
      s(json['recordCode']) ??
      s(json['baseAttendanceRecordCode']) ??
      s(json['primaryAttendanceRecordCode']);
  if (studentAttendanceRecord != null) {
    return studentAttendanceRecord;
  }

  final attendanceRecord = s(json['attendanceRecordCode']) ??
      s(json['attendance_record_code']) ??
      _codeFromNestedObject(json['attendanceRecord']);
  if (attendanceRecord != null) return attendanceRecord;

  final parent = s(json['parentAttendanceRecordCode']) ??
      s(json['parent_attendance_record_code']) ??
      s(json['parentCode']) ??
      s(json['parent_code']) ??
      s(json['dayAttendanceRecordCode']) ??
      s(json['rootAttendanceRecordCode']) ??
      _codeFromNestedObject(json['parentAttendanceRecord']) ??
      _codeFromNestedObject(json['parent']);
  if (parent != null) {
    return parent;
  }

  return null;
}

/// Resolves the identifier that staff attendance mutation APIs expect
/// (`PATCH`/`DELETE` `/api/v1/staff-attendance-records/{code}`).
///
/// Contract: use the daily list entry `code` as mutation id whenever present.
String? _staffCodeFromNestedObject(dynamic v) {
  if (v is! Map) return null;
  final m = Map<String, dynamic>.from(v);
  return _trimmedString(m['code']) ??
      _trimmedString(m['attendanceRecordCode']) ??
      _trimmedString(m['staffAttendanceRecordCode']);
}

String? resolveStaffAttendanceRecordCodeForMutations(
  Map<String, dynamic> json,
) {
  String? s(dynamic v) => _trimmedString(v);

  final code = s(json['code']);
  // Daily mutation APIs expect rowCode from daily view list entry.
  if (code != null) return code;

  final staffAttendanceRecord = s(json['staffAttendanceRecordCode']) ??
      s(json['staff_attendance_record_code']) ??
      _staffCodeFromNestedObject(json['staffAttendanceRecord']) ??
      _staffCodeFromNestedObject(json['staffAttendance']) ??
      s(json['recordCode']) ??
      s(json['baseAttendanceRecordCode']) ??
      s(json['primaryAttendanceRecordCode']);
  if (staffAttendanceRecord != null) {
    return staffAttendanceRecord;
  }

  final attendanceRecord = s(json['attendanceRecordCode']) ??
      s(json['attendance_record_code']) ??
      _staffCodeFromNestedObject(json['attendanceRecord']);
  if (attendanceRecord != null) return attendanceRecord;

  final parent = s(json['parentAttendanceRecordCode']) ??
      s(json['parent_attendance_record_code']) ??
      s(json['parentCode']) ??
      s(json['parent_code']) ??
      s(json['dayAttendanceRecordCode']) ??
      s(json['rootAttendanceRecordCode']) ??
      _staffCodeFromNestedObject(json['parentAttendanceRecord']) ??
      _staffCodeFromNestedObject(json['parent']);
  if (parent != null) {
    return parent;
  }

  return null;
}
