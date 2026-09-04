part of 'sign_attendance_cubit.dart';

/// What the form can be doing.
enum SignStatus { loading, editing, submitting, done, failed }

@immutable
class SignAttendanceState extends Equatable {
  const SignAttendanceState({
    required this.kind,
    required this.audience,
    required this.at,
    this.ids = const <String>[],
    this.status = SignStatus.loading,
    this.people = const <AttendanceRecord>[],
    this.isInsideGeofence = true,
    this.isAcknowledged = false,
  });

  final SignKind kind;
  final AttendanceAudience audience;

  /// The two fields, as one instant: the Date field sets its day, the Time
  /// field sets its clock.
  final DateTime at;

  /// Who the list handed over, in the order they were picked.
  final List<String> ids;

  final SignStatus status;
  final List<AttendanceRecord> people;

  /// The device is on site. Only a sign-in or sign-out taken here is gated
  /// on it; the school's own rule, not a new one.
  final bool isInsideGeofence;

  /// The unexpected-sign-in dialog has been answered.
  final bool isAcknowledged;

  bool get isLoading => status == SignStatus.loading;
  bool get isSubmitting => status == SignStatus.submitting;
  bool get isFailed => status == SignStatus.failed;

  /// Nobody was handed over, or every tile was removed.
  bool get isEmpty => !isLoading && people.isEmpty;

  /// Who on this form is not expected today. Signing them in is an override
  /// and is recorded as one.
  List<AttendanceRecord> get unexpected => <AttendanceRecord>[
    for (final person in people)
      if (!person.isExpectedToday) person,
  ];

  /// Only a sign-in asks: signing somebody out who is already in the
  /// building is never a surprise.
  bool get needsAcknowledgement =>
      kind.isSignIn && unexpected.isNotEmpty && !isAcknowledged;

  bool get canSubmit =>
      !isLoading &&
      !isSubmitting &&
      people.isNotEmpty &&
      isInsideGeofence &&
      !needsAcknowledgement;

  SignAttendanceState copyWith({
    SignStatus? status,
    List<AttendanceRecord>? people,
    List<String>? ids,
    DateTime? at,
    bool? isInsideGeofence,
    bool? isAcknowledged,
  }) => SignAttendanceState(
    kind: kind,
    audience: audience,
    at: at ?? this.at,
    ids: ids ?? this.ids,
    status: status ?? this.status,
    people: people ?? this.people,
    isInsideGeofence: isInsideGeofence ?? this.isInsideGeofence,
    isAcknowledged: isAcknowledged ?? this.isAcknowledged,
  );

  @override
  List<Object?> get props => <Object?>[
    kind,
    audience,
    at,
    ids,
    status,
    people,
    isInsideGeofence,
    isAcknowledged,
  ];
}
