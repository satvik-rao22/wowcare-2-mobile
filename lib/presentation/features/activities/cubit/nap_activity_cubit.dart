import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/activity/usecases/get_nap_start_students_usecase.dart';

part 'nap_activity_state.dart';

/// ViewModel for the Nap screen's one non-shared concern —
/// [GetNapStartStudentsUseCase], used to infer nap-end vs nap-start from the
/// selected students' current napping status. Create/update/approve/reject
/// still go through [ActivityEditorCubit] directly (provided alongside this
/// cubit); this stays separate rather than folding into that shared facade
/// since no other screen needs it.
class NapActivityCubit extends Cubit<NapActivityState> {
  NapActivityCubit({
    required GetNapStartStudentsUseCase getNapStartStudentsUseCase,
  })  : _getNapStartStudentsUseCase = getNapStartStudentsUseCase,
        super(const NapActivityState());

  final GetNapStartStudentsUseCase _getNapStartStudentsUseCase;

  Future<List<String>> getNapStartStudents({required String classroomCode}) =>
      _getNapStartStudentsUseCase(classroomCode: classroomCode);
}
