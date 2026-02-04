import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/classroom/entities/classroom.dart';
import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';

part 'classroom_state.dart';

class ClassroomCubit extends Cubit<ClassroomState> {
  ClassroomCubit({
    required GetActiveClassroomsUseCase getActiveClassroomsUseCase,
  })  : _getActiveClassroomsUseCase = getActiveClassroomsUseCase,
        super(const ClassroomState.initial());

  final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;

  Future<void> loadActiveClassrooms({bool force = false}) async {
    if (state.isLoading) return;
    if (!force && state.classrooms.isNotEmpty) return;

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // TEMP: Always use default school code constant, ignore stored prefs.
      final schoolCode = StorageKeys.defaultSchoolCode;

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

