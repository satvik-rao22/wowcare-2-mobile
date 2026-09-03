import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/features/auth/models/models.dart';
import 'package:wowcare/redesign/features/auth/source/auth_source.dart';

part 'kiosk_family_state.dart';

/// 2c. Which of a guardian's students are arriving, or leaving.
///
/// Opens with everyone the chosen direction can actually move already ticked,
/// because the common case at the door is the whole family at once. A student
/// already the right way round is drawn but cannot be picked: signing in
/// somebody who is Signed In records nothing.
class KioskFamilyCubit extends Cubit<KioskFamilyState> {
  KioskFamilyCubit({required AuthSource source, required KioskFamilyArgs args})
    : _source = source,
      super(
        KioskFamilyState(
          result: args.result,
          isSigningIn: args.isSigningIn,
          selected: _movable(args.result, isSigningIn: args.isSigningIn)
              .map((s) => s.id)
              .toSet(),
        ),
      );

  final AuthSource _source;

  bool _isFetching = false;

  void toggle(KioskStudent student) {
    if (!state.canMove(student)) return;
    final selected = Set<String>.from(state.selected);
    if (!selected.remove(student.id)) selected.add(student.id);
    emit(state.copyWith(selected: selected));
  }

  /// Flipping direction re-ticks whoever the new direction can move.
  void setDirection({required bool isSigningIn}) {
    if (state.isSigningIn == isSigningIn) return;
    emit(
      state.copyWith(
        isSigningIn: isSigningIn,
        selected: _movable(state.result, isSigningIn: isSigningIn)
            .map((s) => s.id)
            .toSet(),
      ),
    );
  }

  Future<void> record({required bool isSigningIn}) async {
    if (_isFetching || state.selected.isEmpty) return;
    _isFetching = true;
    emit(state.copyWith(status: KioskFamilyStatus.recording));

    final moved = await _source.recordStudents(
      result: state.result,
      studentIds: state.selected,
      isSigningIn: isSigningIn,
    );
    _isFetching = false;
    if (isClosed) return;

    emit(
      state.copyWith(
        status: KioskFamilyStatus.recorded,
        result: moved,
        isSigningIn: isSigningIn,
        recordedCount: state.selected.length,
        selected: const <String>{},
      ),
    );
  }

  static List<KioskStudent> _movable(
    KioskPinResult result, {
    required bool isSigningIn,
  }) => isSigningIn ? result.notSignedInStudents : result.signedInStudents;
}
