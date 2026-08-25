import 'package:equatable/equatable.dart';

class MarkAbsentRequestModel extends Equatable {
  const MarkAbsentRequestModel({
    required this.staffCode,
    required this.studentCodes,
    required this.absenceFromDate,
    required this.absenceToDate,
    required this.absenceReason,
    required this.absenceNotes,
    required this.classroomCode,
    this.markAbsentMethod = 'APP',
    this.isExpectedTodayByStudentCode = const <String, bool>{},
  });

  final String staffCode;
  final List<String> studentCodes;
  final String absenceFromDate;
  final String absenceToDate;
  final String absenceReason;

  /// Keyed by studentCode.
  final Map<String, String> absenceNotes;
  final String classroomCode;
  final String markAbsentMethod;
  final Map<String, bool> isExpectedTodayByStudentCode;

  Map<String, dynamic> toJson() {
    return {
      'staffCode': staffCode,
      'studentCodes': studentCodes,
      'absenceFromDate': absenceFromDate,
      'absenceToDate': absenceToDate,
      'absenceReason': absenceReason,
      'absenceNotes': absenceNotes,
      'classroomCode': classroomCode,
      'markAbsentMethod': markAbsentMethod,
      if (isExpectedTodayByStudentCode.isNotEmpty)
        'isExpectedTodayByStudentCode': isExpectedTodayByStudentCode,
    };
  }

  @override
  List<Object?> get props => [
    staffCode,
    studentCodes,
    absenceFromDate,
    absenceToDate,
    absenceReason,
    absenceNotes,
    classroomCode,
    markAbsentMethod,
    isExpectedTodayByStudentCode,
  ];
}

class StudentAbsenceRecordModel extends Equatable {
  const StudentAbsenceRecordModel({
    required this.code,
    required this.studentCode,
    required this.absenceDate,
    required this.absenceFromDate,
    required this.absenceToDate,
    required this.absenceReason,
    required this.absenceNote,
    required this.classroomCode,
    this.markAbsentMethod,
    this.isExpectedToday,
  });

  final String code;
  final String studentCode;
  final String absenceDate;
  final String absenceFromDate;
  final String absenceToDate;
  final String absenceReason;
  final String absenceNote;
  final String classroomCode;
  final String? markAbsentMethod;
  final bool? isExpectedToday;

  factory StudentAbsenceRecordModel.fromJson(Map<String, dynamic> json) {
    return StudentAbsenceRecordModel(
      code: (json['code'] ?? '').toString(),
      studentCode: (json['studentCode'] ?? '').toString(),
      absenceDate: (json['absenceDate'] ?? '').toString(),
      absenceFromDate: (json['absenceFromDate'] ?? '').toString(),
      absenceToDate: (json['absenceToDate'] ?? '').toString(),
      absenceReason: (json['absenceReason'] ?? '').toString(),
      absenceNote: (json['absenceNote'] ?? '').toString(),
      classroomCode: (json['classroomCode'] ?? '').toString(),
      markAbsentMethod: json['markAbsentMethod'] as String?,
      isExpectedToday: json['isExpectedToday'] as bool?,
    );
  }

  @override
  List<Object?> get props => [
    code,
    studentCode,
    absenceDate,
    absenceFromDate,
    absenceToDate,
    absenceReason,
    absenceNote,
    classroomCode,
    markAbsentMethod,
    isExpectedToday,
  ];
}

class MarkAbsentResponseModel extends Equatable {
  const MarkAbsentResponseModel({required this.message, required this.records});

  final String message;
  final List<StudentAbsenceRecordModel> records;

  factory MarkAbsentResponseModel.fromJson(Map<String, dynamic> json) {
    final message = (json['message'] ?? '').toString();
    final data = json['data'];
    final records = (data is List)
        ? data
              .whereType<Map>()
              .map(
                (e) => StudentAbsenceRecordModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
        : <StudentAbsenceRecordModel>[];
    return MarkAbsentResponseModel(message: message, records: records);
  }

  @override
  List<Object?> get props => [message, records];
}
