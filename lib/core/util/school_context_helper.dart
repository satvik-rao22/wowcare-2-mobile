import '../../app/di/di.dart';
import '../../data/features/auth/datasources/auth_local_datasource.dart';
import '../storage/storage_service.dart';
import 'storage_keys.dart';

class SchoolContextHelper {
  SchoolContextHelper._();

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

        if (schoolName.isNotEmpty && schoolName != schoolCode) {
          return schoolName;
        }
      }
    }

    // Last fallback only.
    final storedSchoolName = (await storage.getString(
      StorageKeys.selectedSchoolName,
    ))?.trim();

    if (storedSchoolName != null &&
        storedSchoolName.isNotEmpty &&
        storedSchoolName != schoolCode) {
      return storedSchoolName;
    }

    return null;
  }
}
