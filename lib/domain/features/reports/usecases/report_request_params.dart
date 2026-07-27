import 'package:equatable/equatable.dart';
import '../entities/report_type.dart';
import 'report_params.dart';

class ReportRequestParams extends Equatable implements ReportParams {
  const ReportRequestParams({
    required this.reportType,
    required this.startDate,
    this.endDate,
    this.format = '',
    this.classroomCodes,
    this.studentCodes,
    this.staffCodes,
    this.tagCodes,
    this.schoolName,
    this.search,
  });

  @override
  final ReportType reportType;

  @override
  final DateTime startDate;

  @override
  final String format;

  final DateTime? endDate;
  final List<String>? classroomCodes;
  final List<String>? studentCodes;
  final List<String>? staffCodes;
  final List<String>? tagCodes;
  final String? schoolName;
  final String? search;

  ReportRequestParams copyWith({
    ReportType? reportType,
    DateTime? startDate,
    DateTime? endDate,
    String? format,
    List<String>? classroomCodes,
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
      format: format ?? this.format,
      classroomCodes: classroomCodes ?? this.classroomCodes,
      studentCodes: studentCodes ?? this.studentCodes,
      staffCodes: staffCodes ?? this.staffCodes,
      tagCodes: tagCodes ?? this.tagCodes,
      schoolName: schoolName ?? this.schoolName,
      search: search ?? this.search,
    );
  }

  /// Convert params to request body format for API.
  Map<String, dynamic> toRequestBody() {
    final Map<String, dynamic> body = {
      'reportType': reportType.backendValue,
      'startDate': startDate.toIso8601String().split('T')[0],
      if (endDate != null) 'endDate': endDate!.toIso8601String().split('T')[0],
      if (schoolName != null) 'schoolName': schoolName,
      'format': format,
    };

    // Map field names based on report type for API compatibility.
    // Confirmed against the web client's verified payloads per report type.
    if (reportType == ReportType.studentAbsent ||
        reportType == ReportType.studentAttendancePerStudent ||
        reportType == ReportType.staffAttendancePerStaff ||
        reportType == ReportType.emergencyContacts) {
      // These reports use roomCodes instead of classroomCodes
      if (classroomCodes != null && classroomCodes!.isNotEmpty) {
        body['roomCodes'] = classroomCodes;
      }
    } else {
      // Other reports use classroomCodes
      if (classroomCodes != null && classroomCodes!.isNotEmpty) {
        body['classroomCodes'] = classroomCodes;
      }
    }

    // Add optional fields
    if (studentCodes != null && studentCodes!.isNotEmpty) {
      body['studentCodes'] = studentCodes;
    }
    if (staffCodes != null && staffCodes!.isNotEmpty) {
      body['staffCodes'] = staffCodes;
    }
    if (tagCodes != null && tagCodes!.isNotEmpty) {
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
      if (classroomCodes != null && classroomCodes!.isNotEmpty)
        'classrooms=${classroomCodes!.join(',')}',
      if (studentCodes != null && studentCodes!.isNotEmpty)
        'students=${studentCodes!.join(',')}',
      if (staffCodes != null && staffCodes!.isNotEmpty)
        'staff=${staffCodes!.join(',')}',
      if (tagCodes != null && tagCodes!.isNotEmpty)
        'tags=${tagCodes!.join(',')}',
      if (search != null && search!.trim().isNotEmpty)
        'search=${search!.trim().toLowerCase()}',
    ];
    return parts.join('|');
  }

  @override
  List<Object?> get props => [
    reportType,
    startDate,
    endDate,
    format,
    classroomCodes,
    studentCodes,
    staffCodes,
    tagCodes,
    schoolName,
    search,
  ];
}
