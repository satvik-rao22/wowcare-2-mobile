import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/student_sign_in_request.dart';

void main() {
  group('StudentSignInRequest.toPayload', () {
    test('parent (GPS): base keys + guardianCode + pin', () {
      const request = StudentSignInRequest(
        mode: StudentSignInMode.parent,
        studentCodes: ['STU-1'],
        signInMethod: 'GPS',
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

    test('parent QR scan + not-expected comment: includes qrToken + comment', () {
      const request = StudentSignInRequest(
        mode: StudentSignInMode.parent,
        studentCodes: ['STU-1'],
        signInMethod: 'QR',
        latitude: 0,
        longitude: 0,
        withinGeofence: true,
        timeZone: 'Asia/Kolkata',
        qrToken: 'QR-TOKEN',
        notExpectedComment: 'Walk-in',
        guardianCode: 'GRD-1',
        pin: '',
      );

      expect(request.toPayload(), <String, dynamic>{
        'studentCodes': ['STU-1'],
        'method': 'QR',
        'latitude': 0,
        'longitude': 0,
        'withinGeofence': true,
        'timeZone': 'Asia/Kolkata',
        'qrToken': 'QR-TOKEN',
        'notExpectedComment': 'Walk-in',
        'guardianCode': 'GRD-1',
        'pin': '',
      });
    });

    test('staff (APP): base keys + attendance/staff/classroom/occurredAt', () {
      const request = StudentSignInRequest(
        mode: StudentSignInMode.staff,
        studentCodes: ['STU-1', 'STU-2'],
        signInMethod: 'APP',
        latitude: 0,
        longitude: 0,
        withinGeofence: false,
        timeZone: 'Asia/Kolkata',
        attendanceDate: '2026-08-27',
        staffCode: 'STF-1',
        classroomCode: 'CLS_1',
        classroomCodeByStudentCode: {'STU-1': 'CLS_1', 'STU-2': 'CLS_1'},
        occurredAtIso: '2026-08-27T09:00:00.000Z',
      );

      expect(request.toPayload(), <String, dynamic>{
        'studentCodes': ['STU-1', 'STU-2'],
        'method': 'APP',
        'latitude': 0,
        'longitude': 0,
        'withinGeofence': false,
        'timeZone': 'Asia/Kolkata',
        'attendanceDate': '2026-08-27',
        'staffCode': 'STF-1',
        'classroomCode': 'CLS_1',
        'classroomCodeByStudentCode': {'STU-1': 'CLS_1', 'STU-2': 'CLS_1'},
        'occurredAt': '2026-08-27T09:00:00.000Z',
      });
    });

    test('kiosk overrides method to PIN + guardianCode + pin + isExpected; '
        'a null pin is still carried', () {
      const request = StudentSignInRequest(
        mode: StudentSignInMode.kiosk,
        studentCodes: ['STU-1'],
        signInMethod: 'APP', // base value; kiosk overrides to PIN
        latitude: 0,
        longitude: 0,
        withinGeofence: false,
        timeZone: 'Asia/Kolkata',
        guardianCode: 'GRD-1',
        pin: null,
      );

      final payload = request.toPayload();
      expect(payload['method'], 'PIN');
      expect(payload.containsKey('pin'), isTrue);
      expect(payload['pin'], isNull);
      expect(payload, <String, dynamic>{
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
