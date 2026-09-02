import 'package:wowcare/domain/features/attendance/entities/student_attendance_absent_view_response.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_attendance_absent_view_usecase.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_classroom_by_code_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_names_for_school_usecase.dart';

/// ViewModel seam for [StudentAttendanceAbsentView]. Thin by design: it wraps
/// every raw `serviceLocator<UseCase>()` call the View previously made
/// directly, with the same signatures and return types, so no transformation
/// or setState logic in the View had to change — only where the fetch calls
/// live. [StudentAttendanceAbsentView] has no automated test coverage and is
/// a legal attendance record screen, so this migration is deliberately
/// scoped to relocating the fetch calls only (Mandate 5), matching the
/// pattern used for the two Profile screens.
class StudentAttendanceAbsentFetchCubit {
  StudentAttendanceAbsentFetchCubit({
    required GetStudentAttendanceAbsentViewUseCase
    getStudentAttendanceAbsentViewUseCase,
    required GetTagNameCodeMapForSchoolUseCase
    getTagNameCodeMapForSchoolUseCase,
    required GetTagNamesForSchoolUseCase getTagNamesForSchoolUseCase,
    required GetClassroomByCodeUseCase getClassroomByCodeUseCase,
  }) : _getStudentAttendanceAbsentViewUseCase =
           getStudentAttendanceAbsentViewUseCase,
       _getTagNameCodeMapForSchoolUseCase = getTagNameCodeMapForSchoolUseCase,
       _getTagNamesForSchoolUseCase = getTagNamesForSchoolUseCase,
       _getClassroomByCodeUseCase = getClassroomByCodeUseCase;

  final GetStudentAttendanceAbsentViewUseCase
  _getStudentAttendanceAbsentViewUseCase;
  final GetTagNameCodeMapForSchoolUseCase _getTagNameCodeMapForSchoolUseCase;
  final GetTagNamesForSchoolUseCase _getTagNamesForSchoolUseCase;
  final GetClassroomByCodeUseCase _getClassroomByCodeUseCase;

  /// Used by [_loadAbsentStudents] for the paginated absent-student list.
  Future<StudentAttendanceAbsentViewResponse?> fetchAbsentStudents({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  }) {
    return _getStudentAttendanceAbsentViewUseCase(
      fromAbsenceDate: fromAbsenceDate,
      toAbsenceDate: toAbsenceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      sort: sort,
    );
  }

  /// Used by [_loadTagData] for the tag name<->code map (sent as tagCodes)
  /// and the UI dropdown's display names.
  Future<Map<String, String>> fetchTagNameCodeMap({
    required String schoolCode,
  }) {
    return _getTagNameCodeMapForSchoolUseCase(schoolCode: schoolCode);
  }

  Future<List<String>> fetchTagNames({required String schoolCode}) {
    return _getTagNamesForSchoolUseCase(schoolCode: schoolCode);
  }

  /// Used by the View's own on-demand classroom-name cache when a row's
  /// classroom name isn't already known. Returns null (rather than
  /// throwing) on failure, matching the View's previous "keep code when
  /// lookup fails" behavior.
  Future<String?> fetchClassroomName(String code) async {
    try {
      final details = await _getClassroomByCodeUseCase(code: code);
      final name = details.name.trim();
      return name.isNotEmpty ? name : null;
    } catch (_) {
      return null;
    }
  }
}
