import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/source/attendance_source.dart';

part 'sign_attendance_state.dart';

/// The Sign In and Sign Out forms, which are the same form twice.
///
/// Two fields, Date and Time, over the tiles of whoever was picked. Nothing
/// is behind a disclosure and nothing else is typed: `signedInBy` and
/// `signedOutBy` come from the staff or guardian code on the call, never from
/// the screen.
///
/// Two gates stand in front of the key. The device has to be on site, and a
/// sign-in that includes somebody who is not expected today has to be
/// acknowledged first, which is the app's own unexpected-sign-in dialog
/// written into the form.
class SignAttendanceCubit extends Cubit<SignAttendanceState> {
  SignAttendanceCubit({
    required AttendanceSource source,
    required SignAttendanceArgs args,
    required Persona persona,
    required DateTime today,
  }) : _source = source,
       _persona = persona,
       super(
         SignAttendanceState(
           kind: args.kind,
           audience: args.audience,
           ids: args.ids,
           at: today,
         ),
       );

  final AttendanceSource _source;
  final Persona _persona;

  bool _isFetching = false;

  /// Reads the day back so the tiles carry the real record: a sign-in has to
  /// know who is not expected today before it can ask about them.
  Future<void> load() async {
    if (_isFetching) return;
    _isFetching = true;
    emit(state.copyWith(status: SignStatus.loading));

    try {
      final result = await _source.loadDay(
        persona: _persona,
        audience: state.audience,
        day: state.at,
      );
      final inside = await _source.isInsideGeofence();
      if (isClosed) return;

      final snapshot = switch (result) {
        AttendanceDayLoaded(:final snapshot) => snapshot,
        AttendanceDayOffline(:final snapshot) => snapshot,
      };

      emit(
        state.copyWith(
          status: SignStatus.editing,
          isInsideGeofence: inside,
          people: <AttendanceRecord>[
            for (final id in state.ids)
              if (snapshot.rows.any((r) => r.id == id))
                snapshot.rows.firstWhere((r) => r.id == id),
          ],
        ),
      );
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(status: SignStatus.failed));
    } finally {
      _isFetching = false;
    }
  }

  /// A tile's cross. The last one cannot be removed: an empty form has
  /// nothing to submit.
  void removePerson(String id) {
    if (state.people.length <= 1) return;
    emit(
      state.copyWith(
        people: <AttendanceRecord>[
          for (final person in state.people)
            if (person.id != id) person,
        ],
        ids: <String>[
          for (final each in state.ids)
            if (each != id) each,
        ],
        isAcknowledged: false,
      ),
    );
  }

  void setDate(DateTime date) => emit(
    state.copyWith(
      at: DateTime(
        date.year,
        date.month,
        date.day,
        state.at.hour,
        state.at.minute,
      ),
    ),
  );

  void setTime({required int hour, required int minute}) => emit(
    state.copyWith(
      at: DateTime(state.at.year, state.at.month, state.at.day, hour, minute),
    ),
  );

  void acknowledgeUnexpected() => emit(state.copyWith(isAcknowledged: true));

  /// Returns whether it went through, so the screen knows which toast to put
  /// up and whether to leave.
  Future<bool> submit() async {
    if (!state.canSubmit) return false;
    emit(state.copyWith(status: SignStatus.submitting));

    try {
      final ids = <String>[for (final person in state.people) person.id];
      if (state.kind.isSignIn) {
        await _source.signIn(ids: ids, audience: state.audience, at: state.at);
      } else {
        await _source.signOut(ids: ids, audience: state.audience, at: state.at);
      }
      if (!isClosed) emit(state.copyWith(status: SignStatus.done));
      return true;
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(status: SignStatus.failed));
      return false;
    }
  }
}
