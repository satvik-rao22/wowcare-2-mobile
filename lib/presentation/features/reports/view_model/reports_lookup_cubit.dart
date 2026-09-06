import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/domain/features/reports/entities/report_metadata_entity.dart';
import 'package:wowcare/domain/features/reports/usecases/get_school_code_usecase.dart';
import 'package:wowcare/domain/features/reports/usecases/get_school_name_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/student_classroom/usecases/get_student_classroom_list_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_immunization_settings_usecase.dart';
import 'package:wowcare/presentation/features/reports/view_model/report_lookup_fetcher.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';
part 'reports_state.dart';

/// The lookup half of [ReportsCubit]: the classroom / student / staff / tag /
/// vaccine data the report forms show in their dropdowns.
///
/// A base class rather than a second cubit on purpose — [ReportsCubit] extends
/// it, so there is still ONE instance, ONE provider and ONE
/// `context.read<ReportsCubit>()` at every call site (§6.7).
///
/// Classroom/student/staff names arrive from their own cubits via
/// [setClassroomNames] / [setStudentNames] / [setStaffNames].
abstract class ReportsLookupCubit extends Cubit<ReportsState> {
  ReportsLookupCubit({
    required GetSchoolCodeUseCase getSchoolCodeUseCase,
    required GetSchoolNameUseCase getSchoolNameUseCase,
    required GetTagNameCodeMapForSchoolUseCase
    getTagNameCodeMapForSchoolUseCase,
    required GetActiveClassroomsUseCase getActiveClassroomsUseCase,
    required GetStudentClassroomListUseCase getStudentClassroomListUseCase,
    required GetImmunizationSettingsUseCase getImmunizationSettingsUseCase,
  }) : _getSchoolCodeUseCase = getSchoolCodeUseCase,
       _getTagNameCodeMapForSchoolUseCase = getTagNameCodeMapForSchoolUseCase,
       _getActiveClassroomsUseCase = getActiveClassroomsUseCase,
       _fetcher = ReportLookupFetcher(
         getSchoolCodeUseCase: getSchoolCodeUseCase,
         getSchoolNameUseCase: getSchoolNameUseCase,
         getImmunizationSettingsUseCase: getImmunizationSettingsUseCase,
         getStudentClassroomListUseCase: getStudentClassroomListUseCase,
       ),
       super(const ReportsState.initial());

  /// Stateless lookups (vaccines, school name, students by classroom).
  final ReportLookupFetcher _fetcher;

  final GetSchoolCodeUseCase _getSchoolCodeUseCase;
  final GetTagNameCodeMapForSchoolUseCase _getTagNameCodeMapForSchoolUseCase;
  final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;

  /// Last-write-wins guard for [loadFormStudents]. Was `_fetchId` in each
  /// form's widget state; it belongs with the fetch it guards.
  int _formStudentsFetchId = 0;

  /// Loads the classroom list a report form shows in its dropdown.
  ///
  /// This is the single replacement for the fetch that was copy-pasted into
  /// seven view files. There are two genuinely different classroom sets and
  /// they are NOT interchangeable, so the caller says which one it needs:
  ///
  /// * [includeNonClassroomTypes] `false` → the `onlyTypeClassroom: true` set,
  ///   stored in [ReportsState.classroomNameToCode] — the same bucket the hub's
  ///   ClassroomCubit listener fills, so this only tops it up when the hub has
  ///   not populated it yet (a form entered before the hub's load finished).
  /// * [includeNonClassroomTypes] `true` → the `onlyTypeClassroom: false`
  ///   superset that also contains Office and primary rooms, stored separately
  ///   in [ReportsState.allClassroomNameToCode]. The staff forms and the
  ///   billing transaction form need this wider list; folding it into the hub's
  ///   bucket would silently add those rooms to the hub's own dropdowns.
  ///
  /// Failures now surface through [ReportsState.formClassroomsStatus] instead
  /// of being swallowed, so a form can no longer be generated against a
  /// silently truncated classroom list.
  Future<void> loadFormClassrooms({
    required bool includeNonClassroomTypes,
  }) async {
    if (isClosed) return;
    emit(
      state.copyWith(
        formClassroomsStatus: FormClassroomsStatus.loading,
        clearFormClassroomsError: true,
      ),
    );

    try {
      final schoolCode = await _getSchoolCodeUseCase();
      if (schoolCode.isEmpty) {
        if (isClosed) return;
        emit(
          state.copyWith(
            formClassroomsStatus: FormClassroomsStatus.failure,
            formClassroomsError: ReportsStrings.unableToResolveSchoolTapToRetry,
          ),
        );
        return;
      }

      final classrooms = await _getActiveClassroomsUseCase(
        schoolCode: schoolCode,
        onlyTypeClassroom: !includeNonClassroomTypes,
      );

      final names = <String>[];
      final nameToCode = <String, String>{};
      for (final c in classrooms) {
        names.add(c.name);
        nameToCode[c.name] = c.code;
      }

      if (isClosed) return;
      emit(
        includeNonClassroomTypes
            ? state.copyWith(
                allClassroomNames: names,
                allClassroomNameToCode: nameToCode,
                formClassroomsStatus: FormClassroomsStatus.loaded,
                clearFormClassroomsError: true,
              )
            : state.copyWith(
                classroomNames: names,
                classroomNameToCode: nameToCode,
                formClassroomsStatus: FormClassroomsStatus.loaded,
                clearFormClassroomsError: true,
              ),
      );
    } catch (e) {
      AppLogger.e('[ReportsCubit] loadFormClassrooms failed: $e');
      if (isClosed) return;
      emit(
        state.copyWith(
          formClassroomsStatus: FormClassroomsStatus.failure,
          formClassroomsError: ReportsStrings.couldNotLoadClassroomsTapToRetry,
        ),
      );
    }
  }

