part of 'session_cubit.dart';

enum SessionStatus { signedOut, signedIn, kiosk }

/// The signed-in account, as much of it as the shell needs.
@immutable
class SessionUser extends Equatable {
  const SessionUser({
    required this.id,
    required this.fullName,
    required this.firstName,
    required this.initials,
    required this.designation,
    required this.organizationName,
    required this.schoolName,
    required this.personas,
    this.classroomName,
    this.email = '',
  });

  final String id;
  final String fullName;
  final String firstName;
  final String initials;

  /// Director, Lead Teacher, Guardian: the role label under the name.
  final String designation;
  final String organizationName;
  final String schoolName;

  /// A staff member's own classroom, when they have one.
  final String? classroomName;
  final String email;

  /// Every role this account holds at this school. Switch Profile exists only
  /// when there is more than one.
  final List<Persona> personas;

  bool get canSwitchPersona => personas.length > 1;

  SessionUser copyWith({String? organizationName, String? schoolName}) =>
      SessionUser(
        id: id,
        fullName: fullName,
        firstName: firstName,
        initials: initials,
        designation: designation,
        organizationName: organizationName ?? this.organizationName,
        schoolName: schoolName ?? this.schoolName,
        personas: personas,
        classroomName: classroomName,
        email: email,
      );

  @override
  List<Object?> get props => [
    id,
    fullName,
    firstName,
    initials,
    designation,
    organizationName,
    schoolName,
    classroomName,
    email,
    personas,
  ];
}

@immutable
class SessionState extends Equatable {
  const SessionState({
    this.status = SessionStatus.signedOut,
    this.user,
    this.persona = Persona.admin,
  });

  final SessionStatus status;
  final SessionUser? user;
  final Persona persona;

  bool get isSignedIn => status != SessionStatus.signedOut;
  bool get isKiosk => status == SessionStatus.kiosk;
  bool get isAdmin => persona == Persona.admin;
  bool get isStaff => persona == Persona.staff;
  bool get isGuardian => persona == Persona.guardian;

  SessionState copyWith({
    SessionStatus? status,
    SessionUser? user,
    Persona? persona,
  }) => SessionState(
    status: status ?? this.status,
    user: user ?? this.user,
    persona: persona ?? this.persona,
  );

  @override
  List<Object?> get props => [status, user, persona];
}
