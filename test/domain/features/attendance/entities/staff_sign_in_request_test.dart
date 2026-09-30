import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_sign_in_request.dart';

void main() {
  group('StaffSignInRequest.toPayload', () {
    test('self + kiosk pin: method forced to PIN and pin wins over qrToken', () {
      const request = StaffSignInRequest(
        mode: StaffSignInMode.self,
        staffCode: 'STF-1',
        signInMethod: 'QR', // base value; kiosk overrides to PIN
        latitude: 12.34,
        longitude: 56.78,
        withinGeofence: true,
        timeZone: 'Asia/Kolkata',
        occurredAtIso: '2026-08-27T09:00:00.000Z',
        isExpectedToday: true,
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
        'staffCode': 'STF-1',
        'method': 'PIN',
        'latitude': 12.34,
        'longitude': 56.78,
        'withinGeofence': true,
        'timeZone': 'Asia/Kolkata',
        'occurredAt': '2026-08-27T09:00:00.000Z',
        'isExpectedToday': true,
        'pin': 'PIN-9',
      });
    });

    test('self QR (non-kiosk): includes qrToken, no pin', () {
      const request = StaffSignInRequest(
        mode: StaffSignInMode.self,
        staffCode: 'STF-1',
        signInMethod: 'QR',
        latitude: 0,
        longitude: 0,
        withinGeofence: true,
        timeZone: 'Asia/Kolkata',
        occurredAtIso: '2026-08-27T09:00:00.000Z',
        isExpectedToday: true,
        qrToken: 'QR-TOKEN',
      );

      final payload = request.toPayload();
      expect(payload.containsKey('pin'), isFalse);
      expect(payload, <String, dynamic>{
        'staffCode': 'STF-1',
        'method': 'QR',
        'latitude': 0.0,
        'longitude': 0.0,
        'withinGeofence': true,
        'timeZone': 'Asia/Kolkata',
        'occurredAt': '2026-08-27T09:00:00.000Z',
        'isExpectedToday': true,
        'qrToken': 'QR-TOKEN',
      });
    });

    test('self GPS + not-expected comment: base keys + notExpectedComment', () {
      const request = StaffSignInRequest(
        mode: StaffSignInMode.self,
        staffCode: 'STF-1',
        signInMethod: 'GPS',
        latitude: 1.5,
        longitude: 2.5,
        withinGeofence: false,
        timeZone: 'Asia/Kolkata',
        occurredAtIso: '2026-08-27T09:00:00.000Z',
        isExpectedToday: false,
        notExpectedComment: 'Late arrival',
      );

      final payload = request.toPayload();
      expect(payload.containsKey('pin'), isFalse);
      expect(payload.containsKey('qrToken'), isFalse);
      expect(payload, <String, dynamic>{
        'staffCode': 'STF-1',
        'method': 'GPS',
        'latitude': 1.5,
        'longitude': 2.5,
        'withinGeofence': false,
        'timeZone': 'Asia/Kolkata',
        'occurredAt': '2026-08-27T09:00:00.000Z',
        'isExpectedToday': false,
        'notExpectedComment': 'Late arrival',
      });
    });

    test('admin bulk: isExpectedToday-first shape with staffCodes + map, and '
        'method pinned to APP regardless of signInMethod', () {
      const request = StaffSignInRequest(
        mode: StaffSignInMode.adminBulk,
        staffCode: 'STF-1',
        signInMethod: 'PIN',
        latitude: 1.1,
        longitude: 2.2,
        withinGeofence: false,
        timeZone: 'Asia/Kolkata',
        occurredAtIso: '2026-08-27T09:00:00.000Z',
        isExpectedToday: false,
        attendanceDate: '2026-08-27',
        staffCodes: ['STF-1', 'STF-2'],
        classroomCode: 'CLS_1',
        classroomCodeByStaffCode: {'STF-1': 'CLS_1', 'STF-2': 'CLS_2'},
        notExpectedComment: 'Bulk override',
      );

      expect(request.toPayload(), <String, dynamic>{
        'isExpectedToday': false,
        'attendanceDate': '2026-08-27',
        'staffCode': 'STF-1',
        'staffCodes': ['STF-1', 'STF-2'],
        'classroomCode': 'CLS_1',
        'classroomCodeByStaffCode': {'STF-1': 'CLS_1', 'STF-2': 'CLS_2'},
        // Not 'PIN': an admin signing several staff in from the roster is
        // doing it in the app, not at a kiosk or a geofence, so bulk pins
        // the method to APP. See the payload builder for the history.
        'method': 'APP',
        'latitude': 1.1,
        'longitude': 2.2,
        'withinGeofence': false,
        'timeZone': 'Asia/Kolkata',
        'occurredAt': '2026-08-27T09:00:00.000Z',
        'notExpectedComment': 'Bulk override',
      });
    });
  });
}
