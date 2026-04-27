import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/util/attendance_classroom_scope.dart';
import '../../../../core/util/classroom_visibility.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/classroom/entities/classroom.dart';
import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';

part 'classroom_state.dart';

class ClassroomCubit extends Cubit<ClassroomState> {
  ClassroomCubit({
    required GetActiveClassroomsUseCase getActiveClassroomsUseCase,
    required StorageService storageService,
  })  : _getActiveClassroomsUseCase = getActiveClassroomsUseCase,
        _storageService = storageService,
        super(const ClassroomState.initial());

  final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  final StorageService _storageService;

  Future<void> loadActiveClassrooms({
    bool force = false,
    bool onlyTypeClassroom = true,
    bool applyAttendanceStaffScope = false,
  }) async {
    if (state.isLoading) return;
    // If we already have classrooms for the same filter mode,
    // avoid reloading unless explicitly forced.
    if (!force &&
        state.classrooms.isNotEmpty &&
        state.onlyTypeClassroom == onlyTypeClassroom &&
        state.applyAttendanceStaffScope == applyAttendanceStaffScope) {
      return;
    }

    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: null,
        onlyTypeClassroom: onlyTypeClassroom,
        applyAttendanceStaffScope: applyAttendanceStaffScope,
      ),
    );

    try {
      // Take school from login-context API (saved in storage) only.
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';

      final classrooms = await _getActiveClassroomsUseCase(
        schoolCode: schoolCode,
        onlyTypeClassroom: onlyTypeClassroom,
      );
      var visibleClassrooms = filterSelectableClassrooms(classrooms);

      if (applyAttendanceStaffScope) {
        final shouldScope = await isAttendanceScopedStaffPersona(
          storage: _storageService,
        );
        if (shouldScope) {
          final allowedCodes = await resolveAttendanceAllowedClassroomCodes(
            storage: _storageService,
          );
          final allowedSet = allowedCodes.map((e) => e.trim()).toSet();
          visibleClassrooms = visibleClassrooms
              .where((c) => allowedSet.contains(c.code.trim()))
              .toList(growable: false);
        }
      }

      if (isClosed) return;

      emit(
        state.copyWith(
          classrooms: visibleClassrooms,
          isLoading: false,
          onlyTypeClassroom: onlyTypeClassroom,
          applyAttendanceStaffScope: applyAttendanceStaffScope,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}

