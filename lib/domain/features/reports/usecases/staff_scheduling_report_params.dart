import 'package:equatable/equatable.dart';

import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'report_params.dart';

/// Parameters for Staff Scheduling report generation.
class StaffSchedulingReportParams extends Equatable implements ReportParams {
  const StaffSchedulingReportParams({
    required this.reportType,
    required this.startDate,
    required this.endDate,
    required this.format,
    required this.schoolName,
    this.classroomCodes,
  });

  @override
  final ReportType reportType;

  @override
  final DateTime startDate;
  final String schoolName;

  final DateTime endDate;

  /// Optional classroom codes.
  /// null/empty means all classrooms, if supported by the backend.
  final List<String>? classroomCodes;

  @override
  final String format;

  @override
  String toCacheIdentifier() {
    final sortedClassrooms =
        classroomCodes == null ? <String>[] : List<String>.from(classroomCodes!)
          ..sort();

    final parts = <String>[
      reportType.backendValue,
      _formatDate(startDate),
      _formatDate(endDate),
      if (sortedClassrooms.isNotEmpty)
        'classrooms=${sortedClassrooms.join(',')}',
      'format=$format',
      'schoolName=$schoolName',
    ];

    return parts.join('|');
  }

  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }

  @override
  List<Object?> get props => [
    reportType,
    startDate,
    endDate,
    classroomCodes,
    format,
  ];
}
