import 'package:equatable/equatable.dart';

/// Which endpoint/shape a staff sign-in targets — decides the conditional
/// payload the form previously assembled by branching on `useSelfEndpoint`.
///
/// [self]  → POST /staff-attendance-records/sign-in/self body.
/// [adminBulk] → the admin bulk endpoint (can sign in other staff).
enum StaffSignInMode { self, adminBulk }

/// Typed request for a staff sign-in.
///
/// Replaces the raw `Map<String, dynamic>` payload that used to cross the
/// domain boundary. [toPayload] reproduces — key-for-key, branch-for-branch —
/// the map the sign-in form previously built for each of its two shapes, so the
/// wire format is unchanged; the repository still applies allowed-classroom
/// scoping on top (admin bulk only) before posting.
class StaffSignInRequest extends Equatable {
  const StaffSignInRequest({
    required this.mode,
    required this.staffCode,
    required this.signInMethod,
    required this.latitude,
    required this.longitude,
    required this.withinGeofence,
    required this.timeZone,
    required this.occurredAtIso,
    required this.isExpectedToday,
    // self
    this.isKiosk = false,
    this.pin,
    this.qrToken,
    // admin bulk
    this.attendanceDate,
    this.staffCodes,
    this.classroomCode,
    this.classroomCodeByStaffCode,
    // both (conditional)
    this.notExpectedComment,
  });

  final StaffSignInMode mode;
  final String staffCode;

  /// Base sign-in method (`'QR'`/`'PIN'`/`'GPS'`/`'APP'`). In [self] mode a
  /// kiosk sign-in overrides this to `'PIN'` (see [isKiosk]); admin bulk uses
  /// it verbatim.
  final String signInMethod;
  final double latitude;
  final double longitude;
  final bool withinGeofence;
  final String timeZone;

  /// ISO-8601 UTC timestamp string (`occurredAt.toUtc().toIso8601String()`).
  final String occurredAtIso;
  final bool isExpectedToday;

  /// [self] only: kiosk device sign-in. Forces `method` to `'PIN'` and gates
  /// whether [pin] is carried (`isKiosk && pin != null`).
  final bool isKiosk;

  /// [self] only: kiosk PIN. Included when `isKiosk && pin != null` — and that
  /// branch wins over [qrToken].
  final String? pin;

  /// [self] only: QR token. Included when set AND the pin branch did not fire.
  final String? qrToken;

  final String? attendanceDate;
  final List<String>? staffCodes;
  final String? classroomCode;
  final Map<String, String>? classroomCodeByStaffCode;

  /// Included only when set (a non-empty, already-trimmed "not expected"
  /// comment). Applies to both modes.
  final String? notExpectedComment;

  /// The exact wire payload the form built for this mode.
  Map<String, dynamic> toPayload() {
    switch (mode) {
      case StaffSignInMode.self:
        final payload = <String, dynamic>{
          'staffCode': staffCode,
          // Kiosk overrides the method to PIN.
          'method': isKiosk ? 'PIN' : signInMethod,
          'latitude': latitude,
          'longitude': longitude,
          'withinGeofence': withinGeofence,
          'timeZone': timeZone,
          'occurredAt': occurredAtIso,
          'isExpectedToday': isExpectedToday,
        };
        // pin wins over qrToken (kiosk PIN and QR are mutually exclusive here).
        if (isKiosk && pin != null) {
          payload['pin'] = pin;
        } else if (qrToken != null) {
          payload['qrToken'] = qrToken;
        }
        if (notExpectedComment != null) {
          payload['notExpectedComment'] = notExpectedComment;
        }
        return payload;
      case StaffSignInMode.adminBulk:
        final payload = <String, dynamic>{
          'isExpectedToday': isExpectedToday,
          'attendanceDate': attendanceDate,
          'staffCode': staffCode,
          'staffCodes': staffCodes,
          'classroomCode': classroomCode,
          'classroomCodeByStaffCode': classroomCodeByStaffCode,
          'method': signInMethod,
          'latitude': latitude,
          'longitude': longitude,
          'withinGeofence': withinGeofence,
          'timeZone': timeZone,
          'occurredAt': occurredAtIso,
        };
        if (notExpectedComment != null) {
          payload['notExpectedComment'] = notExpectedComment;
        }
        return payload;
    }
  }

  @override
  List<Object?> get props => [
    mode,
    staffCode,
    signInMethod,
    latitude,
    longitude,
    withinGeofence,
    timeZone,
    occurredAtIso,
    isExpectedToday,
    isKiosk,
    pin,
    qrToken,
    attendanceDate,
    staffCodes,
    classroomCode,
    classroomCodeByStaffCode,
    notExpectedComment,
  ];
}
