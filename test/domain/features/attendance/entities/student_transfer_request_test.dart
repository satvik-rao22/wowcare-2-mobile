import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/student_transfer_request.dart';

void main() {
  group('StudentTransferRequest.toPayload', () {
    test('reproduces exactly the map the transfer form used to build', () {
      const request = StudentTransferRequest(
        transferDate: '2026-08-27',
        staffCode: 'STF-1',
        studentCodes: ['STU-1', 'STU-2'],
        toClassroomCode: 'CLS_1',
        toClassroomCodeByStudentCode: {'STU-1': 'CLS_1', 'STU-2': 'CLS_1'},
        timeZone: 'Asia/Kolkata',
        transferredAt: '2026-08-27T09:00:00.000Z',
      );

      // This is the wire contract the backend depends on — key-for-key the same
      // map the form assembled before StudentTransferRequest existed.
      expect(request.toPayload(), <String, dynamic>{
        'transferDate': '2026-08-27',
        'staffCode': 'STF-1',
        'studentCodes': ['STU-1', 'STU-2'],
        'toClassroomCode': 'CLS_1',
        'toClassroomCodeByStudentCode': {'STU-1': 'CLS_1', 'STU-2': 'CLS_1'},
        'transferReason': 'Transferred via mobile app',
        'timeZone': 'Asia/Kolkata',
        'transferredAt': '2026-08-27T09:00:00.000Z',
      });
    });

    test('transferReason defaults to the generic placeholder the form sent', () {
      const request = StudentTransferRequest(
        transferDate: '2026-08-27',
        staffCode: 'STF-1',
        studentCodes: ['STU-1'],
        toClassroomCode: 'CLS_1',
        toClassroomCodeByStudentCode: {'STU-1': 'CLS_1'},
        timeZone: 'Asia/Kolkata',
        transferredAt: '2026-08-27T09:00:00.000Z',
      );

      expect(request.toPayload()['transferReason'], 'Transferred via mobile app');
    });
  });
}
