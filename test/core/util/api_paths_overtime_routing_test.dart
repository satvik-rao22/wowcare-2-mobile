import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/utils/api_paths.dart';
import 'package:wowcare/core/utils/api_constants.dart';
import 'package:wowcare/core/utils/api_paths_uat.dart';

/// Every endpoint the Attendance V2 (staff overtime) module calls has to reach
/// the attendance microservice.
///
/// This exists because it did not. `staff-overtime-records` was added to
/// [ApiPaths.microserviceKeyFromPath] — the LEGACY, non-gateway mapper — and
/// nowhere else. Every environment that matters (DEV, UAT, PROD) is a gateway
/// environment and routes through [ApiPathsUat], where an unrecognised
/// resource silently falls through to the `user` host. The result was
/// `{gateway}/api/v1/user/staff-overtime-records/profile`, so the overtime
/// screen loaded nothing at all while every test passed.
///
/// The failure mode is what makes it worth a test: an unknown resource does
/// not throw, it just resolves to the wrong host.
void main() {
  /// Every path the Attendance V2 module builds, and the microservice each
  /// one belongs to. `staff-shifts` is a staff-service resource even though
  /// the overtime screen is the caller — the host follows the resource, not
  /// the feature.
  final Map<String, ({String path, String host})> modulePaths =
      <String, ({String path, String host})>{
        'overtime overview': (
          path: '/api/v1/staff-overtime-records/profile',
          host: ApiMicroservices.attendance,
        ),
        'overtime calculate': (
          path: '/api/v1/staff-overtime-records/calculate',
          host: ApiMicroservices.attendance,
        ),
        'day detail': (
          path: '/api/v1/staff-attendance-records/profile',
          host: ApiMicroservices.attendance,
        ),
        'absences': (
          path: '/api/v1/staff-absence-records/profile/absent-toggle',
          host: ApiMicroservices.attendance,
        ),
        'absent days': (
          path: '/api/v1/staff-shifts/absent-days',
          host: ApiMicroservices.staff,
        ),
      };

  group('every Attendance V2 path reaches its own microservice', () {
    test('on a gateway environment (DEV / UAT / PROD)', () {
      final Map<String, String> wrong = <String, String>{};
      modulePaths.forEach((String what, ({String path, String host}) e) {
        final String got = ApiPathsUat.microserviceKeyFromPath(e.path);
        if (got != e.host)
          wrong['$what (${e.path})'] = 'got $got, want ${e.host}';
      });
      expect(
        wrong,
        isEmpty,
        reason:
            'An unknown resource falls back to `user`, which 404s instead of '
            'failing loudly:\n'
            '${wrong.entries.map((e) => '  ${e.key}: ${e.value}').join('\n')}',
      );
    });

    test('and identically on the legacy non-gateway mapper', () {
      // Both mappers have to agree: whichever one a build resolves through,
      // the module has to land on the same host.
      final Map<String, String> wrong = <String, String>{};
      modulePaths.forEach((String what, ({String path, String host}) e) {
        final String got = ApiPaths.microserviceKeyFromPath(e.path);
        if (got != e.host)
          wrong['$what (${e.path})'] = 'got $got, want ${e.host}';
      });
      expect(wrong, isEmpty, reason: wrong.toString());
    });
  });

  test('an unknown resource still falls back to user, as documented', () {
    // Pinning the fallback itself: this is the behaviour that made the bug
    // silent, so if it ever changes to throw, the comment above stops being
    // true and this test should be revisited.
    expect(
      ApiPathsUat.microserviceKeyFromPath('/api/v1/not-a-real-resource/x'),
      ApiMicroservices.user,
    );
  });
}
