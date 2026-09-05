import 'dart:typed_data';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';

/// Arguments for standard report generation screens.
class ReportFormArgs {
  final List<String>? classrooms;
  final List<String>? students;
  final List<String>? staff;
  final List<String>? tags;

  const ReportFormArgs({
    this.classrooms,
    this.students,
    this.staff,
    this.tags,
  });
}

/// Arguments for billing specific report generation screens.
class BillingReportFormArgs {
  final ReportType reportType;
  final String title;
  final List<String>? classrooms;
  final List<String>? students;

  const BillingReportFormArgs({
    required this.reportType,
    required this.title,
    this.classrooms,
    this.students,
  });
}

/// Arguments for the report file viewer screen.
class ReportFileViewerArgs {
  final Uint8List fileData;
  final String fileName;
  final String fileType;

  const ReportFileViewerArgs({
    required this.fileData,
    required this.fileName,
    required this.fileType,
  });
}
