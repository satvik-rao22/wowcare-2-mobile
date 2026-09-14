import 'package:equatable/equatable.dart';

/// Which persona is signing the student in — decides the conditional payload
/// shape, exactly as the sign-in form's branches did.
enum StudentSignInMode { parent, staff, kiosk }

/// Typed request for a student sign-in.
///
/// Replaces the raw `Map<String, dynamic>` payload that used to cross the domain
/// boundary. [toPayload] reproduces — key-for-key, branch-for-branch — the map
/// the sign-in form previously assembled, so the wire format is unchanged; the
/// repository still applies allowed-classroom scoping / guardian-query handling
/// on top before posting.
class StudentSignInRequest extends Equatable {
  const StudentSignInRequest({
    required this.mode,
    required this.studentCodes,
    required this.signInMethod,
    required this.latitude,
    required this.longitude,
    required this.withinGeofence,
    required this.timeZone,
    this.qrToken,
    this.notExpectedComment,
    // parent + kiosk
    this.guardianCode,
    this.pin,
    // staff
    this.attendanceDate,
    this.staffCode,
    this.classroomCode,
    this.classroomCodeByStudentCode,
    this.occurredAtIso,
  });

  final StudentSignInMode mode;
  final List<String> studentCodes;
  final String signInMethod;
  final double latitude;
  final double longitude;
  final bool withinGeofence;
  final String timeZone;

  /// Included only when set (QR scans with a non-empty token).
  final String? qrToken;

  /// Included only when set (a non-empty "not expected" comment).
  final String? notExpectedComment;

  /// parent: resolved guardian code; kiosk: the widget's guardian code.
  final String? guardianCode;

  /// parent: `widget.pin ?? ''`; kiosk: `widget.pin` (may be null — the payload
  /// carried the key regardless in kiosk mode).
  final String? pin;

  final String? attendanceDate;
  final String? staffCode;
  final String? classroomCode;
  final Map<String, String>? classroomCodeByStudentCode;

  /// ISO-8601 UTC timestamp string.
  final String? occurredAtIso;

  /// The exact wire payload the form built.
  Map<String, dynamic> toPayload() {
    final payload = <String, dynamic>{
      'studentCodes': studentCodes,
      // Kiosk overrides the method to PIN (the form set this after the base map).
      'method': mode == StudentSignInMode.kiosk ? 'PIN' : signInMethod,
      'latitude': latitude,
      'longitude': longitude,
      'withinGeofence': withinGeofence,
      'timeZone': timeZone,
    };
    if (qrToken != null) payload['qrToken'] = qrToken;
    if (notExpectedComment != null) {
      payload['notExpectedComment'] = notExpectedComment;
    }
    switch (mode) {
      case StudentSignInMode.parent:
        payload['guardianCode'] = guardianCode;
        payload['pin'] = pin;
      case StudentSignInMode.staff:
        payload['attendanceDate'] = attendanceDate;
        payload['staffCode'] = staffCode;
        payload['classroomCode'] = classroomCode;
        payload['classroomCodeByStudentCode'] = classroomCodeByStudentCode;
        payload['occurredAt'] = occurredAtIso;
      case StudentSignInMode.kiosk:
        payload['guardianCode'] = guardianCode;
        payload['pin'] = pin;
        payload['isExpected'] = true;
    }
    return payload;
  }

  @override
  List<Object?> get props => [
    mode,
    studentCodes,
    signInMethod,
    latitude,
    longitude,
    withinGeofence,
    timeZone,
    qrToken,
    notExpectedComment,
    guardianCode,
    pin,
    attendanceDate,
    staffCode,
    classroomCode,
    classroomCodeByStudentCode,
    occurredAtIso,
  ];
}
