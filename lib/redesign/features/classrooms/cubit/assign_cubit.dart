import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/source/classrooms_source.dart';

part 'assign_state.dart';

/// Assigning students (7g) and staff (7h): pick, then review, then submit.
///
/// One cubit for both, because the two flows post the same way — a list of
/// codes against a classroom, applied immediately. Nothing here books a
/// future-dated move: that is on the module's costly list.
class AssignCubit extends Cubit<AssignState> {
  AssignCubit({
    required ClassroomsSource source,
    required String classroomId,
    required AssignKind kind,
  }) : _source = source,
       super(AssignState(classroomId: classroomId, kind: kind));

  final ClassroomsSource _source;

  bool _isFetching = false;

  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!isSilent) emit(state.copyWith(status: AssignStatus.loading));

    try {
      final detail = await _source.loadClassroom(state.classroomId);
      final candidates = await _source.loadCandidates(
        classroomId: state.classroomId,
        kind: state.kind,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AssignStatus.ready,
          classroom: detail.summary,
          candidates: candidates,
        ),
      );
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(status: AssignStatus.failed));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => load(isSilent: true);

  void search(String query) => emit(state.copyWith(query: query));

  void selectGroup(String? group) =>
      emit(state.copyWith(group: group, clearGroup: group == null));

  void toggle(String id) {
    final next = <String>{...state.pickedIds};
    if (!next.remove(id)) next.add(id);
    emit(state.copyWith(pickedIds: next));
  }

  void toReview() {
    if (state.pickedIds.isEmpty) return;
    emit(state.copyWith(step: AssignStep.review));
  }

  void toPick() => emit(state.copyWith(step: AssignStep.pick));

  Future<void> submit() async {
    if (state.pickedIds.isEmpty || state.status == AssignStatus.submitting) {
      return;
    }
    emit(state.copyWith(status: AssignStatus.submitting));

    try {
      await _source.assign(
        classroomId: state.classroomId,
        kind: state.kind,
        ids: state.pickedIds.toList(),
      );
      if (!isClosed) emit(state.copyWith(status: AssignStatus.done));
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(status: AssignStatus.failed));
    }
  }
}
