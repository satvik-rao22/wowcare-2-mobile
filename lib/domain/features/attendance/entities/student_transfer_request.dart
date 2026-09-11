import 'package:equatable/equatable.dart';

/// Typed request for a student classroom transfer.
///
/// Replaces the raw `Map<String, dynamic>` payload that used to cross the
/// domain boundary. [toPayload] reproduces exactly the map the transfer form
/// previously built, so the wire format the backend receives is unchanged — the
/// repository still applies allowed-classroom scoping on top before posting.
class StudentTransferRequest extends Equatable {
  const StudentTransferRequest({
    required this.transferDate,
    required this.staffCode,
    required this.studentCodes,
    required this.toClassroomCode,
    required this.toClassroomCodeByStudentCode,
    required this.timeZone,
    required this.transferredAt,
    this.transferReason = 'Transferred via mobile app',
  });

  final String transferDate;
  final String staffCode;
  final List<String> studentCodes;
  final String toClassroomCode;
  final Map<String, String> toClassroomCodeByStudentCode;
  final String timeZone;

  /// ISO-8601 UTC timestamp string (e.g. `transferredAt.toUtc().toIso8601String()`).
  final String transferredAt;
  final String transferReason;

  /// The exact wire payload — key-for-key identical to the map the form built.
  Map<String, dynamic> toPayload() => <String, dynamic>{
    'transferDate': transferDate,
    'staffCode': staffCode,
    'studentCodes': studentCodes,
    'toClassroomCode': toClassroomCode,
    'toClassroomCodeByStudentCode': toClassroomCodeByStudentCode,
    'transferReason': transferReason,
    'timeZone': timeZone,
    'transferredAt': transferredAt,
  };

  @override
  List<Object?> get props => [
    transferDate,
    staffCode,
    studentCodes,
    toClassroomCode,
    toClassroomCodeByStudentCode,
    timeZone,
    transferredAt,
    transferReason,
  ];
}
