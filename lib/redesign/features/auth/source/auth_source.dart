import 'package:wowcare/redesign/features/auth/models/models.dart';

/// Where M01 gets its data. Fixtures during the UI phase; in the last phase
/// one implementation wraps `LoginUseCase`, `ForgotPasswordUseCase`,
/// `AuthCubit.loadOrganizationNames` / `loadSchoolsForOrg`,
/// `GetActiveKioskQrUseCase`, `VerifyKioskPinUseCase` and the kiosk
/// sign-in / sign-out usecases.
///
/// No method takes a school or organization code off storage: the scope the
/// caller is working in is always passed in, so the cubits stay free of the
/// locator.
abstract interface class AuthSource {
  /// `POST /api/v1/auth/login`, with the organizations and schools the
  /// account can open folded in. Never throws: the three outcomes are the
  /// three [SignInResult] cases.
  Future<SignInResult> signIn({
    required String email,
    required String password,
  });

  /// `POST /api/v1/auth/forgot-password`. False when the link could not be
  /// sent, which is the only failure 1d draws.
  Future<bool> sendResetLink(String email);

  /// Saves the new password behind a reset link. False when it could not be
  /// saved.
  Future<bool> savePassword(String password);

  /// The kiosk's live QR. Throws [KioskQrFailure] with the line 2e shows.
  Future<KioskQr> activeQr(String schoolCode);

  /// `POST /api/v1/attendance/kiosk/verify-pin`. Null when the PIN belongs to
  /// nobody, which is the only rejection the kiosk draws.
  Future<KioskPinResult?> verifyPin(String pin);

  /// Records the picked students against the guardian on [result], and hands
  /// back the family with today's statuses moved on.
  Future<KioskPinResult> recordStudents({
    required KioskPinResult result,
    required Set<String> studentIds,
    required bool isSigningIn,
  });

  /// Records a staff member's own arrival or departure from the kiosk.
  Future<KioskPinResult> recordStaff({
    required KioskPinResult result,
    required bool isSigningIn,
  });

  /// Whether this PIN may leave kiosk mode. Admin PINs only.
  Future<bool> isAdminPin(String pin);

  /// What a scanned kiosk code resolves to: the guardian standing at the
  /// door, and their students. Null when the code is not one of ours.
  Future<KioskPinResult?> resolveScannedCode(String payload);
}
