import '../../app/di/di.dart';
import '../../data/features/auth/datasources/auth_local_datasource.dart';
import '../storage/storage_service.dart';
import 'storage_keys.dart';

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

    if (schoolCode == null || schoolCode.isEmpty) {
      return null;
    }

    final schools = await authLocal.getOrganizationsAndSchools();

    for (final school in schools) {
      final currentSchoolCode = (school['schoolCode'] ?? '').trim();

      final currentOrgCode = (school['organizationCode'] ?? '').trim();

      if (currentSchoolCode == schoolCode &&
          (orgCode == null || orgCode.isEmpty || currentOrgCode == orgCode)) {
        final schoolName = (school['schoolName'] ?? '').trim();

        if (schoolName.isNotEmpty) {
          return schoolName;
        }
      }
    }

    final storedSchoolName = (await storage.getString(
      StorageKeys.selectedSchoolName,
    ))?.trim();

    if (storedSchoolName != null && storedSchoolName.isNotEmpty) {
      return storedSchoolName;
    }

    // Absolute last resort: the code itself. Still a valid, non-null value
    // for the backend's schoolName field — strictly better than blocking
    // report generation entirely over a missing pretty label.
    return schoolCode;
  }
}
