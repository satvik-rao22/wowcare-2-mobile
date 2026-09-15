import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/utils/api_paths.dart';
import 'package:wowcare/core/utils/api_paths_uat.dart';

/// Locks the three "delete profile photo" endpoints to the exact live UAT
/// routes captured by curl against `https://uat.childcarewow.app`:
///
///   POST /api/v1/student/student/delete-profile-photo/STD_703E2987
///   POST /api/v1/student/guardian/delete-profile-photo/GUA_7367AD6C
///   POST /api/v1/staff/staff/my-profile/delete-profile-photo/STF_A31D9EF6-6
///
/// Two separate things are asserted, because the doubled microservice segment
/// in those URLs is produced by [ApiPathsUat], NOT stored in [ApiPaths]:
///
///  1. [ApiPaths] holds the CANONICAL short path. Storing the doubled gateway
///     form instead would still work on UAT (the rewrite is idempotent) but
///     404s in LOCAL/DEV, which is the trap the sibling comments on
///     `studentPhysicalCheckupCount` already warn about — so it is worth a test.
///  2. [ApiPathsUat.url] rewrites that canonical path into the gateway form.
///
/// Asserted with `endsWith`, matching [ApiPathsUat]'s own test file: the host
/// prefix comes from `ApiConstants.baseUrlForMicroservice`, which switches on
/// the `isUat`/`isProd` `--dart-define`s. Under a plain `flutter test` neither
/// is defined, so it resolves to the local dev host. Comparing against a
/// hard-coded `https://uat.childcarewow.app` literal would make this suite
/// pass only when run with the UAT defines — a bug that file records having
/// already been fixed once.
void main() {
  // The exact codes from the captured curls.
  const studentCode = 'STD_703E2987';
  const guardianCode = 'GUA_7367AD6C';
  const staffCode = 'STF_A31D9EF6-6';

  // The path component of each curl URL, verbatim.
  const studentUatPath =
      '/api/v1/student/student/delete-profile-photo/$studentCode';
  const guardianUatPath =
      '/api/v1/student/guardian/delete-profile-photo/$guardianCode';
  const staffUatPath =
      '/api/v1/staff/staff/my-profile/delete-profile-photo/$staffCode';

  group('ApiPaths — canonical delete-profile-photo paths', () {
    test('student path is the direct-MS form, not the doubled gateway form', () {
      expect(
        ApiPaths.studentDeleteProfilePhotoPath(studentCode),
        '/api/v1/student/delete-profile-photo/$studentCode',
      );
      expect(
        ApiPaths.studentDeleteProfilePhotoPath(studentCode),
        isNot(contains('/student/student/')),
      );
    });

    test('guardian path is rooted at /guardian (student MS resolves the host)', () {
      expect(
        ApiPaths.guardianDeleteProfilePhotoPath(guardianCode),
        '/api/v1/guardian/delete-profile-photo/$guardianCode',
      );
      expect(
        ApiPaths.guardianDeleteProfilePhotoPath(guardianCode),
        isNot(contains('/student/guardian/')),
      );
    });

    test('staff path is the pre-existing my-profile-scoped constant', () {
      expect(
        ApiPaths.staffDeleteProfilePhotoPath(staffCode),
        '/api/v1/staff/my-profile/delete-profile-photo/$staffCode',
      );
      expect(
        ApiPaths.staffDeleteProfilePhotoPath(staffCode),
        isNot(contains('/staff/staff/')),
      );
    });
  });

  group('ApiPathsUat.url — canonical paths rewrite to the captured curl URLs', () {
    test('student', () {
      expect(
        ApiPathsUat.url(ApiPaths.studentDeleteProfilePhotoPath(studentCode)),
        endsWith(studentUatPath),
      );
    });

    test('guardian', () {
      expect(
        ApiPathsUat.url(ApiPaths.guardianDeleteProfilePhotoPath(guardianCode)),
        endsWith(guardianUatPath),
      );
    });

    test('staff', () {
      expect(
        ApiPathsUat.url(ApiPaths.staffDeleteProfilePhotoPath(staffCode)),
        endsWith(staffUatPath),
      );
    });

    test('the rewrite is idempotent — no path gains a second segment', () {
      // Guards the failure mode the plan called out: if someone "fixes" the
      // constants by pasting the curl URLs in, the paths must not end up as
      // `/student/student/student/...` on UAT.
      expect(ApiPathsUat.url(studentUatPath), endsWith(studentUatPath));
      expect(ApiPathsUat.url(guardianUatPath), endsWith(guardianUatPath));
      expect(ApiPathsUat.url(staffUatPath), endsWith(staffUatPath));
    });
  });
}
