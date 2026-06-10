enum ReportType {
  // Student Attendance (4 types)
  studentDailyAttendance('STUDENT_DAILY_ATTENDANCE'),
  studentAbsent('STUDENT_ABSENT'),
  studentAttendancePerStudent('STUDENT_ATTENDANCE_PER_STUDENT'),

  // Staff Attendance (3 types)
  staffAbsent('STAFF_ABSENT'),
  staffAttendance('STAFF_ATTENDANCE'),
  staffAttendancePerStaff('STAFF_ATTENDANCE_PER_STAFF'),

  // Staff Management (1 type - staffSchedule unavailable)
  staffDetails('STAFF_DETAILS'),

  // Student Management (3 types)
  studentsAndFamily('STUDENTS_AND_FAMILY'),
  emergencyContacts('EMERGENCY_CONTACTS'),
  studentIncident('STUDENT_INCIDENT'),

  // Immunization (1 type)
  immunization('IMMUNIZATION');

  const ReportType(this.backendValue);

  final String backendValue;
}
