import 'package:equatable/equatable.dart';

import '../entities/report_type.dart';
import 'report_params.dart';

/// Parameters for Staff Scheduling report generation.
class StaffSchedulingReportParams extends Equatable implements ReportParams {
  const StaffSchedulingReportParams({
    required this.reportType,
    required this.startDate,
    required this.endDate,
    required this.format,
    this.classroomCodes,
  });

  @override
  final ReportType reportType;

  @override
  final DateTime startDate;

  final DateTime endDate;

  /// Optional classroom codes.
  /// null/empty means all classrooms, if supported by the backend.
  final List<String>? classroomCodes;

  @override
  final String format;

  @override
  Map<String, dynamic> toRequestBody() {
    return {
      'reportType': reportType.backendValue,
      'startDate': _formatDate(startDate),
      'endDate': _formatDate(endDate),
      if (classroomCodes != null && classroomCodes!.isNotEmpty)
        'classroomCodes': classroomCodes,
      'format': format,
    };
  }

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
