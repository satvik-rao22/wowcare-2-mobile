import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/auth/auth_strings.dart';
import 'package:wowcare/redesign/features/auth/models/models.dart';
import 'package:wowcare/redesign/features/auth/source/auth_source.dart';

/// M01's fixtures, drawn from the one demo world in `DemoData`.
///
/// Sign in with any of the three demo addresses and any password; 1a arrives
/// prefilled with the one the frame shows, so the reviewer only has to press
/// the key. An address the demo world does not know is [SignInRejected], and
/// the literal `offline` as a password is [SignInOffline], so both of 1a's
/// unhappy states can be reached without unplugging anything.
///
/// The kiosk knows every staff PIN in `DemoData.staffMembers` and one
/// guardian PIN, Ngozi Okafor's, whose two students are one Signed In and one
/// Signed Out, which is exactly the mixed family 2d exists for.
class PreviewAuthSource implements AuthSource {
  PreviewAuthSource();

  /// Long enough that 1a's Signing in state and 2e's Loading QR card are both
  /// visible, short enough not to be in the way.
  static const Duration _latency = Duration(milliseconds: 700);

  /// The password that stands in for a dead network.
  static const String _offlinePassword = 'offline';

  /// Ngozi Okafor's Sign-In PIN. Staff PINs come off `DemoData`.
  static const String _guardianPin = '1234';

  /// Only a Director may leave kiosk mode, and Marcus is the only one.
  static const String _adminPin = '4821';

  /// 2e cycles its four states on every pull to refresh, which is what the
  /// frame is demonstrating. Nothing else in the app counts calls.
  int _qrCall = 0;

  @override
  Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_latency);

    if (password.trim().toLowerCase() == _offlinePassword) {
      return const SignInOffline();
    }

    final user = _userFor(email);
    if (user == null || password.trim().isEmpty) {
      return const SignInRejected();
    }

    return SignInSuccess(
      AuthAccount(user: user, organizations: _organizations),
    );
  }

  @override
  Future<bool> sendResetLink(String email) async {
    await Future<void>.delayed(_latency);
    return _userFor(email) != null;
  }

  @override
  Future<bool> savePassword(String password) async {
    await Future<void>.delayed(_latency);
    return true;
  }

  @override
  Future<KioskQr> activeQr(String schoolCode) async {
    await Future<void>.delayed(_latency);

    final call = _qrCall++;
    switch (call % 4) {
      case 1:
        return KioskQr(
          schoolName: DemoData.schoolName,
          payload: '',
          validTo: DemoData.today,
          isActive: false,
        );
      case 2:
        throw const KioskQrFailure(AuthStrings.qrUnable);
      case 3:
        throw const KioskQrFailure(AuthStrings.schoolCodeMissing);
      default:
        return KioskQr(
          schoolName: DemoData.schoolName,
          payload: 'wowcare://kiosk/${DemoData.schoolName}',
          validTo: DemoData.today.add(const Duration(seconds: 30)),
        );
    }
  }

  @override
  Future<KioskPinResult?> verifyPin(String pin) async {
    await Future<void>.delayed(_latency);
    return _resultFor(pin);
  }

  @override
  Future<KioskPinResult> recordStudents({
    required KioskPinResult result,
    required Set<String> studentIds,
    required bool isSigningIn,
  }) async {
    await Future<void>.delayed(_latency);

    final moved = <KioskStudent>[
      for (final student in result.students)
        if (studentIds.contains(student.id))
          student.copyWith(
            attendance: isSigningIn
                ? AttendanceStatus.signedIn
                : AttendanceStatus.signedOut,
            timeLabel: _nowLabel,
          )
        else
          student,
    ];

    return KioskPinResult(
      persona: result.persona,
      personId: result.personId,
      personName: result.personName,
      acceptedAtLabel: result.acceptedAtLabel,
      staffAttendance: result.staffAttendance,
      students: moved,
    );
  }

  @override
  Future<KioskPinResult> recordStaff({
    required KioskPinResult result,
    required bool isSigningIn,
  }) async {
    await Future<void>.delayed(_latency);

    return KioskPinResult(
      persona: result.persona,
      personId: result.personId,
      personName: result.personName,
      acceptedAtLabel: _nowLabel,
      staffAttendance: isSigningIn
          ? AttendanceStatus.signedIn
          : AttendanceStatus.signedOut,
      students: result.students,
    );
  }

  @override
  Future<bool> isAdminPin(String pin) async {
    await Future<void>.delayed(_latency);
    return pin == _adminPin;
  }

  @override
  Future<KioskPinResult?> resolveScannedCode(String payload) async {
    await Future<void>.delayed(_latency);
    return payload.isEmpty ? null : _resultFor(_guardianPin);
  }

  // --- Fixtures -------------------------------------------------------------

  static SessionUser? _userFor(String email) {
    final wanted = email.trim().toLowerCase();
    for (final user in <SessionUser>[
      DemoData.admin,
      DemoData.staff,
      DemoData.guardian,
    ]) {
      if (user.email.toLowerCase() == wanted) return user;
    }
    return null;
  }

  static List<AuthOrganization> get _organizations => <AuthOrganization>[
    for (final org in DemoData.organizations)
      AuthOrganization(
        id: org.id,
        name: org.name,
        roleLabel: org.roleLabel,
        schools: <AuthSchool>[
          for (final (index, school) in org.schools.indexed)
            AuthSchool(
              id: school.id,
              code: 'SCH_${2481 + index * 909}',
              name: school.name,
              isLocked: school.isLocked,
              isCurrent: school.name == DemoData.schoolName,
            ),
        ],
      ),
  ];

  static KioskPinResult? _resultFor(String pin) {
    if (pin == _guardianPin) {
      return KioskPinResult(
        persona: KioskPersona.guardian,
        personId: DemoData.guardian.id,
        personName: DemoData.guardian.fullName,
        acceptedAtLabel: _nowLabel,
        students: <KioskStudent>[
          for (final child in DemoData.guardianChildren)
            KioskStudent(
              id: child.id,
              name: child.name,
              initials: child.initials,
              classroomName: child.classroom,
              attendance: _statusOf(child.attendance),
              timeLabel: child.timeLabel,
            ),
        ],
      );
    }

    for (final member in DemoData.staffMembers) {
      if (member.signInPin != pin) continue;
      return KioskPinResult(
        persona: KioskPersona.staff,
        personId: member.id,
        personName: member.name,
        acceptedAtLabel: _nowLabel,
        staffAttendance: _statusOf(member.attendance),
      );
    }

    return null;
  }

  static AttendanceStatus _statusOf(DemoAttendance attendance) =>
      switch (attendance) {
        DemoAttendance.signedIn => AttendanceStatus.signedIn,
        DemoAttendance.signedOut => AttendanceStatus.signedOut,
        DemoAttendance.absent => AttendanceStatus.absent,
        DemoAttendance.notMarked => AttendanceStatus.notMarked,
      };

  /// The demo world is frozen at 9:41 on the design's own day, so the kiosk
  /// stamps that rather than the device clock.
  static String get _nowLabel {
    final now = DemoData.today;
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${now.hour < 12 ? 'AM' : 'PM'}';
  }
}
