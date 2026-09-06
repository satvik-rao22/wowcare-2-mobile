import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'report_params.dart';

/// Parameters for Staff Details report generation.
///
/// Captures field selections (13 total staff fields) and maps them to
/// boolean include flags in the backend payload.
class StaffDetailsReportParams extends Equatable implements ReportParams {
  const StaffDetailsReportParams({
    required this.reportType,
    this.startDate,
    this.endDate,
    required this.staffFieldsSelected,
    required this.statusFilter,
    required this.format,
    required this.schoolName,
    this.classroomCodes,
  });

  @override
  final ReportType reportType;

  @override
  final DateTime? startDate;
  final String schoolName;

  final DateTime? endDate;

  /// Set of selected staff field names (e.g., {'Name', 'Email ID', 'Designation'})
  final Set<String> staffFieldsSelected;

  /// Status filter value (e.g., 'Active Staff', 'Inactive Staff', 'All Staff')
  final String statusFilter;

  @override
  final String format;

  /// Optional classroom codes (empty = all classrooms)
  final List<String>? classroomCodes;

  @override
  String toCacheIdentifier() {
    final parts = <String>[
      'STAFF_DETAILS',
      if (startDate != null) startDate!.toIso8601String().split('T')[0],
      if (endDate != null) endDate!.toIso8601String().split('T')[0],
      'staffFields=${staffFieldsSelected.toList()..sort()}',
      'status=$statusFilter',
      if (classroomCodes != null && classroomCodes!.isNotEmpty)
        'classrooms=${classroomCodes!.join(',')}',
    ];

    return parts.join('|');
  }

  @override
  List<Object?> get props => [
    reportType,
    startDate,
    endDate,
    staffFieldsSelected,
    statusFilter,
    format,
    schoolName,
    classroomCodes,
  ];
}
