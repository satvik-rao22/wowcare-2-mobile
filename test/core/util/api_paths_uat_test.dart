import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/util/api_paths_uat.dart';

void main() {
  group('ApiPathsUat.url', () {
    test(
      'keeps staff my-profile asset-code paths under a single staff segment',
      () {
        const path = '/api/v1/staff/my-profile/profile-photo/asset-codes';

        expect(
          ApiPathsUat.url(path),
          'https://uat-wowcare.childcarewow.app$path',
        );
      },
    );

    test(
      'keeps staff my-profile profile paths under a single staff segment',
      () {
        const path = '/api/v1/staff/my-profile/STF_123/profile';

        expect(
          ApiPathsUat.url(path),
          'https://uat-wowcare.childcarewow.app$path',
        );
      },
    );
  });
}