  /// The classroom name→code map, loading it once if the hub has not filled
  /// it in yet. Replaces the `_resolveClassroomNameToCodeMap()` helper (and
  /// its local `_classroomCodeByName` cache) that each form carried.
  Future<Map<String, String>> ensureClassroomNameToCode() async {
    if (state.classroomNameToCode.isNotEmpty) {
      return state.classroomNameToCode;
    }
    await loadFormClassrooms(includeNonClassroomTypes: false);
    return state.classroomNameToCode;
  }

  /// Loads the students of [classroomNames] into [ReportsState.studentNames]
  /// and [ReportsState.studentNameToCode], toggling
  /// [ReportsState.formStudentsLoading] around the call.
  ///
  /// This is the whole of the `_fetchStudentsForClassrooms` orchestration the
  /// billing form used to run in its widget state — the API result and the
  /// loading flag are §2.2 bucket A, "no exceptions". Stale responses are
  /// dropped by [_formStudentsFetchId], the same last-write-wins guard the
  /// view's `_fetchId` provided.

  /// Loads the students of [classroomNames] into [ReportsState.studentNames]
  /// and [ReportsState.studentNameToCode], toggling
  /// [ReportsState.formStudentsLoading] around the call.
  ///
  /// This is the whole of the `_fetchStudentsForClassrooms` orchestration the
  /// billing form used to run in its widget state — the API result and the
  /// loading flag are §2.2 bucket A, "no exceptions". Stale responses are
  /// dropped by [_formStudentsFetchId], the same last-write-wins guard the
  /// view's `_fetchId` provided.
  Future<void> loadFormStudents({
    required List<String> classroomNames,
    bool concurrent = false,
  }) async {
    final fetchId = ++_formStudentsFetchId;

    if (classroomNames.isEmpty) {
      if (isClosed) return;
      emit(
        state.copyWith(
          studentNames: const <String>[],
          studentNameToCode: const <String, String>{},
          formStudentsLoading: false,
        ),
      );
      return;
    }

    emit(state.copyWith(formStudentsLoading: true));

    try {
      final classroomNameToCode = await ensureClassroomNameToCode();
      final classroomCodes = classroomNames
          .map((name) => classroomNameToCode[name])
          .whereType<String>()
          .where((c) => c.trim().isNotEmpty)
          .toSet()
          .toList();

      if (classroomCodes.isEmpty) {
        if (isClosed || fetchId != _formStudentsFetchId) return;
        // Note: the name→code map is deliberately NOT cleared here, matching
        // the branch this replaced.
        emit(
          state.copyWith(
            studentNames: const <String>[],
            formStudentsLoading: false,
          ),
        );
        return;
      }

      final nameToCode = await fetchStudentsForClassrooms(
        classroomCodes: classroomCodes,
        concurrent: concurrent,
      );

      if (isClosed || fetchId != _formStudentsFetchId) return;

      final sortedNames = nameToCode.keys.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      emit(
        state.copyWith(
          studentNames: sortedNames,
          studentNameToCode: nameToCode,
          formStudentsLoading: false,
        ),
      );
    } catch (e) {
      AppLogger.e('[ReportsCubit] loadFormStudents failed: $e');
      if (isClosed || fetchId != _formStudentsFetchId) return;
      emit(state.copyWith(formStudentsLoading: false));
    }
  }

  /// Loads the students of EVERY room (including Office and primary rooms)
  /// into [ReportsState.studentNames] / [ReportsState.studentNameToCode].
  ///
  /// The billing transaction report covers all rooms rather than a chosen
  /// subset, so it needs the `onlyTypeClassroom: false` set. Owning the whole
  /// sequence here keeps the API result and its loading flag out of widget
  /// state (§2.2 bucket A).

