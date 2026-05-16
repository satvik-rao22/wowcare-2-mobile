import 'package:bloc/bloc.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/student_classroom/entities/student_classroom_item.dart';
import '../../../../domain/features/student_classroom/usecases/get_student_classroom_list_usecase.dart';
import 'classroom_students_state.dart';

class ClassroomStudentsCubit extends Cubit<ClassroomStudentsState> {
  ClassroomStudentsCubit({
    required GetStudentClassroomListUseCase getStudentClassroomListUseCase,
    required StorageService storageService,
  }) : _getStudentClassroomListUseCase = getStudentClassroomListUseCase,
       _storageService = storageService,
       super(const ClassroomStudentsState.initial());

  final GetStudentClassroomListUseCase _getStudentClassroomListUseCase;
  final StorageService _storageService;

  String? _lastSuccessfulStudentListKey;

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
        refresh: false,
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
          errorMessage: e.toString(),
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
          errorMessage: e.toString(),
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
