import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/family_summary_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/get_family_summary_usecase.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_page_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';

part 'family_summary_state.dart';

/// Loads the per-family billing summary list (last invoice / last payment /
/// open balance) for the Student(s) overview and Transactions lists. Search and
/// the "outstanding only" filter are applied client-side over the loaded rows.
///
/// It also owns the funnel sheet's filters. Two of them (last payment status,
/// payment method) read straight off the loaded rows. The other three
/// (classroom, tags, student status) are **student** attributes that the
/// family-summary endpoint cannot filter on — it accepts only
/// `organizationCode`, `school` and `size` — so they are resolved through the
/// student list API (`GET /api/v1/student`, which does support
/// `classroomCodes` / `tagCodes` / `status`) and the resulting student codes
/// are intersected with each row's [FamilySummaryEntity.studentCodes].
class FamilySummaryCubit extends Cubit<FamilySummaryState> {
  FamilySummaryCubit({
    required GetFamilySummaryUseCase getFamilySummary,
    required GetActiveClassroomsUseCase getActiveClassrooms,
    required GetTagNameCodeMapForSchoolUseCase getTagNameCodeMap,
    required GetStudentPageUseCase getStudentPage,
    required StorageService storage,
  })  : _getFamilySummary = getFamilySummary,
        _getActiveClassrooms = getActiveClassrooms,
        _getTagNameCodeMap = getTagNameCodeMap,
        _getStudentPage = getStudentPage,
        _storage = storage,
        super(const FamilySummaryState.initial());

  final GetFamilySummaryUseCase _getFamilySummary;
  final GetActiveClassroomsUseCase _getActiveClassrooms;
  final GetTagNameCodeMapForSchoolUseCase _getTagNameCodeMap;
  final GetStudentPageUseCase _getStudentPage;
  final StorageService _storage;

  String _schoolCode = '';

  /// Students requested when resolving a classroom/tag/status selection. The
  /// whole matching set is needed at once to intersect against the family
  /// rows, so this is deliberately larger than a UI page (the family list
  /// itself is fetched with `size: 1000` for the same reason).
  static const int _studentLookupSize = 1000;

  /// Monotonic generation for the student-code lookup, so a slower response
  /// for a superseded selection can't overwrite a newer one.
  int _filterGeneration = 0;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final org =
          (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
      final school =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      _schoolCode = school;
      final families = await _getFamilySummary(
        organizationCode: org,
        school: school,
      );
      if (isClosed) return;
      emit(state.copyWith(families: _dedupeByOwner(families), isLoading: false));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
    }
    await _loadFilterOptions();
  }

  /// Fetches the classroom and tag option lists for the funnel sheet.
  ///
  /// Deliberately non-fatal and run after the list: the family list is the
  /// screen's job, so a classroom/tag outage must leave it rendered (the
  /// sheet simply offers fewer facets) rather than replacing it with an error.
  Future<void> _loadFilterOptions() async {
    if (isClosed || state.classroomNames.isNotEmpty) return;
    try {
      final List<Classroom> classrooms =
          await _getActiveClassrooms(schoolCode: _schoolCode);
      final Map<String, String> tagNameToCode =
          await _getTagNameCodeMap(schoolCode: _schoolCode);

      final classroomNameToCode = <String, String>{
        for (final c in classrooms)
          if (c.name.trim().isNotEmpty) c.name.trim(): c.code.trim(),
      };

      if (isClosed) return;
      emit(state.copyWith(
        classroomNames: classroomNameToCode.keys.toList(),
        classroomNameToCode: classroomNameToCode,
        tagNames: tagNameToCode.keys.toList()..sort(),
        tagNameToCode: tagNameToCode,
      ));
    } catch (_) {
      // Options stay empty; the sheet hides those sections.
    }
  }

  /// The API has been observed returning the same family more than once
  /// (same owner, repeated rows) — the same family/last-name showing up
  /// several times in the list. Dedupe by owner identity (falling back to
  /// family name only if the owner code is missing) so each family renders
  /// once, keeping the first occurrence returned.
  List<FamilySummaryEntity> _dedupeByOwner(List<FamilySummaryEntity> families) {
    final seen = <String>{};
    final result = <FamilySummaryEntity>[];
    for (final f in families) {
      final key = f.ownerCode.trim().isNotEmpty
          ? '${f.ownerType.trim().toUpperCase()}:${f.ownerCode.trim()}'
          : f.familyName.trim().toLowerCase();
      if (seen.add(key)) result.add(f);
    }
    return result;
  }

  void setSearchQuery(String query) =>
      emit(state.copyWith(searchQuery: query));

  void clearSearch() => emit(state.copyWith(searchQuery: ''));

  void setShowOutstandingOnly(bool value) =>
      emit(state.copyWith(showOutstandingOnly: value));

  /// Applies every funnel selection at once.
  ///
  /// [classroomNames], [tagNames] and [status] are student attributes, so they
  /// trigger a student-list query whose codes are intersected with each row's
  /// `studentCodes`. An empty selection clears that dimension rather than
  /// matching nothing.
  Future<void> applyFilters({
    required List<String> classroomNames,
    required List<String> tagNames,
    required String? status,
  }) async {
    final gen = ++_filterGeneration;
    final normalizedStatus = (status ?? '').trim();
    final hasStudentFacet = classroomNames.isNotEmpty ||
        tagNames.isNotEmpty ||
        normalizedStatus.isNotEmpty;

    emit(state.copyWith(
      selectedClassroomNames: classroomNames,
      selectedTagNames: tagNames,
      selectedStatus: () => normalizedStatus.isEmpty ? null : normalizedStatus,
      // No student facet selected → no student-side restriction at all.
      matchingStudentCodes: () => null,
      isApplyingFilters: hasStudentFacet,
    ));

    if (!hasStudentFacet) return;

    try {
      final classroomCodes = classroomNames
          .map((n) => state.classroomNameToCode[n])
          .whereType<String>()
          .where((c) => c.isNotEmpty)
          .toList();
      final tagCodes = tagNames
          .map((n) => state.tagNameToCode[n])
          .whereType<String>()
          .where((c) => c.isNotEmpty)
          .toList();

      final page = await _getStudentPage(
        schoolCode: _schoolCode,
        status: normalizedStatus.isEmpty ? null : normalizedStatus.toUpperCase(),
        classroomCodes: classroomCodes.isEmpty ? null : classroomCodes,
        tagCodes: tagCodes.isEmpty ? null : tagCodes,
        page: 0,
        size: _studentLookupSize,
      );
      if (isClosed || gen != _filterGeneration) return;
      emit(state.copyWith(
        matchingStudentCodes: () =>
            page.items.map((s) => s.code.trim()).where((c) => c.isNotEmpty).toSet(),
        isApplyingFilters: false,
      ));
    } catch (e) {
      if (isClosed || gen != _filterGeneration) return;
      // Leave the restriction unset so the list stays usable, and surface why.
      emit(state.copyWith(
        isApplyingFilters: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }

  /// Drops every funnel selection, leaving search and the outstanding toggle.
  void clearFilters() {
    _filterGeneration++;
    emit(state.copyWith(
      selectedClassroomNames: const <String>[],
      selectedTagNames: const <String>[],
      selectedStatus: () => null,
      matchingStudentCodes: () => null,
      isApplyingFilters: false,
    ));
  }
}
