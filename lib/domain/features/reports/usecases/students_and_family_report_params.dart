import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'report_params.dart';

/// Parameters for Students & Family report generation.
///
/// Captures field selections (20 total: 13 student + 7 guardian/pickup fields)
/// and maps them to boolean include flags in the backend payload.
class StudentsAndFamilyReportParams extends Equatable implements ReportParams {
  const StudentsAndFamilyReportParams({
    required this.reportType,
    required this.startDate,
    required this.endDate,
    required this.studentFieldsSelected,
    required this.parentFieldsSelected,
    required this.statusFilter,
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

  /// Set of selected student field names (e.g., {'Full Name', 'DOB', ...})
  final Set<String> studentFieldsSelected;

  /// Set of selected guardian/parent field names
  final Set<String> parentFieldsSelected;

  /// Status filter value (e.g., 'Active', 'Inactive', 'Upcoming')
  final String statusFilter;

  @override
  final String format;

  final String schoolName;

  /// Optional classroom codes (empty = all classrooms)
  final List<String>? classroomCodes;

  /// Optional tag codes (empty = all tags)
  final List<String>? tagCodes;

  @override
  String toCacheIdentifier() {
    final parts = <String>[
      'STUDENTS_AND_FAMILY',
      startDate.toIso8601String().split('T')[0],
      endDate.toIso8601String().split('T')[0],
      'studentFields=${studentFieldsSelected.toList()..sort()}',
      'parentFields=${parentFieldsSelected.toList()..sort()}',
      'statusFilter=$statusFilter',
      if (classroomCodes != null && classroomCodes!.isNotEmpty)
        'roomCodes=${classroomCodes!.join(',')}',
      if (tagCodes != null && tagCodes!.isNotEmpty)
        'tagCodes=${tagCodes!.join(',')}',
    ];
    return parts.join('|');
  }

  @override
  List<Object?> get props => [
    reportType,
    startDate,
    endDate,
    studentFieldsSelected,
    parentFieldsSelected,
    statusFilter,
    format,
    schoolName,
    classroomCodes,
    tagCodes,
  ];
}
