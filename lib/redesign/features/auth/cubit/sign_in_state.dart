part of 'sign_in_cubit.dart';

enum SignInStatus {
  /// 1a at rest, and every keystroke in it.
  editing,

  /// 1a's key showing its ring.
  submitting,

  /// Wrong email or password. Login returns a generic failure and nothing
  /// else, so there is no attempts-left or lockout case to draw.
  rejected,

  /// The request never reached the server.
  offline,

  /// Credentials accepted, scope still to pick: 1b and 1c.
  signedIn,

  /// Scope picked. The page hands [SignInState.user] to the session.
  scoped,
}

@immutable
class SignInState extends Equatable {
  const SignInState({
    this.status = SignInStatus.editing,
    this.email = '',
    this.password = '',
    this.account,
    this.organization,
    this.school,
    this.schoolQuery = '',
  });

  final SignInStatus status;
  final String email;
  final String password;

  /// Who signed in, and everywhere they can work. Null until 1a succeeds.
  final AuthAccount? account;

  final AuthOrganization? organization;
  final AuthSchool? school;

  /// 1c's search box.
  final String schoolQuery;

  bool get isSubmitting => status == SignInStatus.submitting;
  bool get isRejected => status == SignInStatus.rejected;
  bool get isOffline => status == SignInStatus.offline;

  /// The key is live once both fields carry something. Nothing more is
  /// validated here: the server decides whether the pair is right.
  bool get canSubmit => email.trim().isNotEmpty && password.isNotEmpty;

  List<AuthOrganization> get organizations =>
      account?.organizations ?? const <AuthOrganization>[];

  /// The schools of the picked organization, filtered by [schoolQuery].
  List<AuthSchool> get schools {
    final all = organization?.schools ?? const <AuthSchool>[];
    final query = schoolQuery.trim().toLowerCase();
    if (query.isEmpty) return all;
    return all
        .where(
          (s) =>
              s.name.toLowerCase().contains(query) ||
              s.code.toLowerCase().contains(query),
        )
        .toList();
  }

  /// The account, re-scoped to the organization and school just picked.
  SessionUser? get user {
    final base = account?.user;
    if (base == null || organization == null || school == null) return null;
    return base.copyWith(
      organizationName: organization!.name,
      schoolName: school!.name,
    );
  }

  SignInState copyWith({
    SignInStatus? status,
    String? email,
    String? password,
    AuthAccount? account,
    AuthOrganization? organization,
    AuthSchool? school,
    String? schoolQuery,
    bool clearSchool = false,
  }) => SignInState(
    status: status ?? this.status,
    email: email ?? this.email,
    password: password ?? this.password,
    account: account ?? this.account,
    organization: organization ?? this.organization,
    school: clearSchool ? null : (school ?? this.school),
    schoolQuery: clearSchool ? '' : (schoolQuery ?? this.schoolQuery),
  );

  @override
  List<Object?> get props => [
    status,
    email,
    password,
    account,
    organization,
    school,
    schoolQuery,
  ];
}
