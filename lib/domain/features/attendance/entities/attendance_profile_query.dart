import 'package:equatable/equatable.dart';

/// Typed query parameters for the attendance profile fetch endpoints
/// (student + staff `profile`).
///
/// Replaces the previously hand-assembled `Map<String, dynamic>` at the call
/// sites. [toQueryParameters] reproduces the exact wire map (same keys, same
/// null-omission rules) so the HTTP request is byte-for-byte unchanged.
///
/// [sort] is typed `Object?` because callers pass either a `List<String>`
/// (profile screens) or a `String` (dashboard cubit) — both are preserved
/// verbatim.
class AttendanceProfileQuery extends Equatable {
  const AttendanceProfileQuery({
    this.studentCode,
    this.staffCode,
    required this.fromAttendanceDate,
    required this.toAttendanceDate,
    required this.page,
    required this.size,
    this.sort,
    this.allowedClassroomCodes,
  });

  final String? studentCode;
  final String? staffCode;
  final String fromAttendanceDate;
  final String toAttendanceDate;
  final int page;
  final int size;
  final Object? sort;
  final Object? allowedClassroomCodes;

  Map<String, dynamic> toQueryParameters() {
    return {
      if (studentCode != null) 'studentCode': studentCode,
      if (staffCode != null) 'staffCode': staffCode,
      'fromAttendanceDate': fromAttendanceDate,
      'toAttendanceDate': toAttendanceDate,
      'page': page,
      'size': size,
      if (sort != null) 'sort': sort,
      if (allowedClassroomCodes != null)
        'allowedClassroomCodes': allowedClassroomCodes,
    };
  }

  @override
  List<Object?> get props => [
        studentCode,
        staffCode,
        fromAttendanceDate,
        toAttendanceDate,
        page,
        size,
        sort,
        allowedClassroomCodes,
      ];
}
