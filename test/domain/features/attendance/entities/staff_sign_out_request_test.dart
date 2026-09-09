import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_sign_out_request.dart';

void main() {
  group('StaffSignOutRequest.toPayload', () {
    test('admin/GPS (non-kiosk, non-QR): base map, no pin, no qrToken', () {
      const request = StaffSignOutRequest(
        attendanceDate: '2026-08-27',
        staffCode: 'STF-1',
        staffCodes: ['STF-1', 'STF-2'],
        classroomCode: 'CLS_1',
        classroomCodeByStaffCode: {'STF-1': 'CLS_1', 'STF-2': 'CLS_2'},
        signOutMethod: 'APP',
        latitude: 1.1,
        longitude: 2.2,
        withinGeofence: false,
        timeZone: 'Asia/Kolkata',
        occurredAtIso: '2026-08-27T09:00:00.000Z',
      );

      final payload = request.toPayload();
      expect(payload.containsKey('pin'), isFalse);
      expect(payload.containsKey('qrToken'), isFalse);
      expect(payload, <String, dynamic>{
        'attendanceDate': '2026-08-27',
        'staffCode': 'STF-1',
        'staffCodes': ['STF-1', 'STF-2'],
        'classroomCode': 'CLS_1',
        'classroomCodeByStaffCode': {'STF-1': 'CLS_1', 'STF-2': 'CLS_2'},
        'method': 'APP',
        'latitude': 1.1,
        'longitude': 2.2,
        'withinGeofence': false,
        'timeZone': 'Asia/Kolkata',
        'occurredAt': '2026-08-27T09:00:00.000Z',
      });
    });

    test('QR self (non-kiosk): includes qrToken, no pin', () {
      const request = StaffSignOutRequest(
        attendanceDate: '2026-08-27',
        staffCode: 'STF-1',
        staffCodes: ['STF-1'],
        classroomCode: '',
        classroomCodeByStaffCode: {},
        signOutMethod: 'QR',
        latitude: 0,
        longitude: 0,
        withinGeofence: true,
        timeZone: 'Asia/Kolkata',
        occurredAtIso: '2026-08-27T09:00:00.000Z',
        qrToken: 'QR-TOKEN',
      );

      final payload = request.toPayload();
      expect(payload.containsKey('pin'), isFalse);
      expect(payload, <String, dynamic>{
        'attendanceDate': '2026-08-27',
        'staffCode': 'STF-1',
        'staffCodes': ['STF-1'],
        'classroomCode': '',
        'classroomCodeByStaffCode': <String, String>{},
        'method': 'QR',
        'latitude': 0.0,
        'longitude': 0.0,
        'withinGeofence': true,
        'timeZone': 'Asia/Kolkata',
        'occurredAt': '2026-08-27T09:00:00.000Z',
        'qrToken': 'QR-TOKEN',
      });
    });

    test('kiosk + pin: method forced to PIN and pin wins over qrToken', () {
      const request = StaffSignOutRequest(
        attendanceDate: '2026-08-27',
        staffCode: 'STF-1',
        staffCodes: ['STF-1'],
        classroomCode: 'CLS_1',
        classroomCodeByStaffCode: {'STF-1': 'CLS_1'},
        signOutMethod: 'GPS', // base value; kiosk overrides to PIN
        latitude: 12.34,
        longitude: 56.78,
        withinGeofence: true,
        timeZone: 'Asia/Kolkata',
        occurredAtIso: '2026-08-27T09:00:00.000Z',
        isKiosk: true,
        pin: 'PIN-9',
        // A qrToken is also present, but the kiosk pin branch must win.
        qrToken: 'QR-TOKEN',
      );

      final payload = request.toPayload();
      expect(payload['method'], 'PIN');
      expect(payload.containsKey('pin'), isTrue);
      expect(payload.containsKey('qrToken'), isFalse);
      expect(payload, <String, dynamic>{
        'attendanceDate': '2026-08-27',
        'staffCode': 'STF-1',
        'staffCodes': ['STF-1'],
        'classroomCode': 'CLS_1',
        'classroomCodeByStaffCode': {'STF-1': 'CLS_1'},
        'method': 'PIN',
        'latitude': 12.34,
        'longitude': 56.78,
        'withinGeofence': true,
        'timeZone': 'Asia/Kolkata',
        'occurredAt': '2026-08-27T09:00:00.000Z',
        'pin': 'PIN-9',
      });
    });

    test('kiosk without pin: method PIN, no pin, no qrToken', () {
      const request = StaffSignOutRequest(
        attendanceDate: '2026-08-27',
        staffCode: 'STF-1',
        staffCodes: ['STF-1'],
        classroomCode: 'CLS_1',
        classroomCodeByStaffCode: {'STF-1': 'CLS_1'},
        signOutMethod: 'GPS',
        latitude: 0,
        longitude: 0,
        withinGeofence: true,
        timeZone: 'Asia/Kolkata',
        occurredAtIso: '2026-08-27T09:00:00.000Z',
        isKiosk: true,
        // pin is null (kiosk with no PIN captured) and qrToken null.
      );

      final payload = request.toPayload();
      expect(payload['method'], 'PIN');
      expect(payload.containsKey('pin'), isFalse);
      expect(payload.containsKey('qrToken'), isFalse);
      expect(payload, <String, dynamic>{
        'attendanceDate': '2026-08-27',
        'staffCode': 'STF-1',
        'staffCodes': ['STF-1'],
        'classroomCode': 'CLS_1',
        'classroomCodeByStaffCode': {'STF-1': 'CLS_1'},
        'method': 'PIN',
        'latitude': 0.0,
        'longitude': 0.0,
        'withinGeofence': true,
        'timeZone': 'Asia/Kolkata',
        'occurredAt': '2026-08-27T09:00:00.000Z',
      });
    });
  });
}
