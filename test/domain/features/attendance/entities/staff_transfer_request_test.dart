import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_transfer_request.dart';

void main() {
  group('StaffTransferRequest.toPayload', () {
    test('reproduces exactly the map the staff transfer form used to build', () {
      const request = StaffTransferRequest(
        staffCode: 'STF-1',
        staffCodes: ['STF-1', 'STF-2'],
        toClassroomCode: 'CLS_1',
        toClassroomCodeByStaffCode: {'STF-1': 'CLS_1', 'STF-2': 'CLS_1'},
        timeZone: 'Asia/Kolkata',
        transferredAt: '2026-08-27T09:00:00.000Z',
      );

      expect(request.toPayload(), <String, dynamic>{
        'staffCode': 'STF-1',
        'staffCodes': ['STF-1', 'STF-2'],
        'toClassroomCode': 'CLS_1',
        'toClassroomCodeByStaffCode': {'STF-1': 'CLS_1', 'STF-2': 'CLS_1'},
        'transferReason': 'Transferred via mobile app',
        'timeZone': 'Asia/Kolkata',
        'transferredAt': '2026-08-27T09:00:00.000Z',
      });
    });

    test('transferReason defaults to the generic placeholder the form sent', () {
      const request = StaffTransferRequest(
        staffCode: 'STF-1',
        staffCodes: ['STF-1'],
        toClassroomCode: 'CLS_1',
        toClassroomCodeByStaffCode: {'STF-1': 'CLS_1'},
        timeZone: 'Asia/Kolkata',
        transferredAt: '2026-08-27T09:00:00.000Z',
      );

      expect(request.toPayload()['transferReason'], 'Transferred via mobile app');
    });
  });
}
