import 'package:wowcare/presentation/features/students/view_model/student_cubit.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';

/// The message for an EMPTY student list, differentiated by *why* it is empty so
/// an empty result reads correctly rather than always saying "No students
/// found":
///
/// - a scope/permission-driven empty (scoped staff with no assigned classrooms),
/// - a search that matched nothing,
/// - a filter set that matched nothing,
/// - or a genuinely empty roster.
///
/// API failures never reach this function — the screen renders the error+retry
/// branch whenever `state.errorMessage != null`, so an API failure is never
/// mistaken for "no students".
String studentListEmptyMessage(StudentState state) {
  if (state.noAccessibleClassrooms) {
    return StudentStrings.noClassroomsAssignedEmpty;
  }
  if (state.searchQuery.trim().isNotEmpty) {
    return StudentStrings.noStudentsMatchYourSearch;
  }
  if (studentListHasActiveFilters(state)) {
    return StudentStrings.noStudentsMatchFilters;
  }
  return StudentStrings.noStudentsFound;
}

/// True when any filter other than the default (Active status, no search) is
/// narrowing the roster — distinguishes "no students match the filters" from
/// "no students exist".
bool studentListHasActiveFilters(StudentState s) {
  bool nonEmptyList(List<String>? l) => l != null && l.isNotEmpty;
  bool nonEmptyStr(String? v) => v != null && v.trim().isNotEmpty;
  return nonEmptyList(s.classroomCodesFilter) ||
      nonEmptyList(s.tagCodesFilter) ||
      nonEmptyList(s.guardianCodesFilter) ||
      nonEmptyList(s.attendanceStatusesFilter) ||
      nonEmptyStr(s.codeFilter) ||
      nonEmptyStr(s.firstNameFilter) ||
      nonEmptyStr(s.lastNameFilter) ||
      (s.statusFilter != null && s.statusFilter != 'ACTIVE');
}
