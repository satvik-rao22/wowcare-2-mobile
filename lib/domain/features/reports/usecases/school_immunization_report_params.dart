import 'package:equatable/equatable.dart';
import '../entities/report_type.dart';
import 'report_params.dart';

/// Parameters for School Immunization report generation.
///
/// Captures vaccine selection, status filters, and parent info flags
/// and maps them to the backend payload format.
class SchoolImmunizationReportParams extends Equatable implements ReportParams {
  const SchoolImmunizationReportParams({
    required this.reportType,
    required this.startDate,
    required this.endDate,
    required this.vaccineCodes,
    required this.statusFilters,
    required this.includeParentName,
    required this.includeParentEmail,
    required this.format,
    required this.schoolName,
    this.classroomCodes,
    this.tagCodes,
  });

  @override
  final ReportType reportType;

  @override
  final DateTime startDate;

  final DateTime endDate;

  /// List of vaccine codes to filter by (e.g., ['DTaP', 'Polio', 'MMR'])
  final List<String> vaccineCodes;

  /// List of status filters (e.g., ['ACTIVE'], ['UPCOMING'])
  final List<String> statusFilters;

  /// Whether to include parent name in the report
  final bool includeParentName;

  final String schoolName;

  /// Whether to include parent email in the report
  final bool includeParentEmail;

  @override
  final String format;

  /// Optional classroom codes (empty = all classrooms)
  final List<String>? classroomCodes;

  /// Optional tag codes (empty = all tags)
  final List<String>? tagCodes;

  @override
  Map<String, dynamic> toRequestBody() {
    return {
      'reportType': 'IMMUNIZATION',
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate.toIso8601String().split('T')[0],
      'vaccineCodes': vaccineCodes,
      'schoolName': schoolName,
      // Key names confirmed against the web client's verified IMMUNIZATION
      // payload: roomCodes/tagCodes/statusFilter, not classrooms/tags/statuses.
      'statusFilter': statusFilters,
      'includeParentName': includeParentName,
      'includeParentEmail': includeParentEmail,
      if (classroomCodes != null && classroomCodes!.isNotEmpty)
        'roomCodes': classroomCodes,
      if (tagCodes != null && tagCodes!.isNotEmpty) 'tagCodes': tagCodes,
      'format': format,
    };
  }

  @override
  String toCacheIdentifier() {
    final parts = <String>[
      'IMMUNIZATION',
      startDate.toIso8601String().split('T')[0],
      endDate.toIso8601String().split('T')[0],
      'vaccines=${vaccineCodes.join(',')}',
      'schoolName=$schoolName',
      'statuses=${statusFilters.join(',')}',
      'parentName=$includeParentName',

      'parentEmail=$includeParentEmail',
      if (classroomCodes != null && classroomCodes!.isNotEmpty)
        'classrooms=${classroomCodes!.join(',')}',
      if (tagCodes != null && tagCodes!.isNotEmpty)
        'tags=${tagCodes!.join(',')}',
    ];
    return parts.join('|');
  }

  @override
  List<Object?> get props => [
    reportType,
    startDate,
    endDate,
    vaccineCodes,
    statusFilters,
    includeParentName,
    schoolName,
    includeParentEmail,
    format,
    classroomCodes,
    tagCodes,
  ];
}
