import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/utils/api_constants.dart';
import 'package:wowcare/core/utils/api_paths.dart';
import 'package:wowcare/core/utils/api_paths_uat.dart';
import 'package:wowcare/modules/attendance_regularization/data/datasources/reg_api_paths.dart';

/// The regularization resource segment has to resolve to the **attendance**
/// microservice. Unregistered segments fall through to `user`, which in a
/// gateway build produces `/api/v1/user/...` and a silent 404 — the gate then
/// looks like it simply never fires.
void main() {
  const paths = [
    RegApiPaths.openSessionsCheck,
    RegApiPaths.raise,
    RegApiPaths.raiseBatch,
    RegApiPaths.approveSelected,
  ];

  test('every regularization path maps to the attendance microservice', () {
    for (final path in [...paths, RegApiPaths.approve('SREG_1'), RegApiPaths.edit('SREG_1')]) {
      expect(ApiPaths.microserviceKeyFromPath(path), ApiMicroservices.attendance,
          reason: path);
      expect(ApiPathsUat.microserviceKeyFromPath(path),
          ApiMicroservices.attendance,
          reason: path);
    }
  });

  test('a gateway build puts the attendance segment in the path', () {
    expect(
      ApiPathsUat.url(RegApiPaths.openSessionsCheck),
      endsWith(
          '/api/v1/attendance/staff-attendance-regularizations/open-sessions/check'),
    );
  });

  test('the sign-in endpoints the gate watches resolve to attendance too', () {
    for (final path in [RegApiPaths.signInAdmin, RegApiPaths.signInSelf]) {
      expect(ApiPaths.microserviceKeyFromPath(path), ApiMicroservices.attendance,
          reason: path);
    }
  });
}
