import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/student_sign_out_request.dart';

void main() {
  group('StudentSignOutRequest.toPayload', () {
    test('parent (GPS): base keys + guardianCode + pin', () {
      const request = StudentSignOutRequest(
        mode: StudentSignOutMode.parent,
        studentCodes: ['STU-1'],
        signOutMethod: 'GPS',
        latitude: 12.34,
        longitude: 56.78,
        withinGeofence: true,
        timeZone: 'Asia/Kolkata',
        guardianCode: 'GRD-1',
        pin: '1234',
      );

      expect(request.toPayload(), <String, dynamic>{
        'studentCodes': ['STU-1'],
        'method': 'GPS',
        'latitude': 12.34,
        'longitude': 56.78,
        'withinGeofence': true,
        'timeZone': 'Asia/Kolkata',
        'guardianCode': 'GRD-1',
        'pin': '1234',
      });
    });

    test('parent QR scan: includes qrToken', () {
      const request = StudentSignOutRequest(
        mode: StudentSignOutMode.parent,
        studentCodes: ['STU-1'],
        signOutMethod: 'QR',
        latitude: 0,
        longitude: 0,
        withinGeofence: true,
        timeZone: 'Asia/Kolkata',
        qrToken: 'QR-TOKEN',
        guardianCode: 'GRD-1',
        pin: '',
      );

      expect(request.toPayload()['qrToken'], 'QR-TOKEN');
      expect(request.toPayload().containsKey('notExpectedComment'), isFalse);
    });

    test('staff (APP): base keys + attendance/staff/classroom/occurredAt', () {
      const request = StudentSignOutRequest(
        mode: StudentSignOutMode.staff,
        studentCodes: ['STU-1'],
        signOutMethod: 'APP',
        latitude: 0,
        longitude: 0,
        withinGeofence: false,
        timeZone: 'Asia/Kolkata',
        attendanceDate: '2026-08-27',
        staffCode: 'STF-1',
        classroomCode: 'CLS_1',
        classroomCodeByStudentCode: {'STU-1': 'CLS_1'},
        occurredAtIso: '2026-08-27T17:00:00.000Z',
      );

      expect(request.toPayload(), <String, dynamic>{
        'studentCodes': ['STU-1'],
        'method': 'APP',
        'latitude': 0,
        'longitude': 0,
        'withinGeofence': false,
        'timeZone': 'Asia/Kolkata',
        'attendanceDate': '2026-08-27',
        'staffCode': 'STF-1',
        'classroomCode': 'CLS_1',
        'classroomCodeByStudentCode': {'STU-1': 'CLS_1'},
        'occurredAt': '2026-08-27T17:00:00.000Z',
      });
    });

    test('kiosk overrides method to PIN + guardianCode + pin (may be null) + isExpected', () {
      const request = StudentSignOutRequest(
        mode: StudentSignOutMode.kiosk,
        studentCodes: ['STU-1'],
        signOutMethod: 'APP',
        latitude: 0,
        longitude: 0,
        withinGeofence: false,
        timeZone: 'Asia/Kolkata',
        guardianCode: 'GRD-1',
        pin: null,
      );

      expect(request.toPayload(), <String, dynamic>{
        'studentCodes': ['STU-1'],
        'method': 'PIN',
        'latitude': 0,
        'longitude': 0,
        'withinGeofence': false,
        'timeZone': 'Asia/Kolkata',
        'guardianCode': 'GRD-1',
        'pin': null,
        'isExpected': true,
      });
    });
  });
}
