import 'package:equatable/equatable.dart';

/// Typed request for a staff classroom transfer.
///
/// Replaces the raw `Map<String, dynamic>` payload that used to cross the
/// domain boundary. [toPayload] reproduces exactly the map the staff transfer
/// form previously built, so the wire format is unchanged — the repository
/// still applies allowed-classroom scoping on top before posting.
class StaffTransferRequest extends Equatable {
  const StaffTransferRequest({
    required this.staffCode,
    required this.staffCodes,
    required this.toClassroomCode,
    required this.toClassroomCodeByStaffCode,
    required this.timeZone,
    required this.transferredAt,
    this.transferReason = 'Transferred via mobile app',
  });

  final String staffCode;
  final List<String> staffCodes;
  final String toClassroomCode;
  final Map<String, String> toClassroomCodeByStaffCode;
  final String timeZone;

  /// ISO-8601 UTC timestamp string.
  final String transferredAt;
  final String transferReason;

  /// The exact wire payload — key-for-key identical to the map the form built.
  Map<String, dynamic> toPayload() => <String, dynamic>{
    'staffCode': staffCode,
    'staffCodes': staffCodes,
    'toClassroomCode': toClassroomCode,
    'toClassroomCodeByStaffCode': toClassroomCodeByStaffCode,
    'transferReason': transferReason,
    'timeZone': timeZone,
    'transferredAt': transferredAt,
  };

  @override
  List<Object?> get props => [
    staffCode,
    staffCodes,
    toClassroomCode,
    toClassroomCodeByStaffCode,
    timeZone,
    transferredAt,
    transferReason,
  ];
}
