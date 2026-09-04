import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/util/api_error_handler.dart';
import '../../../../domain/features/student/usecases/get_student_tag_names_usecase.dart';
import '../../../../domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import '../../../../domain/features/student/usecases/get_tag_names_for_school_usecase.dart';
import '../../../../domain/features/student/usecases/update_student_tags_usecase.dart';

part 'student_tags_state.dart';

/// Reads + mutation for a student's tags.
///
/// Screens route every tag read/write through this cubit → use case →
/// repository so no view depends on [StudentRepository] directly.
class StudentTagsCubit extends Cubit<StudentTagsState> {
  StudentTagsCubit({
    required GetStudentTagNamesUseCase getStudentTagNamesUseCase,
    required GetTagNamesForSchoolUseCase getTagNamesForSchoolUseCase,
    required GetTagNameCodeMapForSchoolUseCase getTagNameCodeMapForSchoolUseCase,
    required UpdateStudentTagsUseCase updateStudentTagsUseCase,
  })  : _getStudentTagNamesUseCase = getStudentTagNamesUseCase,
        _getTagNamesForSchoolUseCase = getTagNamesForSchoolUseCase,
        _getTagNameCodeMapForSchoolUseCase = getTagNameCodeMapForSchoolUseCase,
        _updateStudentTagsUseCase = updateStudentTagsUseCase,
        super(const StudentTagsState.initial());

  final GetStudentTagNamesUseCase _getStudentTagNamesUseCase;
  final GetTagNamesForSchoolUseCase _getTagNamesForSchoolUseCase;
  final GetTagNameCodeMapForSchoolUseCase _getTagNameCodeMapForSchoolUseCase;
  final UpdateStudentTagsUseCase _updateStudentTagsUseCase;

  /// Thin Future-based read of a student's tag names for callers that drive
  /// their own async flow (e.g. the lazy tags loader).
  Future<List<String>> fetchStudentTagNames(String studentCode) {
    return _getStudentTagNamesUseCase(studentCode: studentCode);
  }

  /// Thin Future-based read of a school's available tag names.
  Future<List<String>> fetchTagNamesForSchool(String schoolCode) {
    return _getTagNamesForSchoolUseCase(schoolCode: schoolCode);
  }

  /// Thin Future-based read of a school's tag name → code mapping.
  Future<Map<String, String>> fetchTagNameCodeMap(String schoolCode) {
    return _getTagNameCodeMapForSchoolUseCase(schoolCode: schoolCode);
  }

  // --- Tags edit-sheet state (load + selection + save) ---

  /// Show the sheet's loader immediately (called sync from the sheet's initState,
  /// before the school code is resolved) so the first frame isn't the empty form.
  void beginLoading() {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));
  }

  /// Load the school's available tags + name→code map and seed the selection
  /// from [initialTagNames], dropping any that no longer exist for the school.
  Future<void> load({
    required String schoolCode,
    required List<String> initialTagNames,
  }) async {
    if (isClosed) return;
    emit(state.copyWith(
      isLoading: true,
      errorMessage: null,
      schoolCode: schoolCode,
    ));
    try {
      final names = await _getTagNamesForSchoolUseCase(schoolCode: schoolCode);
      final map = await _getTagNameCodeMapForSchoolUseCase(
        schoolCode: schoolCode,
      );
      if (isClosed) return;
      final selected =
          initialTagNames.where((t) => names.contains(t)).toList();
      emit(state.copyWith(
        availableTagNames: names,
        tagNameToCode: map,
        selectedTags: selected,
        isLoading: false,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }

  void setSelectedTags(List<String> tags) {
    emit(state.copyWith(selectedTags: tags));
  }

  /// Persist the current selection: resolve the selected names to codes against
  /// the loaded map and route through [updateTags] (single-flight +
  /// `mutationInProgress`). Returns the success message.
  Future<String> saveTags({required String studentCode}) {
    final tagCodes = state.selectedTags
        .map((n) => state.tagNameToCode[n])
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toList();
    return updateTags(
      studentCode: studentCode,
      schoolCode: state.schoolCode,
      tagCodes: tagCodes,
    );
  }

  /// In-flight mutations keyed by `action:code`. A second identical call while
  /// the first is still running returns the SAME future instead of issuing a
  /// duplicate request — single-flight independent of any UI button-disabling.
  final Map<String, Future<Object?>> _inFlightMutations = {};

  Future<T> _singleFlightMutation<T>(
    String key,
    Future<T> Function() operation,
  ) {
    final existing = _inFlightMutations[key];
    if (existing != null) return existing as Future<T>;
    final future = operation();
    _inFlightMutations[key] = future;
    // Clear the in-flight entry on completion. `whenComplete` returns a new
    // future that mirrors any error; ignore it so a rethrown mutation error
    // surfaces only through the caller's `future` and isn't double-reported as
    // an unhandled async error.
    future.whenComplete(() => _inFlightMutations.remove(key)).ignore();
    return future;
  }

  Future<String> updateTags({
    required String studentCode,
    required String schoolCode,
    required List<String> tagCodes,
  }) {
    return _singleFlightMutation<String>('updateTags:$studentCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _updateStudentTagsUseCase(
          studentCode: studentCode,
          schoolCode: schoolCode,
          tagCodes: tagCodes,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }
}
