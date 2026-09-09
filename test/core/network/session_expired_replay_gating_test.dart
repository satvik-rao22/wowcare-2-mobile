import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/session_expired_interceptor.dart';

void main() {
  group('SessionExpiredInterceptor.shouldReplayAfterRefresh', () {
    test('a request flagged noAutoReplay (non-idempotent mutation) opts OUT of '
        'automatic replay after a token refresh', () {
      final flagged = RequestOptions(path: '/students', method: 'POST')
        ..extra[kNoAutoReplayExtraKey] = true;
      expect(SessionExpiredInterceptor.shouldReplayAfterRefresh(flagged), isFalse);
    });

    test('an ordinary request (no flag) still replays as before — Attendance and '
        'idempotent reads/updates are unaffected', () {
      final normal = RequestOptions(path: '/attendance/records', method: 'POST');
      expect(SessionExpiredInterceptor.shouldReplayAfterRefresh(normal), isTrue);
    });
  });
}
