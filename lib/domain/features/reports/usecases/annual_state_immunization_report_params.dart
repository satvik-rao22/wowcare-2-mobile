import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'report_params.dart';

/// Parameters for Annual State Immunization report generation.
///
/// Routed to the student management microservice
/// (`POST /api/v1/student/reports/generate`); only a date range and export
/// format are required.
class AnnualStateImmunizationReportParams extends Equatable
    implements ReportParams {
  const AnnualStateImmunizationReportParams({
    required this.reportType,
    required this.startDate,
    required this.endDate,
    required this.format,
    required this.schoolName,
  });

  @override
  final ReportType reportType;

  @override
  final DateTime startDate;

  final DateTime endDate;

  @override
  final String format;

  final String schoolName;

  @override
  String toCacheIdentifier() {
    return [
      reportType.backendValue,
      startDate.toIso8601String().split('T')[0],
      endDate.toIso8601String().split('T')[0],
    ].join('|');
  }

  @override
  List<Object?> get props => [
    reportType,
    startDate,
    endDate,
    format,
    schoolName,
  ];
}
