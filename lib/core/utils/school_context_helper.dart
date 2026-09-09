import '../../app/di/di.dart';
import '../../data/features/auth/datasources/auth_local_datasource.dart';
import '../storage/storage_service.dart';
import 'storage_keys.dart';
import 'logger_service.dart';

class SchoolContextHelper {
  SchoolContextHelper._();

  /// Resolves a display name for the currently active school, preferring a
  /// real name but falling back all the way to the school CODE itself
  /// rather than null — several other call sites in this app (e.g.
  /// `ActiveSchoolSwitcher`, `AuthLocalDataSourceImpl.setSelectedOrgAndSchool`)
  /// already persist the code as `selectedSchoolName`/`schoolName` when no
  /// prettier name is known at that point, so rejecting that same value
  /// here (the previous `!= schoolCode` guards) made this return null far
  /// more often than the school context was actually unknown — every report
  /// screen treats that null as a hard "Unable to resolve school name"
  /// block, refusing to generate a report even though a schoolCode WAS
  /// available. Only returns null when there is truly no schoolCode at all.
  static Future<String?> getSchoolName() async {
    final storage = serviceLocator<StorageService>();
    final authLocal = serviceLocator<AuthLocalDataSource>();
    final orgCode = (await storage.getString(
      StorageKeys.organizationCode,
    ))?.trim();
    final schoolCode = (await storage.getString(
      StorageKeys.schoolCode,
    ))?.trim();

    AppLogger.d('[SCHOOL_CTX] orgCode=$orgCode schoolCode=$schoolCode');

    // Read cached org+school list (preserve whatever the backend stored).
    final schools = await authLocal.getOrganizationsAndSchools();
    AppLogger.d('[SCHOOL_CTX] organizationsAndSchools=$schools');

    // 1) Prefer a real schoolName from organizationsAndSchools (only if it
    //    is present and not equal to the code).
    if (schoolCode != null && schoolCode.isNotEmpty) {
      for (final school in schools) {
        final currentSchoolCode = (school['schoolCode'] ?? '')
            .toString()
            .trim();
        final currentOrgCode = (school['organizationCode'] ?? '')
            .toString()
            .trim();
        final currentSchoolName = (school['schoolName'] ?? '')
            .toString()
            .trim();

        AppLogger.d(
          '[SCHOOL_CTX] entry: org=$currentOrgCode code=$currentSchoolCode name=$currentSchoolName',
        );

        if (currentSchoolCode == schoolCode &&
            (orgCode == null || orgCode.isEmpty || currentOrgCode == orgCode)) {
          if (currentSchoolName.isNotEmpty &&
              currentSchoolName != currentSchoolCode) {
            AppLogger.d(
              '[SCHOOL_CTX] resolved from orgsAndSchools=$currentSchoolName',
            );
            return currentSchoolName;
          }
        }
      }
    }

    // 2) Next, check the persisted selectedSchoolName (explicit selection flows).
    final storedSelectedName = (await storage.getString(
      StorageKeys.selectedSchoolName,
    ))?.trim();
    AppLogger.d('[SCHOOL_CTX] selectedSchoolName=$storedSelectedName');
    if (storedSelectedName != null &&
        storedSelectedName.isNotEmpty &&
        storedSelectedName != schoolCode) {
      AppLogger.d(
        '[SCHOOL_CTX] resolved from selectedSchoolName=$storedSelectedName',
      );
      return storedSelectedName;
    }

    // 3) Login-context may contain a display name (e.g. LastLoginSchoolName).
    try {
      final loginContext = await authLocal.getLoginContext();
      final ctxName = (loginContext?['schoolName'] ?? '').toString().trim();
      AppLogger.d('[SCHOOL_CTX] loginContext.schoolName=$ctxName');
      if (ctxName.isNotEmpty && ctxName != schoolCode) {
        AppLogger.d('[SCHOOL_CTX] resolved from loginContext=$ctxName');
        return ctxName;
      }
    } catch (_) {}

    // 4) Last resort: return the code if present (keeps existing behaviour of
    //    not blocking report generation). If even code is missing return null.
    if (schoolCode != null && schoolCode.isNotEmpty) {
      AppLogger.d('[SCHOOL_CTX] falling back to schoolCode=$schoolCode');
      return schoolCode;
    }

    AppLogger.d('[SCHOOL_CTX] no school name or code found');
    return null;
  }
}
