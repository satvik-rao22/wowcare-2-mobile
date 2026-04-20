import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
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
  }) async {
    if (state.isLoading) return;
    // If we already have classrooms for the same filter mode,
    // avoid reloading unless explicitly forced.
    if (!force &&
        state.classrooms.isNotEmpty &&
        state.onlyTypeClassroom == onlyTypeClassroom) {
      return;
    }

    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: null,
        onlyTypeClassroom: onlyTypeClassroom,
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
      final visibleClassrooms = filterSelectableClassrooms(classrooms);

      if (isClosed) return;

      emit(
        state.copyWith(
          classrooms: visibleClassrooms,
          isLoading: false,
          onlyTypeClassroom: onlyTypeClassroom,
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

