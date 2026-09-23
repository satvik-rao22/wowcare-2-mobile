import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/staff_code_resolver.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';

/// Fetches the logged-in staff member's sign-in PIN from the API.
///
/// The PIN is deliberately **not** cached. It used to be read once at login
/// into `StorageKeys.staffPin` and then served from storage forever, so a PIN
/// changed on the web stayed wrong on the My Day card and in the app bar menu
/// until the user logged out and back in. Every caller now asks the API.
///
/// Returns an empty string when there is no staff code to ask about (a
/// guardian-only account) and `null` when the call itself failed — callers
/// treat `null` as "leave whatever is on screen alone", since blanking a
/// correct PIN because the network blipped is worse than showing it a moment
/// longer.
Future<String?> fetchSignInPinForLoggedInUser({
  StaffRepository? staffRepository,
  StorageService? storageService,
}) async {
  final repository = staffRepository ?? serviceLocator<StaffRepository>();
  final storage = storageService ?? serviceLocator<StorageService>();

  var staffCode = '';
  try {
    staffCode = await resolveStaffCodeForLoggedInUser();
  } catch (_) {
    // Fall through to the stored code below.
  }
  if (staffCode.isEmpty) {
    staffCode = (await storage.getString(StorageKeys.staffCode) ?? '').trim();
  }
  if (staffCode.isEmpty) return '';

  try {
    final pin = await repository.getStaffSignInPin(staffCode: staffCode);
    return pin.trim();
  } catch (e) {
    AppLogger.w('[SIGN-IN-PIN] Fetch failed for staffCode=$staffCode: $e');
    return null;
  }
}
