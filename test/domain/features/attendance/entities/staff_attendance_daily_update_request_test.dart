import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_attendance_daily_update_request.dart';

void main() {
  group('StaffAttendanceDailyUpdateRequest.toPayload', () {
    test('both times, non-transfer: includes times + APP methods', () {
      const request = StaffAttendanceDailyUpdateRequest(
        staffCode: 'STF-1',
        timeZone: 'Asia/Kolkata',
        signedInAtIso: '2026-08-27T09:00:00.000Z',
        signedOutAtIso: '2026-08-27T17:00:00.000Z',
      );

      expect(request.toPayload(), <String, dynamic>{
        'staffCode': 'STF-1',
        'signedInAt': '2026-08-27T09:00:00.000Z',
        'signedOutAt': '2026-08-27T17:00:00.000Z',
        'signedInMethod': 'APP',
        'signedOutMethod': 'APP',
        'timeZone': 'Asia/Kolkata',
      });
    });

    test('only sign-in changed: omits sign-out keys', () {
      const request = StaffAttendanceDailyUpdateRequest(
        staffCode: 'STF-1',
        timeZone: 'Asia/Kolkata',
        signedInAtIso: '2026-08-27T09:00:00.000Z',
      );

      expect(request.toPayload(), <String, dynamic>{
        'staffCode': 'STF-1',
        'signedInAt': '2026-08-27T09:00:00.000Z',
        'signedInMethod': 'APP',
        'timeZone': 'Asia/Kolkata',
      });
    });

    test('only sign-out changed: omits sign-in keys', () {
      const request = StaffAttendanceDailyUpdateRequest(
        staffCode: 'STF-1',
        timeZone: 'Asia/Kolkata',
        signedOutAtIso: '2026-08-27T17:00:00.000Z',
      );

      expect(request.toPayload(), <String, dynamic>{
        'staffCode': 'STF-1',
        'signedOutAt': '2026-08-27T17:00:00.000Z',
        'signedOutMethod': 'APP',
        'timeZone': 'Asia/Kolkata',
      });
    });

    test('transfer record: times included but method keys are omitted', () {
      const request = StaffAttendanceDailyUpdateRequest(
        staffCode: 'STF-1',
        timeZone: 'Asia/Kolkata',
        signedInAtIso: '2026-08-27T09:00:00.000Z',
        signedOutAtIso: '2026-08-27T17:00:00.000Z',
        isTransferRecord: true,
      );

      expect(request.toPayload(), <String, dynamic>{
        'staffCode': 'STF-1',
        'signedInAt': '2026-08-27T09:00:00.000Z',
        'signedOutAt': '2026-08-27T17:00:00.000Z',
        'timeZone': 'Asia/Kolkata',
      });
    });
  });
}
