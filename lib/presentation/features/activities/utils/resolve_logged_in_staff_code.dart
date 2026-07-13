import '../../../../app/di/di.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../core/util/login_persona_util.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';

/// Resolves `staffCode` for the logged-in user: prefers validated cache, then
/// `/api/v1/staff/code` (same as login). Persists to storage when fetched.
Future<String?> resolveLoggedInStaffCode() async {
  try {
    final storage = serviceLocator<StorageService>();
    final userCode =
        (await storage.getString(StorageKeys.userCode) ?? '').trim();
    if (userCode.isEmpty) return null;

    final orgCode =
        (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final schoolFromStorage =
        (await storage.getString(StorageKeys.schoolCode) ?? '').trim();

    if (orgCode.isNotEmpty) {
      final rolesJson =
          (await storage.getString(StorageKeys.roles) ?? '').trim();
      if (shouldSkipStaffCodeResolutionForContext(
        rolesJson: rolesJson,
        organizationCode: orgCode,
        schoolCode: schoolFromStorage,
      )) {
        return null;
      }
    }

    final cachedStaffCode =
        (await storage.getString(StorageKeys.staffCode) ?? '').trim();
    final cachedStaffUser =
        (await storage.getString(StorageKeys.staffCodeUser) ?? '').trim();

    if (cachedStaffCode.isNotEmpty &&
        cachedStaffUser.isNotEmpty &&
        cachedStaffUser == userCode) {
      return cachedStaffCode;
    }
    if (cachedStaffCode.isNotEmpty) {
      return cachedStaffCode;
    }

    if (orgCode.isEmpty) return null;

    final staffRepo = serviceLocator<StaffRepository>();

    Future<String?> lookup(String schoolCode) async {
      final code = await staffRepo.getStaffCodeForUser(
        userCode: userCode,
        organizationCode: orgCode,
        schoolCode: schoolCode,
      );
      final t = (code ?? '').trim();
      return t.isEmpty ? null : t;
    }

    // Org admins are mapped org-level: the /staff/code lookup expects '-' and
    // 404s on a real school code, so resolve the right lookup school up front
    // instead of firing a doomed real-school request first.
    final rolesJson = (await storage.getString(StorageKeys.roles) ?? '').trim();
    final lookupSchool = staffCodeLookupSchoolCode(
      rolesJson: rolesJson,
      organizationCode: orgCode,
      schoolCode: schoolFromStorage,
    );

    String? resolved;
    if (lookupSchool.isNotEmpty && lookupSchool != '-') {
      resolved = await lookup(lookupSchool);
    }
    resolved ??= await lookup('-');

    if (resolved != null) {
      await storage.saveString(StorageKeys.staffCode, resolved);
      await storage.saveString(StorageKeys.staffCodeUser, userCode);
    }
    return resolved;
  } catch (e) {
    CoreUtils.logApiError('resolveLoggedInStaffCode failed: $e');
    return null;
  }
}

/// Resolves staff display name from staff APIs.
/// Prefers `/api/v1/staff/my-profile/{staffCode}`, then
/// `/api/v1/staff/{staffCode}/profile`.
Future<String> resolveLoggedInStaffDisplayNameFromApi({
  String? staffCode,
}) async {
  try {
    final code = (staffCode ?? await resolveLoggedInStaffCode() ?? '').trim();
    if (code.isEmpty) return '';
    final staffRepo = serviceLocator<StaffRepository>();
    try {
      final myProfile = await staffRepo.getStaffProfile(staffCode: code);
      final full = myProfile.fullName.trim();
      final composed = '${myProfile.firstName} ${myProfile.lastName}'.trim();
      final resolved = full.isNotEmpty ? full : composed;
      if (resolved.isNotEmpty) return resolved;
    } catch (_) {}
    try {
      final profileByCode = await staffRepo.getStaffProfile(
        staffCode: code,
        forEditStaff: true,
      );
      final full = profileByCode.fullName.trim();
      final composed = '${profileByCode.firstName} ${profileByCode.lastName}'
          .trim();
      final resolved = full.isNotEmpty ? full : composed;
      if (resolved.isNotEmpty) return resolved;
    } catch (_) {}
    return '';
  } catch (e) {
    CoreUtils.logApiError('resolveLoggedInStaffDisplayNameFromApi failed: $e');
    return '';
  }
}
