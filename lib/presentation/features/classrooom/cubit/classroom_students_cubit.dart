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
  })  : _getStudentClassroomListUseCase = getStudentClassroomListUseCase,
        _storageService = storageService,
        super(const ClassroomStudentsState.initial());

  final GetStudentClassroomListUseCase _getStudentClassroomListUseCase;
  final StorageService _storageService;

  Future<void> loadInitial({
    required String classroomCode,
    String? search,
    List<String>? studentCodes,
    List<String>? status,
    List<String>? tagCodes,
    List<String>? studentCodes,
  }) async {
    if (state.isLoading) return;

    emit(
      state.copyWith(
        isLoading: true,
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
        studentCodes: studentCodes,
        tagCodes: tagCodes,
        refresh: false,
      );

      if (isClosed) return;
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
    List<String>? studentCodes,
  }) async {
    if (state.isRefreshing) return;

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
        studentCodes: studentCodes,
        tagCodes: tagCodes,
        refresh: true,
      );

      if (isClosed) return;
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

