import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/modules/attendance_regularization/core/config/reg_config.dart';
import 'package:wowcare/modules/attendance_regularization/core/errors/reg_exceptions.dart';
import 'package:wowcare/modules/attendance_regularization/data/datasources/reg_api_paths.dart';

/// D1 — the contract surface.
///
/// Every payload here is copied from `REGULARIZATION_API_CONTRACT.md` and the
/// Postman collection rather than invented, so these tests fail if the shipped
/// contract and this client ever drift.
void main() {
  DioException error(int status, Object? body, {String path = '/sign-in'}) {
    return DioException(
      requestOptions: RequestOptions(path: path),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: path),
        statusCode: status,
        data: body,
      ),
      type: DioExceptionType.badResponse,
    );
  }

  group('RegApiPaths — the seven endpoints', () {
    test('the gate is one endpoint', () {
      expect(
        RegApiPaths.openSessionsCheck,
        '/api/v1/staff-attendance-regularizations/open-sessions/check',
      );
    });

    test('raise and list share the base path', () {
      // Both personas go through the same call; the token decides the outcome.
      expect(RegApiPaths.raise, RegApiPaths.base);
      expect(RegApiPaths.list, RegApiPaths.base);
    });

    test('the remaining paths match the contract', () {
      expect(RegApiPaths.raiseBatch,
          '/api/v1/staff-attendance-regularizations/raise-batch');
      expect(RegApiPaths.approveSelected,
          '/api/v1/staff-attendance-regularizations/approve-selected');
      expect(RegApiPaths.approve('SREG_0000001'),
          '/api/v1/staff-attendance-regularizations/SREG_0000001/approve');
      expect(RegApiPaths.edit('SREG_0000001'),
          '/api/v1/staff-attendance-regularizations/SREG_0000001');
    });
  });

  group('RegApiPaths — sign-in matching', () {
    test('matches all three sign-in endpoints', () {
      expect(RegApiPaths.isStaffSignIn(RegApiPaths.signInAdmin), isTrue);
      expect(RegApiPaths.isStaffSignIn(RegApiPaths.signInSelf), isTrue);
      expect(RegApiPaths.isStaffSignIn(RegApiPaths.signInKiosk), isTrue);
    });

    test('matches fully-qualified URLs and ignores the query string', () {
      expect(
        RegApiPaths.isStaffSignIn(
            'https://api.example.com/api/v1/staff-attendance-records/sign-in/self?x=1'),
        isTrue,
      );
    });

    test('does not match sign-out, transfer or the student endpoints', () {
      expect(RegApiPaths.isStaffSignIn('/api/v1/staff-attendance-records/sign-out'),
          isFalse);
      expect(RegApiPaths.isStaffSignIn('/api/v1/staff-attendance-records/transfer'),
          isFalse);
      expect(RegApiPaths.isStaffSignIn('/api/v1/student-attendance-records/sign-in'),
          isFalse);
    });

    test('self and kiosk are self; the admin endpoint is not', () {
      // The service treats a kiosk as isAdmin=false, so a kiosk-raised
      // correction lands PENDING like any other self sign-in.
      expect(RegApiPaths.isSelfSignIn(RegApiPaths.signInSelf), isTrue);
      expect(RegApiPaths.isSelfSignIn(RegApiPaths.signInKiosk), isTrue);
      expect(RegApiPaths.isSelfSignIn(RegApiPaths.signInAdmin), isFalse);
    });

    test('only a kiosk must name whose gate it is asking about', () {
      // A device has no staff record, so `{}` is a 400 for it.
      expect(RegApiPaths.gateNeedsStaffCodes(RegApiPaths.signInKiosk), isTrue);
      expect(RegApiPaths.gateNeedsStaffCodes(RegApiPaths.signInSelf), isFalse);
      expect(RegApiPaths.gateNeedsStaffCodes(RegApiPaths.signInAdmin), isFalse);
    });
  });

  group('RegHttpErrors — REGULARIZATION_REQUIRED (contract §7)', () {
    /// Verbatim from the contract.
    final signInBlocked = {
      'success': false,
      'message': 'A missed sign-out from 2026-06-23 must be regularized first',
      'error': {
        'code': 'REGULARIZATION_REQUIRED',
        'rejectedValue': [
          {
            'staffCode': 'STF_0007',
            'attendanceCode': 'SAR_10231',
            'attendanceDate': '2026-06-23',
            'suggestedSignOutTime': '2026-06-23T13:30:00Z',
          }
        ],
      },
    };

    test('is recognised by its code', () {
      final e = error(409, signInBlocked);
      expect(RegHttpErrors.isRegularizationRequired(e), isTrue);
      expect(RegHttpErrors.codeOf(e), 'REGULARIZATION_REQUIRED');
    });

    test('carries the blocked day, so the sheet opens with no second call', () {
      final blocked = RegHttpErrors.blockedSessionsFrom(error(409, signInBlocked));
      expect(blocked.length, 1);
      expect(blocked.single['attendanceCode'], 'SAR_10231');
      expect(blocked.single['suggestedSignOutTime'], '2026-06-23T13:30:00Z');
    });

    test('exposes the human message for the toast', () {
      expect(
        RegHttpErrors.messageOf(error(409, signInBlocked)),
        'A missed sign-out from 2026-06-23 must be regularized first',
      );
    });

    test('a 409 that is NOT the gate is not treated as one', () {
      // e.g. "already signed in" — opening a regularization sheet would be
      // wrong, so the code has to match, not just the status.
      final e = error(409, {
        'success': false,
        'message': 'Staff already signed in for today',
        'error': {'code': 'ALREADY_SIGNED_IN'},
      });
      expect(RegHttpErrors.isRegularizationRequired(e), isFalse);
      expect(RegHttpErrors.blockedSessionsFrom(e), isEmpty);
    });

    test('a single object rather than a list is still read', () {
      final e = error(409, {
        'error': {
          'code': 'REGULARIZATION_REQUIRED',
          'rejectedValue': {'attendanceCode': 'SAR_1'},
        },
      });
      expect(RegHttpErrors.blockedSessionsFrom(e).single['attendanceCode'],
          'SAR_1');
    });

    test('no payload means fall back to a fresh gate check', () {
      final e = error(409, {'error': {'code': 'REGULARIZATION_REQUIRED'}});
      expect(RegHttpErrors.isRegularizationRequired(e), isTrue);
      expect(RegHttpErrors.blockedSessionsFrom(e), isEmpty);
    });
  });

  group('RegHttpErrors — REGULARIZATION_ALREADY_APPROVED (contract §5.7)', () {
    /// Verbatim from the contract.
    final alreadyApproved = {
      'error': {
        'code': 'REGULARIZATION_ALREADY_APPROVED',
        'rejectedValue': {'code': 'SREG_0000001', 'status': 'APPROVED'},
      },
    };

    test('is recognised by its code', () {
      expect(RegHttpErrors.isAlreadyApproved(error(409, alreadyApproved)),
          isTrue);
    });

    test('the rejected value names the request and its status', () {
      final rejected =
          RegHttpErrors.rejectedValueOf(error(409, alreadyApproved)) as Map;
      expect(rejected['code'], 'SREG_0000001');
      expect(rejected['status'], 'APPROVED');
    });

    test('a different 409 code is not an already-approved edit', () {
      final e = error(409, {'error': {'code': 'SOMETHING_ELSE'}});
      expect(RegHttpErrors.isAlreadyApproved(e), isFalse);
    });

    test('a bare 409 with no code still surfaces as already-approved', () {
      // A gateway that strips the envelope should not degrade the message to a
      // generic failure — 409 on this endpoint means only one thing.
      expect(RegHttpErrors.isAlreadyApproved(error(409, null)), isTrue);
      expect(RegHttpErrors.isAlreadyApproved(error(400, null)), isFalse);
    });
  });

  group('RegHttpErrors — robustness', () {
    test('a non-Dio error classifies as nothing', () {
      expect(RegHttpErrors.codeOf(Exception('boom')), '');
      expect(RegHttpErrors.isRegularizationRequired(Exception('boom')), isFalse);
      expect(RegHttpErrors.isAlreadyApproved(Exception('boom')), isFalse);
      expect(RegHttpErrors.blockedSessionsFrom(Exception('boom')), isEmpty);
    });

    test('a string body does not crash the parser', () {
      expect(RegHttpErrors.codeOf(error(500, 'Internal Server Error')), '');
    });

    test('a flattened envelope is still classified', () {
      // Some gateways hoist the error code to the top level.
      final e = error(409, {'code': 'REGULARIZATION_REQUIRED'});
      expect(RegHttpErrors.isRegularizationRequired(e), isTrue);
    });
  });

  group('RegConfig', () {
    test('method values match the contract', () {
      expect(RegMethod.app, 'APP');
      expect(RegMethod.web, 'WEB');
      expect(RegMethod.kiosk, 'KIOSK');
      expect(RegConfig.method, 'APP');
    });

    test('both gate pre-checks default on', () {
      // Option A for bulk: the admin sees the consequence before anyone is
      // signed in, so Skip genuinely skips.
      expect(RegConfig.preCheckSingleSignIn, isTrue);
      expect(RegConfig.preCheckBulkSignIn, isTrue);
    });

    test('the gate check is time-boxed', () {
      // The gate must never be the reason attendance is slow.
      expect(RegConfig.gateCheckTimeout.inSeconds, greaterThan(0));
      expect(RegConfig.gateCheckTimeout.inSeconds, lessThanOrEqualTo(15));
    });
  });
}
