import 'package:equatable/equatable.dart';

/// Typed query parameters for the attendance profile absent-toggle fetch
/// endpoints (student + staff `profile/absent/toggle`).
///
/// Replaces the previously hand-assembled `Map<String, dynamic>` at the call
/// sites. [toQueryParameters] reproduces the exact wire map (same keys, same
/// null-omission rules) so the HTTP request is byte-for-byte unchanged.
///
/// When [includePageableAliasParams] is `true` the `pageable.*` alias keys are
/// emitted alongside the plain paging keys (the profile screens send both for
/// cross-environment compatibility; the dashboard cubit sends only the plain
/// keys).
///
/// [sort] is typed `Object?` because callers pass either a `List<String>`
/// (profile screens) or a `String` (dashboard cubit) — both are preserved
/// verbatim.
class AttendanceProfileAbsentToggleQuery extends Equatable {
  const AttendanceProfileAbsentToggleQuery({
    this.studentCode,
    this.staffCode,
    required this.fromAbsenceDate,
    required this.toAbsenceDate,
    required this.page,
    required this.size,
    this.sort,
    this.allowedClassroomCodes,
    this.includePageableAliasParams = false,
  });

  final String? studentCode;
  final String? staffCode;
  final String fromAbsenceDate;
  final String toAbsenceDate;
  final int page;
  final int size;
  final Object? sort;
  final Object? allowedClassroomCodes;
  final bool includePageableAliasParams;

  Map<String, dynamic> toQueryParameters() {
    return {
      if (studentCode != null) 'studentCode': studentCode,
      if (staffCode != null) 'staffCode': staffCode,
      'fromAbsenceDate': fromAbsenceDate,
      'toAbsenceDate': toAbsenceDate,
      'page': page,
      'size': size,
      if (sort != null) 'sort': sort,
      if (allowedClassroomCodes != null)
        'allowedClassroomCodes': allowedClassroomCodes,
      if (includePageableAliasParams) 'pageable.page': page,
      if (includePageableAliasParams) 'pageable.size': size,
      if (includePageableAliasParams && sort != null) 'pageable.sort': sort,
    };
  }

  @override
  List<Object?> get props => [
        studentCode,
        staffCode,
        fromAbsenceDate,
        toAbsenceDate,
        page,
        size,
        sort,
        allowedClassroomCodes,
        includePageableAliasParams,
      ];
}
