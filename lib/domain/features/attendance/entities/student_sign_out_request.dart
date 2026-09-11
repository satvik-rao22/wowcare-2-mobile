import 'package:equatable/equatable.dart';

/// Which persona is signing the student out — decides the conditional payload
/// shape, exactly as the sign-out form's branches did.
enum StudentSignOutMode { parent, staff, kiosk }

/// Typed request for a student sign-out.
///
/// Replaces the raw `Map<String, dynamic>` payload that used to cross the domain
/// boundary. [toPayload] reproduces — key-for-key, branch-for-branch — the map
/// the sign-out form previously assembled, so the wire format is unchanged; the
/// repository still applies allowed-classroom scoping / guardian-query handling
/// on top before posting.
///
/// (Sign-out has no `notExpectedComment` key — otherwise the shape matches
/// sign-in.)
class StudentSignOutRequest extends Equatable {
  const StudentSignOutRequest({
    required this.mode,
    required this.studentCodes,
    required this.signOutMethod,
    required this.latitude,
    required this.longitude,
    required this.withinGeofence,
    required this.timeZone,
    this.qrToken,
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

  final StudentSignOutMode mode;
  final List<String> studentCodes;
  final String signOutMethod;
  final double latitude;
  final double longitude;
  final bool withinGeofence;
  final String timeZone;
  final String? qrToken;
  final String? guardianCode;
  final String? pin;
  final String? attendanceDate;
  final String? staffCode;
  final String? classroomCode;
  final Map<String, String>? classroomCodeByStudentCode;
  final String? occurredAtIso;

  /// The exact wire payload the form built.
  Map<String, dynamic> toPayload() {
    final payload = <String, dynamic>{
      'studentCodes': studentCodes,
      // Kiosk overrides the method to PIN (the form set this after the base map).
      'method': mode == StudentSignOutMode.kiosk ? 'PIN' : signOutMethod,
      'latitude': latitude,
      'longitude': longitude,
      'withinGeofence': withinGeofence,
      'timeZone': timeZone,
    };
    if (qrToken != null) payload['qrToken'] = qrToken;
    switch (mode) {
      case StudentSignOutMode.parent:
        payload['guardianCode'] = guardianCode;
        payload['pin'] = pin;
      case StudentSignOutMode.staff:
        payload['attendanceDate'] = attendanceDate;
        payload['staffCode'] = staffCode;
        payload['classroomCode'] = classroomCode;
        payload['classroomCodeByStudentCode'] = classroomCodeByStudentCode;
        payload['occurredAt'] = occurredAtIso;
      case StudentSignOutMode.kiosk:
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
    signOutMethod,
    latitude,
    longitude,
    withinGeofence,
    timeZone,
    qrToken,
    guardianCode,
    pin,
    attendanceDate,
    staffCode,
    classroomCode,
    classroomCodeByStudentCode,
    occurredAtIso,
  ];
}
