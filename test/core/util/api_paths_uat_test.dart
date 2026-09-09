import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/utils/api_paths_uat.dart';

/// [ApiPathsUat.url] does two separable things: it rewrites a LOCAL path into
/// the UAT gateway's shape, then prefixes the microservice's base URL.
///
/// These tests assert only the rewrite, via `endsWith`. The base URL comes from
/// `ApiConstants.baseUrlForMicroservice`, which switches on the `isUat`/`isProd`
/// build flags — under a plain `flutter test` neither is defined, so it resolves
/// to the local dev host. The previous version of this file compared against a
/// hard-coded `https://uat-wowcare.childcarewow.app` literal and could therefore
/// only ever pass when the suite was run with the UAT `--dart-define`s.
void main() {
  group('ApiPathsUat.url — staff microservice path rewriting', () {
    test(
      'a staff RESOURCE path nests under the staff microservice segment',
      () {
        // The UAT gateway routes `<microservice>/<resource>/...`, and for the
        // staff service both happen to be spelled "staff" — so the doubling is
        // the correct output, not a bug. `_ensureUatMicroserviceSegment` calls
        // this out explicitly ("local `/api/v1/staff/code` should become
        // `/api/v1/staff/staff/code` in UAT"), and the datasource doc comments
        // record the same live paths (see staff_remote_datasource.dart, e.g.
        // "PATCH /api/v1/staff/staff/my-profile/{staffCode}").
        expect(
          ApiPathsUat.url('/api/v1/staff/my-profile/profile-photo/asset-codes'),
          endsWith('/api/v1/staff/staff/my-profile/profile-photo/asset-codes'),
        );

        expect(
          ApiPathsUat.url('/api/v1/staff/my-profile/STF_123/profile'),
          endsWith('/api/v1/staff/staff/my-profile/STF_123/profile'),
        );
      },
    );

    test('a path already rooted at a known staff resource is left alone', () {
      // The invariant that actually matters: the rewrite must be idempotent, so
      // a path that has already been through it is not doubled a second time.
      const already = '/api/v1/staff/staff-documents/DOC_1';
      expect(ApiPathsUat.url(already), endsWith(already));
    });

    test(
      'a sibling staff resource gets the microservice segment prepended',
      () {
        expect(
          ApiPathsUat.url('/api/v1/staff-documents/DOC_1'),
          endsWith('/api/v1/staff/staff-documents/DOC_1'),
        );
      },
    );
  });
}
