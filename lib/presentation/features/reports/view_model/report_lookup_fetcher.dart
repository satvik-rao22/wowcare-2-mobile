import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/domain/features/reports/usecases/get_school_code_usecase.dart';
import 'package:wowcare/domain/features/reports/usecases/get_school_name_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_immunization_settings_usecase.dart';
import 'package:wowcare/domain/features/student_classroom/entities/student_classroom_item.dart';
import 'package:wowcare/domain/features/student_classroom/usecases/get_student_classroom_list_usecase.dart';

/// Stateless lookups the report forms need — vaccines, the school name, and
/// the students of a set of classrooms.
///
/// These never touch cubit state: they take use cases in, return plain data
/// out. Splitting them off `reports_lookup_cubit.dart` (§6.7) separates
/// fetching from state management and brings that file under the size ceiling
/// without exposing the cubit's internals.
class ReportLookupFetcher {
  const ReportLookupFetcher({
    required GetSchoolCodeUseCase getSchoolCodeUseCase,
    required GetSchoolNameUseCase getSchoolNameUseCase,
    required GetImmunizationSettingsUseCase getImmunizationSettingsUseCase,
    required GetStudentClassroomListUseCase getStudentClassroomListUseCase,
  }) : _getSchoolCodeUseCase = getSchoolCodeUseCase,
       _getSchoolNameUseCase = getSchoolNameUseCase,
       _getImmunizationSettingsUseCase = getImmunizationSettingsUseCase,
       _getStudentClassroomListUseCase = getStudentClassroomListUseCase;

  final GetSchoolCodeUseCase _getSchoolCodeUseCase;
  final GetSchoolNameUseCase _getSchoolNameUseCase;
  final GetImmunizationSettingsUseCase _getImmunizationSettingsUseCase;
  final GetStudentClassroomListUseCase _getStudentClassroomListUseCase;

  /// The school's configured vaccines, as a name → code map. Empty when the
  /// school code is unset, matching the old in-view early return.
  Future<Map<String, String>> fetchVaccineNameToCode() async {
    final schoolCode = await _getSchoolCodeUseCase();
    if (schoolCode.isEmpty) {
      AppLogger.w(
        '[ImmunizationReport] schoolCode is empty – skipping vaccine load',
      );
      return const <String, String>{};
    }

    final vaccines = await _getImmunizationSettingsUseCase(
      schoolCode: schoolCode,
    );
    AppLogger.d(
      '[ImmunizationReport] Loaded ${vaccines.length} vaccines from API: '
      '$vaccines',
    );

    final nameToCode = <String, String>{};
    for (final v in vaccines) {
      if (v.name.isNotEmpty && v.code.isNotEmpty) {
        nameToCode[v.name] = v.code;
      }
    }
    AppLogger.d('[ImmunizationReport] vaccineNameToCode map: $nameToCode');
    return nameToCode;
  }

  /// Loads the school's vaccines into [ReportsState.vaccineNames] /
  /// [ReportsState.vaccineNameToCode], toggling
  /// [ReportsState.vaccinesLoading] around the call.
  ///
  /// Replaces the `_loadVaccines()` the immunization form ran in widget state:
  /// an API result plus its loading flag is §2.2 bucket A.

  /// The school name, exactly as the forms used to read it straight off
  /// storage. Returns '' when unset, matching the old expression.
  Future<String> resolveSchoolName() async {
    return _getSchoolNameUseCase();
  }

  /// ACTIVE students across [classroomCodes], as a full-name → student-code
  /// map. Replaces the per-classroom fetch loop the three student/billing
  /// forms each carried.
  ///
  /// [concurrent] preserves the callers' request patterns rather than
  /// unifying them: the attendance-per-student and billing-transaction forms
  /// fetched classroom-by-classroom in sequence, the billing report form
  /// fetched all classrooms at once. A per-classroom failure yields no
  /// students for that classroom and does not fail the whole call — the same
  /// behaviour as the `catch` inside each old loop.
  Future<Map<String, String>> fetchStudentsForClassrooms({
    required List<String> classroomCodes,
    bool concurrent = false,
  }) async {
    final schoolCode = await _getSchoolCodeUseCase();

    Future<List<StudentClassroomItem>> fetch(String code) =>
        _getStudentClassroomListUseCase(
          schoolCode: schoolCode,
          classroomCode: code,
          status: const ['ACTIVE'],
          refresh: true,
        ).catchError((_) => <StudentClassroomItem>[]);

    final results = <List<StudentClassroomItem>>[];
    if (concurrent) {
      results.addAll(await Future.wait(classroomCodes.map(fetch)));
    } else {
      for (final code in classroomCodes) {
        results.add(await fetch(code));
      }
    }

    final nameToCode = <String, String>{};
    for (final studentList in results) {
      for (final s in studentList) {
        final fullName = s.fullName.trim();
        if (fullName.isNotEmpty && s.studentCode.trim().isNotEmpty) {
          nameToCode[fullName] = s.studentCode.trim();
        }
      }
    }
    return nameToCode;
  }

  /// Loads the school's tags (names + name→TAG_* code map) and stores both in
  /// state. Tags are optional metadata so failures are swallowed.
}
