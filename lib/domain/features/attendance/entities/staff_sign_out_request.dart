import 'package:equatable/equatable.dart';

/// Typed request for a staff sign-out.
///
/// Replaces the raw `Map<String, dynamic>` payload that used to cross the
/// domain boundary. [toPayload] reproduces — key-for-key, branch-for-branch —
/// the single map the sign-out form previously assembled, so the wire format is
/// unchanged; the repository still applies allowed-classroom scoping on top
/// (admin/bulk only, i.e. `!isSelf`) before posting.
///
/// Unlike staff SIGN-IN, the sign-out form only ever built ONE payload shape
/// (it always routes through the admin/bulk-style body, and [isSelf] merely
/// selects the endpoint) — so there is no mode enum here. The only conditional
/// keys are [pin] / [qrToken], mutually exclusive exactly as the form had them.
class StaffSignOutRequest extends Equatable {
  const StaffSignOutRequest({
    required this.attendanceDate,
    required this.staffCode,
    required this.staffCodes,
    required this.classroomCode,
    required this.classroomCodeByStaffCode,
    required this.signOutMethod,
    required this.latitude,
    required this.longitude,
    required this.withinGeofence,
    required this.timeZone,
    required this.occurredAtIso,
    this.isKiosk = false,
    this.pin,
    this.qrToken,
  });

  final String attendanceDate;
  final String staffCode;
  final List<String> staffCodes;
  final String classroomCode;
  final Map<String, String> classroomCodeByStaffCode;

  /// Base sign-out method (`'QR'`/`'APP'`/`'GPS'`). A kiosk sign-out overrides
  /// this to `'PIN'` (see [isKiosk]).
  final String signOutMethod;

  final double latitude;
  final double longitude;
  final bool withinGeofence;
  final String timeZone;

  /// ISO-8601 UTC timestamp string (`occurredAt.toUtc().toIso8601String()`).
  final String occurredAtIso;

  /// Kiosk device sign-out. Forces `method` to `'PIN'` and gates whether [pin]
  /// is carried (`isKiosk && pin != null`) — and that branch wins over
  /// [qrToken].
  final bool isKiosk;

  /// Kiosk PIN. Included when `isKiosk && pin != null`.
  final String? pin;

  /// QR token. Included when set AND the kiosk-pin branch did not fire.
  final String? qrToken;

  /// The exact wire payload the form built.
  Map<String, dynamic> toPayload() {
    final payload = <String, dynamic>{
      'attendanceDate': attendanceDate,
      'staffCode': staffCode,
      'staffCodes': staffCodes,
      'classroomCode': classroomCode,
      'classroomCodeByStaffCode': classroomCodeByStaffCode,
      // Kiosk overrides the method to PIN.
      'method': isKiosk ? 'PIN' : signOutMethod,
      'latitude': latitude,
      'longitude': longitude,
      'withinGeofence': withinGeofence,
      'timeZone': timeZone,
      'occurredAt': occurredAtIso,
    };
    // pin wins over qrToken (kiosk PIN and QR are mutually exclusive here).
    if (isKiosk && pin != null) {
      payload['pin'] = pin;
    } else if (qrToken != null) {
      payload['qrToken'] = qrToken;
    }
    return payload;
  }

  @override
  List<Object?> get props => [
    attendanceDate,
    staffCode,
    staffCodes,
    classroomCode,
    classroomCodeByStaffCode,
    signOutMethod,
    latitude,
    longitude,
    withinGeofence,
    timeZone,
    occurredAtIso,
    isKiosk,
    pin,
    qrToken,
  ];
}
