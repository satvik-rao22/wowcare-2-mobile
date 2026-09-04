import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/attendance/models/attendance_audience.dart';

/// Which of the two forms is open. There is no create-attendance endpoint: a
/// record is made by signing somebody in, and closed by signing them out.
enum SignKind {
  signIn,
  signOut;

  bool get isSignIn => this == SignKind.signIn;
}

/// What the roster hands the form: who, and which way round.
///
/// Typed rather than `state.extra as Map`, and carried on the route so a
/// deep link that arrives with nothing still opens an honest empty form.
@immutable
class SignAttendanceArgs extends Equatable {
  const SignAttendanceArgs({
    required this.kind,
    required this.audience,
    this.ids = const <String>[],
  });

  final SignKind kind;
  final AttendanceAudience audience;

  /// The people picked on the list, in the order they were picked.
  final List<String> ids;

  @override
  List<Object?> get props => <Object?>[kind, audience, ids];
}
