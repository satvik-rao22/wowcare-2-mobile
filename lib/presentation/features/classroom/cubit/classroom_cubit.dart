import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
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

  Future<void> loadActiveClassrooms({bool force = false}) async {
    if (state.isLoading) return;
    if (!force && state.classrooms.isNotEmpty) return;

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // Take school from login-context API (saved in storage) only.
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';

      final classrooms = await _getActiveClassroomsUseCase(
        schoolCode: schoolCode,
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          classrooms: classrooms,
          isLoading: false,
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

