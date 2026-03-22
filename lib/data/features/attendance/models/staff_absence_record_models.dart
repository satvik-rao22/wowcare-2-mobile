import 'package:equatable/equatable.dart';

class StaffMarkAbsentRequestModel extends Equatable {
  const StaffMarkAbsentRequestModel({
    required this.staffCode,
    required this.staffCodes,
    required this.absenceFromDate,
    required this.absenceToDate,
    required this.absenceReason,
    required this.absenceType,
    required this.absenceNotes,
  });

  final String staffCode; // marker staff (who is marking absent)
  final List<String> staffCodes; // staff that are absent
  final String absenceFromDate;
  final String absenceToDate;
  final String absenceReason;
  final String absenceType;
  final Map<String, String> absenceNotes; // keyed by staffCode

  Map<String, dynamic> toJson() {
    return {
      'staffCode': staffCode,
      'staffCodes': staffCodes,
      'absenceFromDate': absenceFromDate,
      'absenceToDate': absenceToDate,
      'absenceReason': absenceReason,
      'absenceType': absenceType,
      'absenceNotes': absenceNotes,
    };
  }

  @override
  List<Object?> get props => [
        staffCode,
        staffCodes,
        absenceFromDate,
        absenceToDate,
        absenceReason,
        absenceType,
        absenceNotes,
      ];
}

class StaffAbsenceRecordModel extends Equatable {
  const StaffAbsenceRecordModel({
    required this.code,
    required this.staffCode,
    required this.absenceDate,
    required this.absenceFromDate,
    required this.absenceToDate,
    required this.absenceReason,
    required this.absenceType,
    required this.absenceNote,
  });

  final String code;
  final String staffCode;
  final String absenceDate;
  final String absenceFromDate;
  final String absenceToDate;
  final String absenceReason;
  final String absenceType;
  final String absenceNote;

  factory StaffAbsenceRecordModel.fromJson(Map<String, dynamic> json) {
    return StaffAbsenceRecordModel(
      code: (json['code'] ?? '').toString(),
      staffCode: (json['staffCode'] ?? '').toString(),
      absenceDate: (json['absenceDate'] ?? '').toString(),
      absenceFromDate: (json['absenceFromDate'] ?? '').toString(),
      absenceToDate: (json['absenceToDate'] ?? '').toString(),
      absenceReason: (json['absenceReason'] ?? '').toString(),
      absenceType: (json['absenceType'] ?? '').toString(),
      absenceNote: (json['absenceNote'] ?? '').toString(),
    );
  }

  @override
  List<Object?> get props => [
        code,
        staffCode,
        absenceDate,
        absenceFromDate,
        absenceToDate,
        absenceReason,
        absenceType,
        absenceNote,
      ];
}

class StaffMarkAbsentResponseModel extends Equatable {
  const StaffMarkAbsentResponseModel({
    required this.message,
    required this.records,
  });

  final String message;
  final List<StaffAbsenceRecordModel> records;

  factory StaffMarkAbsentResponseModel.fromJson(Map<String, dynamic> json) {
    final message = (json['message'] ?? '').toString();
    final data = json['data'];
    final records = (data is List)
        ? data
            .whereType<Map>()
            .map((e) => StaffAbsenceRecordModel.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <StaffAbsenceRecordModel>[];
    return StaffMarkAbsentResponseModel(
      message: message,
      records: records,
    );
  }

  @override
  List<Object?> get props => [message, records];
}

