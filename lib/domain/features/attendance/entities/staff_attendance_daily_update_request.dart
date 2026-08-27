import 'package:equatable/equatable.dart';

/// Typed request for patching a staff daily attendance record (edit sign-in /
/// sign-out times).
///
/// Replaces the raw `Map<String, dynamic>` body that used to cross the domain
/// boundary. [toPayload] reproduces exactly the conditional map the edit cubit
/// previously built, so the wire format is unchanged:
///  - `signedInAt` / `signedOutAt` are included only when set;
///  - `signedInMethod` / `signedOutMethod` ('APP') are included only when the
///    matching time is set AND this is not a transfer record.
class StaffAttendanceDailyUpdateRequest extends Equatable {
  const StaffAttendanceDailyUpdateRequest({
    required this.staffCode,
    required this.timeZone,
    this.signedInAtIso,
    this.signedOutAtIso,
    this.isTransferRecord = false,
  });

  final String staffCode;
  final String timeZone;

  /// ISO-8601 UTC timestamp string, or null when the sign-in time is unchanged.
  final String? signedInAtIso;

  /// ISO-8601 UTC timestamp string, or null when the sign-out time is unchanged.
  final String? signedOutAtIso;
  final bool isTransferRecord;

  /// The exact wire payload — key-for-key identical to the map the cubit built.
  Map<String, dynamic> toPayload() => <String, dynamic>{
    'staffCode': staffCode,
    if (signedInAtIso != null) 'signedInAt': signedInAtIso,
    if (signedOutAtIso != null) 'signedOutAt': signedOutAtIso,
    if (!isTransferRecord && signedInAtIso != null) 'signedInMethod': 'APP',
    if (!isTransferRecord && signedOutAtIso != null) 'signedOutMethod': 'APP',
    'timeZone': timeZone,
  };

  @override
  List<Object?> get props => [
    staffCode,
    timeZone,
    signedInAtIso,
    signedOutAtIso,
    isTransferRecord,
  ];
}
