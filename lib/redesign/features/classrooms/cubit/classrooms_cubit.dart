import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/source/classrooms_source.dart';

part 'classrooms_state.dart';

/// M07's list (7a), its empty floor (7b) and the list's own edge states (7j).
///
/// Search and the three chips are held here rather than in the screen, so the
/// counts a chip carries and the rows under it can never disagree.
class ClassroomsCubit extends Cubit<ClassroomsState> {
  ClassroomsCubit({required ClassroomsSource source})
    : _source = source,
      super(const ClassroomsState());

  final ClassroomsSource _source;

  bool _isFetching = false;

  /// [isSilent] keeps the floor on screen while a revisit refetches behind it,
  /// so coming back from a classroom never flashes empty.
  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!isSilent) emit(state.copyWith(status: ClassroomsStatus.loading));

    try {
      final board = await _source.loadBoard();
      if (isClosed) return;
      emit(state.copyWith(status: ClassroomsStatus.ready, board: board));
    } on Exception catch (_) {
      if (isClosed) return;
      // A floor we already have stays up and says how old it is; with nothing
      // to show, the screen fails outright.
      emit(
        state.copyWith(
          status: state.board.isEmpty
              ? ClassroomsStatus.failed
              : ClassroomsStatus.cached,
        ),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => load(isSilent: true);

  void search(String query) => emit(state.copyWith(query: query));

  void clearSearch() => emit(state.copyWith(query: ''));

  void selectSegment(ClassroomSegment segment) =>
      emit(state.copyWith(segment: segment));
}
