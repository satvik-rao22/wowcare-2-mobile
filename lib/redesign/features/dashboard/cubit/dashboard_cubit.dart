import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/dashboard/models/models.dart';
import 'package:wowcare/redesign/features/dashboard/source/dashboard_source.dart';

part 'dashboard_state.dart';

/// M03. One cubit for all three dashboards.
///
/// The persona is passed in rather than read off a locator, so the same cubit
/// serves 3A1, 3S1 and 3P1 and a screen never branches on who is looking: it
/// draws the cards the snapshot carries.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({required DashboardSource source, required Persona persona})
    : _source = source,
      super(DashboardState(persona: persona));

  final DashboardSource _source;

  bool _isFetching = false;

  /// [isSilent] keeps the last snapshot on screen while a navigation revisit
  /// refetches behind it, so returning to the dashboard never flashes empty.
  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!isSilent) emit(state.copyWith(status: DashboardStatus.loading));

    try {
      final snapshot = await _source.load(state.persona);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: DashboardStatus.ready,
          snapshot: snapshot,
          selectedChildId: snapshot.children.isEmpty
              ? null
              : (state.selectedChildId ?? snapshot.children.first.id),
        ),
      );
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(status: DashboardStatus.failed));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => load(isSilent: true);

  /// The persona flipped under us (13d Switch Profile).
  Future<void> setPersona(Persona persona) async {
    if (state.persona == persona) return;
    emit(DashboardState(persona: persona));
    await load();
  }

  void toggleMyDay() => emit(state.copyWith(isMyDayOpen: !state.isMyDayOpen));

  void selectChild(String id) => emit(state.copyWith(selectedChildId: id));

  // --- The actions on My day ------------------------------------------------

  Future<void> signOutSelf({DateTime? at}) async {
    final day = state.snapshot.myDay;
    if (day == null) return;
    emit(state.copyWith(isWorking: true));
    final moved = await _source.signOutSelf(day: day, at: at);
    if (isClosed) return;
    emit(
      state.copyWith(
        isWorking: false,
        snapshot: state.snapshot.copyWith(myDay: moved),
      ),
    );
  }

  Future<void> transfer(String classroomName) async {
    final day = state.snapshot.myDay;
    if (day == null) return;
    emit(state.copyWith(isWorking: true));
    final moved = await _source.transfer(
      day: day,
      classroomName: classroomName,
    );
    if (isClosed) return;
    emit(
      state.copyWith(
        isWorking: false,
        snapshot: state.snapshot.copyWith(myDay: moved),
      ),
    );
  }

  Future<void> setAbsent({required bool isAbsent}) async {
    final day = state.snapshot.myDay;
    if (day == null) return;
    emit(state.copyWith(isWorking: true));
    final moved = await _source.setAbsent(day: day, isAbsent: isAbsent);
    if (isClosed) return;
    emit(
      state.copyWith(
        isWorking: false,
        snapshot: state.snapshot.copyWith(myDay: moved),
      ),
    );
  }

  // --- The actions on a guardian's student ---------------------------------

  Future<void> signOutChild() async {
    final child = state.selectedChild;
    if (child == null) return;
    emit(state.copyWith(isWorking: true));
    final moved = await _source.signOutChild(child);
    if (isClosed) return;
    emit(state.copyWith(isWorking: false, snapshot: _replace(moved)));
  }

  Future<void> setReminder({required bool isOn}) async {
    final child = state.selectedChild;
    if (child == null) return;
    final moved = await _source.setReminder(child: child, isOn: isOn);
    if (isClosed) return;
    emit(state.copyWith(snapshot: _replace(moved)));
  }

  DashboardSnapshot _replace(ChildDay child) => state.snapshot.copyWith(
    children: <ChildDay>[
      for (final existing in state.snapshot.children)
        if (existing.id == child.id) child else existing,
    ],
  );
}
