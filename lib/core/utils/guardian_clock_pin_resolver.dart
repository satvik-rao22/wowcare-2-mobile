import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/student/entities/student_guardian.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';

/// Picks the logged-in guardian's sign-in PIN out of a student's [guardians].
///
/// A student can have several guardians and the response carries all of their
/// PINs, so "the PIN" is whichever row belongs to the person holding the phone.
/// Preference order: the row matching the logged-in user (by `userCode`, then
/// `guardianCode`) → the primary contact → the first guardian that has a PIN
/// at all. Only rows that actually carry a PIN are considered, so a match on a
/// PIN-less row can't shadow one that would have shown a number.
String selectGuardianClockPin({
  required List<StudentGuardian> guardians,
  required String loggedInUserCode,
  required String loggedInGuardianCode,
}) {
  final withPin = guardians
      .where((g) => (g.clockPin ?? '').trim().isNotEmpty)
      .toList(growable: false);
  if (withPin.isEmpty) return '';

  final userCode = loggedInUserCode.trim();
  final guardianCode = loggedInGuardianCode.trim();

  StudentGuardian? matchForUser;
  if (userCode.isNotEmpty || guardianCode.isNotEmpty) {
    for (final g in withPin) {
      if (userCode.isNotEmpty && g.userCode.trim() == userCode) {
        matchForUser = g;
        break;
      }
      if (guardianCode.isNotEmpty && g.guardianCode.trim() == guardianCode) {
        matchForUser = g;
        break;
      }
    }
  }

  final primaryWithPin = withPin.where((g) => g.primaryContact).firstOrNull;

  return ((matchForUser?.clockPin) ??
          (primaryWithPin?.clockPin) ??
          (withPin.firstOrNull?.clockPin) ??
          '')
      .trim();
}

/// Fetches the logged-in guardian's sign-in PIN for [studentCode].
///
/// The parent-persona counterpart of `fetchSignInPinForLoggedInUser`: a
/// guardian has no staff record, so their PIN lives on the student's guardian
/// list rather than behind the staff PIN endpoint.
///
/// Like the staff variant, nothing is cached — `forceRefresh: true` skips the
/// 5-minute guardians cache, because a PIN changed on the web is never
/// invalidated here (no PIN update passes through this app) and a stale cache
/// would keep showing the old number.
///
/// Returns an empty string when there is no child selected or no guardian
/// carries a PIN, and `null` when the call itself failed — callers treat
/// `null` as "leave whatever is on screen alone".
Future<String?> fetchGuardianSignInPinForLoggedInUser({
  required String studentCode,
  StudentRepository? studentRepository,
  StorageService? storageService,
}) async {
  final code = studentCode.trim();
  if (code.isEmpty) return '';

  final repository = studentRepository ?? serviceLocator<StudentRepository>();
  final storage = storageService ?? serviceLocator<StorageService>();

  try {
    final guardians = await repository.getStudentGuardians(
      studentCode: code,
      forceRefresh: true,
    );
    return selectGuardianClockPin(
      guardians: guardians,
      loggedInUserCode:
          (await storage.getString(StorageKeys.userCode) ?? '').trim(),
      loggedInGuardianCode:
          (await storage.getString(StorageKeys.guardianCode) ?? '').trim(),
    );
  } catch (e) {
    AppLogger.w('[SIGN-IN-PIN] Guardian fetch failed for student=$code: $e');
    return null;
  }
}
