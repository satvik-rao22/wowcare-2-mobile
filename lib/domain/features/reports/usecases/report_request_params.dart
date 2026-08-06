import 'package:equatable/equatable.dart';
import '../entities/report_type.dart';
import 'report_params.dart';

class ReportRequestParams extends Equatable implements ReportParams {
  const ReportRequestParams({
    required this.reportType,
    required this.startDate,
    this.endDate,
    this.date,
    this.format = '',
    this.roomCodes,
    this.studentCodes,
    this.staffCodes,
    this.tagCodes,
    required this.schoolName,
    this.search,
  });

  @override
  final ReportType reportType;

  @override
  final DateTime startDate;

  final DateTime? date;

  @override
  final String format;

  final DateTime? endDate;

  final List<String>? roomCodes;
  final List<String>? studentCodes;
  final List<String>? staffCodes;
  final List<String>? tagCodes;
  final String? schoolName;
  final String? search;

  ReportRequestParams copyWith({
    ReportType? reportType,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? date,
    String? format,
    List<String>? roomCodes,
    List<String>? studentCodes,
    List<String>? staffCodes,
    List<String>? tagCodes,
    String? schoolName,
    String? search,
  }) {
    return ReportRequestParams(
      reportType: reportType ?? this.reportType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      date: date ?? this.date,
      format: format ?? this.format,
      roomCodes: roomCodes ?? this.roomCodes,
      studentCodes: studentCodes ?? this.studentCodes,
      staffCodes: staffCodes ?? this.staffCodes,
      tagCodes: tagCodes ?? this.tagCodes,
      schoolName: schoolName ?? this.schoolName,
      search: search ?? this.search,
    );
  }

  /// Convert params to request body format for API.
  // Map<String, dynamic> toRequestBody() {
  //   final Map<String, dynamic> body = {
  //     'reportType': reportType.backendValue,
  //     'startDate': startDate.toIso8601String().split('T')[0],
  //     if (endDate != null) 'endDate': endDate!.toIso8601String().split('T')[0],
  //     if (schoolName != null && schoolName!.trim().isNotEmpty)
  //       'schoolName': schoolName,
  //     'format': format,
  //   };
  Map<String, dynamic> toRequestBody() {
    final Map<String, dynamic> body = {
      'reportType': reportType.backendValue,
      'format': format,
      if (schoolName != null && schoolName!.trim().isNotEmpty)
        'schoolName': schoolName,
    };

    if (reportType == ReportType.studentDailyAttendance) {
      body['date'] = (date ?? startDate).toIso8601String().split('T')[0];
    } else {
      body['startDate'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) {
        body['endDate'] = endDate!.toIso8601String().split('T')[0];
      }
    }

    // Existing room/classroom mapping...

    // Map field names based on report type for API compatibility.
    // Confirmed against the web client's verified payloads per report type.
    if (reportType == ReportType.studentAbsent ||
        reportType == ReportType.studentAttendancePerStudent ||
        reportType == ReportType.staffAttendancePerStaff ||
        reportType == ReportType.emergencyContacts ||
        reportType == ReportType.studentIncident) {
      // These reports use roomCodes instead of classroomCodes.
      if (roomCodes != null) {
        body['roomCodes'] = roomCodes;
      }
    } else {
      // Other reports use classroomCodes.
      if (roomCodes != null) {
        body['roomCodes'] = roomCodes;
      }
    }

    // Add optional fields.
    if (studentCodes != null) {
      body['studentCodes'] = studentCodes;
    }
    if (staffCodes != null) {
      body['staffCodes'] = staffCodes;
    }
    if (tagCodes != null) {
      body['tagCodes'] = tagCodes;
    }
    if (search != null && search!.trim().isNotEmpty) {
      body['search'] = search!.trim();
    }

    return body;
  }

  /// Build cache identifier from params.
  String toCacheIdentifier() {
    final parts = <String>[
      reportType.backendValue,
      startDate.toIso8601String().split('T')[0],
      if (endDate != null) endDate!.toIso8601String().split('T')[0],
      if (roomCodes != null && roomCodes!.isNotEmpty)
        'classrooms=${roomCodes!.join(',')}',
      if (studentCodes != null && studentCodes!.isNotEmpty)
        'students=${studentCodes!.join(',')}',
      if (staffCodes != null && staffCodes!.isNotEmpty)
        'staff=${staffCodes!.join(',')}',
      if (tagCodes != null && tagCodes!.isNotEmpty)
        'tags=${tagCodes!.join(',')}',
      if (search != null && search!.trim().isNotEmpty)
        'search=${search!.trim().toLowerCase()}',
      if (schoolName != null && schoolName!.trim().isNotEmpty)
        'school=${schoolName!.trim().toLowerCase()}',
      if (format.isNotEmpty) 'format=$format',
      if (date != null) 'date=${date!.toIso8601String().split('T')[0]}',
    ];
    return parts.join('|');
  }

  @override
  List<Object?> get props => [
    reportType,
    startDate,
    endDate,
    date,
    format,
    roomCodes,
    studentCodes,
    staffCodes,
    tagCodes,
    schoolName,
    search,
  ];
}
