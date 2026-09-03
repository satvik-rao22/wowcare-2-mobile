import 'package:bloc/bloc.dart';
import 'package:wowcare/core/util/api_error_handler.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/activity/usecases/get_nap_start_students_usecase.dart';
import '../../../../domain/features/student_classroom/entities/student_classroom_item.dart';
import '../../../../domain/features/student_classroom/usecases/get_student_classroom_list_usecase.dart';
import 'classroom_students_state.dart';

class ClassroomStudentsCubit extends Cubit<ClassroomStudentsState> {
  ClassroomStudentsCubit({
    required GetStudentClassroomListUseCase getStudentClassroomListUseCase,
    required GetNapStartStudentsUseCase getNapStartStudentsUseCase,
    required StorageService storageService,
  }) : _getStudentClassroomListUseCase = getStudentClassroomListUseCase,
       _getNapStartStudentsUseCase = getNapStartStudentsUseCase,
       _storageService = storageService,
       super(const ClassroomStudentsState.initial());

  final GetStudentClassroomListUseCase _getStudentClassroomListUseCase;
  final GetNapStartStudentsUseCase _getNapStartStudentsUseCase;
  final StorageService _storageService;

  String? _lastSuccessfulStudentListKey;

  /// Guards against a slow, superseded nap-codes fetch clobbering a newer
  /// one's result (e.g. rapid classroom switching).
  int _napCodesFetchToken = 0;

  /// Fetches which students in [classroomCode] are currently on a nap.
  /// [refresh] is accepted for call-site symmetry with [loadInitial]/
  /// [refresh] but — matching this endpoint's original View-side
  /// behaviour — isn't currently forwarded to the use case (no
  /// cache-bypass parameter exists on it).
  Future<void> loadNapStartStudentCodes({
    required String classroomCode,
    required bool refresh,
  }) async {
    final code = classroomCode.trim();
    if (code.isEmpty) return;

    final token = ++_napCodesFetchToken;
    if (!isClosed) emit(state.copyWith(napCodesLoading: true));

    try {
      final codes = await _getNapStartStudentsUseCase(classroomCode: code);
      final normalized = codes
          .map((e) => e.trim().toUpperCase())
          .where((e) => e.isNotEmpty)
          .toSet();

      if (isClosed || token != _napCodesFetchToken) return;
      emit(state.copyWith(nappingStudentCodes: normalized));
    } catch (_) {
      // Keep the existing set on failure to avoid flicker.
      if (isClosed || token != _napCodesFetchToken) return;
    } finally {
      if (!isClosed && token == _napCodesFetchToken) {
        emit(state.copyWith(napCodesLoading: false));
      }
    }
  }

  static String studentListRequestKey({
    required String classroomCode,
    String? search,
    List<String>? studentCodes,
    List<String>? status,
    List<String>? tagCodes,
  }) {
    final sc =
        List<String>.from(studentCodes ?? const <String>[])
            .map((e) => e.trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();
    final st =
        List<String>.from(status ?? const <String>[])
            .map((e) => e.trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();
    final tg = List<String>.from(
      tagCodes ?? const <String>[],
    ).map((e) => e.trim()).where((e) => e.isNotEmpty).toList()..sort();
    return [
      classroomCode.trim(),
      's=${(search ?? '').trim().toLowerCase()}',
      'sc=${sc.join(',')}',
      'st=${st.join(',')}',
      'tg=${tg.join(',')}',
    ].join('|');
  }

  Future<void> loadInitial({
    required String classroomCode,
    String? search,
    List<String>? studentCodes,
    List<String>? status,
    List<String>? tagCodes,
    // When true, bypasses the repository's roster cache even though this
    // still goes through the "clear immediately on a different request" UX
    // below — used when switching to a classroom whose cached roster may be
    // stale (e.g. a student was just transferred into it elsewhere in the
    // app), as opposed to a plain first-mount load where a recent cache hit
    // is fine.
    bool forceRefresh = false,
  }) async {
    if (state.isLoading) return;

    final key = studentListRequestKey(
      classroomCode: classroomCode,
      search: search,
      studentCodes: studentCodes,
      status: status,
      tagCodes: tagCodes,
    );
    final preserve =
        key == _lastSuccessfulStudentListKey && state.students.isNotEmpty;

    emit(
      state.copyWith(
        students: preserve ? state.students : [],
        isLoading: !preserve,
        isRefreshing: false,
        errorMessage: null,
        lastClassroomCode: classroomCode,
      ),
    );

    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      final items = await _getStudentClassroomListUseCase(
        schoolCode: schoolCode,
        classroomCode: classroomCode,
        search: search,
        studentCodes: studentCodes,
        status: status,
        tagCodes: tagCodes,
        refresh: forceRefresh,
      );

      if (isClosed) return;
      _lastSuccessfulStudentListKey = key;
      emit(
        state.copyWith(
          students: items,
          isLoading: false,
          isRefreshing: false,
          errorMessage: null,
          lastClassroomCode: classroomCode,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
          lastClassroomCode: classroomCode,
        ),
      );
    }
  }

  Future<void> refresh({
    required String classroomCode,
    String? search,
    List<String>? studentCodes,
    List<String>? status,
    List<String>? tagCodes,
  }) async {
    if (state.isRefreshing) return;

    final key = studentListRequestKey(
      classroomCode: classroomCode,
      search: search,
      studentCodes: studentCodes,
      status: status,
      tagCodes: tagCodes,
    );

    emit(
      state.copyWith(
        isRefreshing: true,
        errorMessage: null,
        lastClassroomCode: classroomCode,
      ),
    );

    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      final items = await _getStudentClassroomListUseCase(
        schoolCode: schoolCode,
        classroomCode: classroomCode,
        search: search,
        studentCodes: studentCodes,
        status: status,
        tagCodes: tagCodes,
        refresh: true,
      );

      if (isClosed) return;
      _lastSuccessfulStudentListKey = key;
      emit(
        state.copyWith(
          students: items,
          isLoading: false,
          isRefreshing: false,
          errorMessage: null,
          lastClassroomCode: classroomCode,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isRefreshing: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
          lastClassroomCode: classroomCode,
        ),
      );
    }
  }

  static List<StudentClassroomItem> applyClientFilters(
    List<StudentClassroomItem> students, {
    bool presentOnly = false,
    bool nappingOnly = false,
    String? searchText,
  }) {
    final q = (searchText ?? '').trim().toLowerCase();

    return students.where((s) {
      if (presentOnly && !s.signedIn) return false;
      if (nappingOnly && !s.nap) return false;
      if (q.isNotEmpty && !s.fullName.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }
}
