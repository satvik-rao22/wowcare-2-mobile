import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/source/classrooms_source.dart';

part 'create_classroom_state.dart';

/// The create form. The frames stop at "Create a classroom" on 7a and 7b, so
/// this is the smallest step that key can lead to: the four fields the
/// classroom record needs, validated, then back to the floor.
class CreateClassroomCubit extends Cubit<CreateClassroomState> {
  CreateClassroomCubit({required ClassroomsSource source})
    : _source = source,
      super(const CreateClassroomState());

  final ClassroomsSource _source;

  void setName(String name) =>
      emit(state.copyWith(draft: state.draft.copyWith(name: name)).cleared());

  void setAgeFrom(String value) => emit(
    state
        .copyWith(
          draft: value.trim().isEmpty
              ? state.draft.copyWith(clearAgeFrom: true)
              : state.draft.copyWith(ageFromMonths: int.tryParse(value.trim())),
        )
        .cleared(),
  );

  void setAgeTo(String value) => emit(
    state
        .copyWith(
          draft: value.trim().isEmpty
              ? state.draft.copyWith(clearAgeTo: true)
              : state.draft.copyWith(ageToMonths: int.tryParse(value.trim())),
        )
        .cleared(),
  );

  void setCapacity(String value) => emit(
    state
        .copyWith(
          draft: value.trim().isEmpty
              ? state.draft.copyWith(clearCapacity: true)
              : state.draft.copyWith(capacity: int.tryParse(value.trim())),
        )
        .cleared(),
  );

  void setStudentsPerStaff(String value) => emit(
    state
        .copyWith(
          draft: value.trim().isEmpty
              ? state.draft.copyWith(clearStudentsPerStaff: true)
              : state.draft.copyWith(
                  studentsPerStaff: int.tryParse(value.trim()),
                ),
        )
        .cleared(),
  );

  /// Validates, then creates. The created classroom lands in
  /// [CreateClassroomState.created] so the screen can name it in its toast.
  Future<void> submit() async {
    if (state.status == CreateClassroomStatus.saving) return;

    final errors = _validate(state.draft);
    if (errors.isNotEmpty) {
      emit(state.copyWith(errors: errors));
      return;
    }

    emit(
      state.copyWith(
        status: CreateClassroomStatus.saving,
        errors: const <ClassroomField, String>{},
      ),
    );

    try {
      final created = await _source.createClassroom(state.draft);
      if (!isClosed) {
        emit(
          state.copyWith(status: CreateClassroomStatus.saved, created: created),
        );
      }
    } on Exception catch (_) {
      if (!isClosed) {
        emit(state.copyWith(status: CreateClassroomStatus.failed));
      }
    }
  }

  static Map<ClassroomField, String> _validate(ClassroomDraft draft) {
    final errors = <ClassroomField, String>{};

    if (draft.name.trim().isEmpty) {
      errors[ClassroomField.name] = ClassroomsStrings.nameRequired;
    }
    final capacity = draft.capacity;
    if (capacity == null || capacity < 1) {
      errors[ClassroomField.capacity] = ClassroomsStrings.capacityInvalid;
    }
    final ratio = draft.studentsPerStaff;
    if (ratio == null || ratio < 1) {
      errors[ClassroomField.studentsPerStaff] = ClassroomsStrings.ratioInvalid;
    }
    final from = draft.ageFromMonths;
    final to = draft.ageToMonths;
    if (from != null && to != null && to <= from) {
      errors[ClassroomField.ageTo] = ClassroomsStrings.ageInvalid;
    }
    return errors;
  }
}
