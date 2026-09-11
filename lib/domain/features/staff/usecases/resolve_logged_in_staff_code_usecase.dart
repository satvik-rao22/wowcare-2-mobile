import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/login_persona_util.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';

/// Resolves `staffCode` for the logged-in user: prefers validated cache, then
/// `/api/v1/staff/code` (same as login). Persists to storage when fetched.
///
/// Constructor-injected (`StorageService`/`StaffRepository`), so callers
/// reach it through a Cubit rather than resolving those dependencies (or this
/// use case itself) directly — the seam Mandate 5 requires.
class ResolveLoggedInStaffCodeUseCase {
  const ResolveLoggedInStaffCodeUseCase(this._storage, this._staffRepo);

  final StorageService _storage;
  final StaffRepository _staffRepo;

  Future<String?> call() async {
    try {
      final userCode = (await _storage.getString(StorageKeys.userCode) ?? '')
          .trim();
      if (userCode.isEmpty) return null;

      final orgCode =
          (await _storage.getString(StorageKeys.organizationCode) ?? '')
              .trim();
      final schoolFromStorage =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();

      if (orgCode.isNotEmpty) {
        final rolesJson = (await _storage.getString(StorageKeys.roles) ?? '')
            .trim();
        if (shouldSkipStaffCodeResolutionForContext(
          rolesJson: rolesJson,
          organizationCode: orgCode,
          schoolCode: schoolFromStorage,
        )) {
          return null;
        }
      }

      final cachedStaffCode =
          (await _storage.getString(StorageKeys.staffCode) ?? '').trim();
      final cachedStaffUser =
          (await _storage.getString(StorageKeys.staffCodeUser) ?? '').trim();

      if (cachedStaffCode.isNotEmpty &&
          cachedStaffUser.isNotEmpty &&
          cachedStaffUser == userCode) {
        return cachedStaffCode;
      }
      if (cachedStaffCode.isNotEmpty) {
        return cachedStaffCode;
      }

      if (orgCode.isEmpty) return null;

      Future<String?> lookup(String schoolCode) async {
        final code = await _staffRepo.getStaffCodeForUser(
          userCode: userCode,
          organizationCode: orgCode,
          schoolCode: schoolCode,
        );
        final t = (code ?? '').trim();
        return t.isEmpty ? null : t;
      }

      // Org admins are mapped org-level: the /staff/code lookup expects '-'
      // and 404s on a real school code, so resolve the right lookup school up
      // front instead of firing a doomed real-school request first.
      final rolesJson = (await _storage.getString(StorageKeys.roles) ?? '')
          .trim();
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
        await _storage.saveString(StorageKeys.staffCode, resolved);
        await _storage.saveString(StorageKeys.staffCodeUser, userCode);
      }
      return resolved;
    } catch (e) {
      CoreUtils.logApiError('ResolveLoggedInStaffCodeUseCase failed: $e');
      return null;
    }
  }
}

/// Resolves staff display name from staff APIs.
/// Prefers `/api/v1/staff/my-profile/{staffCode}`, then
/// `/api/v1/staff/{staffCode}/profile`.
class ResolveLoggedInStaffDisplayNameUseCase {
  const ResolveLoggedInStaffDisplayNameUseCase(
    this._staffRepo,
    this._resolveStaffCode,
  );

  final StaffRepository _staffRepo;
  final ResolveLoggedInStaffCodeUseCase _resolveStaffCode;

  Future<String> call({String? staffCode}) async {
    try {
      final code = (staffCode ?? await _resolveStaffCode() ?? '').trim();
      if (code.isEmpty) return '';
      try {
        final myProfile = await _staffRepo.getStaffProfile(staffCode: code);
        final full = myProfile.fullName.trim();
        final composed = '${myProfile.firstName} ${myProfile.lastName}'
            .trim();
        final resolved = full.isNotEmpty ? full : composed;
        if (resolved.isNotEmpty) return resolved;
      } catch (_) {
        // Falls through to the by-code profile lookup below.
      }
      try {
        final profileByCode = await _staffRepo.getStaffProfile(
          staffCode: code,
          forEditStaff: true,
        );
        final full = profileByCode.fullName.trim();
        final composed =
            '${profileByCode.firstName} ${profileByCode.lastName}'.trim();
        final resolved = full.isNotEmpty ? full : composed;
        if (resolved.isNotEmpty) return resolved;
      } catch (_) {
        // Both lookups failed — return '' below, same as before.
      }
      return '';
    } catch (e) {
      CoreUtils.logApiError('ResolveLoggedInStaffDisplayNameUseCase failed: $e');
      return '';
    }
  }
}