  /// Loads the students of EVERY room (including Office and primary rooms)
  /// into [ReportsState.studentNames] / [ReportsState.studentNameToCode].
  ///
  /// The billing transaction report covers all rooms rather than a chosen
  /// subset, so it needs the `onlyTypeClassroom: false` set. Owning the whole
  /// sequence here keeps the API result and its loading flag out of widget
  /// state (§2.2 bucket A).
  Future<void> loadAllRoomStudents() async {
    final fetchId = ++_formStudentsFetchId;
    emit(state.copyWith(formStudentsLoading: true));
    try {
      await loadFormClassrooms(includeNonClassroomTypes: true);
      if (isClosed || fetchId != _formStudentsFetchId) return;

      final classroomCodes = state.allClassroomNameToCode.values.toList();
      if (classroomCodes.isEmpty) {
        emit(
          state.copyWith(
            studentNames: const <String>[],
            formStudentsLoading: false,
          ),
        );
        return;
      }

      final nameToCode = await fetchStudentsForClassrooms(
        classroomCodes: classroomCodes,
      );
      if (isClosed || fetchId != _formStudentsFetchId) return;

      final sortedNames = nameToCode.keys.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      emit(
        state.copyWith(
          studentNames: sortedNames,
          studentNameToCode: nameToCode,
          formStudentsLoading: false,
        ),
      );
    } catch (e) {
      AppLogger.e('[ReportsCubit] loadAllRoomStudents failed: $e');
      if (isClosed || fetchId != _formStudentsFetchId) return;
      emit(state.copyWith(formStudentsLoading: false));
    }
  }

  /// Loads the school's vaccines into [ReportsState.vaccineNames] /
  /// [ReportsState.vaccineNameToCode], toggling
  /// [ReportsState.vaccinesLoading] around the call.
  ///
  /// Replaces the `_loadVaccines()` the immunization form ran in widget state:
  /// an API result plus its loading flag is §2.2 bucket A.
  Future<void> loadVaccines() async {
    if (isClosed) return;
    emit(state.copyWith(vaccinesLoading: true));
    try {
      final nameToCode = await fetchVaccineNameToCode();
      if (isClosed) return;
      emit(
        state.copyWith(
          vaccineNames: nameToCode.keys.toList(),
          vaccineNameToCode: nameToCode,
          vaccinesLoading: false,
        ),
      );
    } catch (e, st) {
      AppLogger.e('[ImmunizationReport] Failed to load vaccines: $e\n$st');
      if (isClosed) return;
      emit(state.copyWith(vaccinesLoading: false));
    }
  }

  /// The school name, exactly as the forms used to read it straight off
  /// storage. Returns '' when unset, matching the old expression.

  /// Loads the school's tags (names + name→TAG_* code map) and stores both in
  /// state. Tags are optional metadata so failures are swallowed.
  Future<void> loadTags() async {
    try {
      final schoolCode = await _getSchoolCodeUseCase();
      if (schoolCode.isEmpty) return;

      final nameToCode = await _getTagNameCodeMapForSchoolUseCase(
        schoolCode: schoolCode,
      );

      AppLogger.d('[ReportsCubit] Loaded tag name→code map: $nameToCode');

      if (isClosed) return;
      emit(
        state.copyWith(
          tagNames: nameToCode.keys.toList(),
          tagNameToCode: nameToCode,
        ),
      );
    } catch (e) {
      // Tags are optional; ignore failures.
      AppLogger.w('[ReportsCubit] loadTags failed (non-fatal): $e');
    }
  }

  // Forwarders to [ReportLookupFetcher] so call sites stay unchanged.
  Future<Map<String, String>> fetchVaccineNameToCode() =>
      _fetcher.fetchVaccineNameToCode();
  Future<String> resolveSchoolName() => _fetcher.resolveSchoolName();
  Future<Map<String, String>> fetchStudentsForClassrooms({
    required List<String> classroomCodes,
    bool concurrent = false,
  }) => _fetcher.fetchStudentsForClassrooms(
    classroomCodes: classroomCodes,
    concurrent: concurrent,
  );

  void setClassroomNames(
    List<String> names, {
    Map<String, String>? nameToCodeMap,
  }) {
    if (isClosed) return;
    emit(
      state.copyWith(
        classroomNames: names,
        classroomNameToCode: nameToCodeMap ?? state.classroomNameToCode,
      ),
    );
  }

  void setStudentNames(
    List<String> names, {
    Map<String, String>? nameToCodeMap,
  }) {
    if (isClosed) return;
    emit(
      state.copyWith(
        studentNames: names,
        studentNameToCode: nameToCodeMap ?? state.studentNameToCode,
      ),
    );
  }

  void setStaffNames(List<String> names, {Map<String, String>? nameToCodeMap}) {
    if (isClosed) return;
    emit(
      state.copyWith(
        staffNames: names,
        staffNameToCode: nameToCodeMap ?? state.staffNameToCode,
      ),
    );
  }

  /// Generate a report based on request params.
  /// Every call triggers a fresh API request - no caching or deduplication.

  /// Load dynamic student tags for filtering.
  /// Tags are optional; failures are silently ignored.

  /// Clear the generated report and success signal from state.
}
