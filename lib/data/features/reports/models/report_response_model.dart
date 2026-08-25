import 'package:equatable/equatable.dart';
import '../../../../core/util/app_time.dart';
import '../../../../domain/features/reports/entities/report_entity.dart';
import '../../../../domain/features/reports/entities/report_type.dart';

class ReportResponseModel extends Equatable {
  const ReportResponseModel({
    required this.reportId,
    required this.reportType,
    required this.generatedAt,
    this.assetCode,
    this.fileName,
    this.message,
  });

  final String reportId;
  final String reportType;
  final String generatedAt;
  final String? assetCode;
  final String? fileName;
  final String? message;

  /// Parses the wrapped response format: `{success, message, data: {reportId, ...}, timestamp, error}`.
  ///
  /// Throws [FormatException] when the backend reports failure
  /// (`success: false`) or when a required field is missing, instead of
  /// silently defaulting to `''` — a missing `reportId`/`assetCode` means
  /// the report can never be downloaded, so surfacing that as a generation
  /// failure immediately is more useful than a UI that says "generated"
  /// for a report nobody can open.
  factory ReportResponseModel.fromJson(Map<String, dynamic> json) {
    final success = json['success'];
    if (success is bool && !success) {
      throw FormatException(
        'Report generation failed: ${json['message'] ?? json['error'] ?? 'unknown error'}',
      );
    }

    final dataObject = json['data'] as Map<String, dynamic>?;
    final reportData = dataObject ?? json;

    final reportId = reportData['reportId'] as String?;
    final reportType = reportData['reportType'] as String?;
    final generatedAt = reportData['generatedAt'] as String?;

    if (reportId == null || reportId.isEmpty) {
      throw FormatException(
        'Report response missing required field "reportId": $reportData',
      );
    }
    if (reportType == null || reportType.isEmpty) {
      throw FormatException(
        'Report response missing required field "reportType": $reportData',
      );
    }
    if (generatedAt == null || generatedAt.isEmpty) {
      throw FormatException(
        'Report response missing required field "generatedAt": $reportData',
      );
    }

    return ReportResponseModel(
      reportId: reportId,
      reportType: reportType,
      generatedAt: generatedAt,
      assetCode: reportData['assetCode'] as String?,
      fileName: reportData['fileName'] as String?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'reportType': reportType,
      'generatedAt': generatedAt,
      if (assetCode != null) 'assetCode': assetCode,
      if (fileName != null) 'fileName': fileName,
      if (message != null) 'message': message,
    };
  }

  /// Convert model to domain entity.
  ///
  /// Throws [FormatException] for an unrecognized `reportType` instead of
  /// silently mislabeling the report as Student Daily Attendance.
  ReportEntity toEntity() {
    final reportTypeEnum = ReportType.values.firstWhere(
      (e) => e.backendValue == reportType,
      orElse: () =>
          throw FormatException('Unknown reportType in response: $reportType'),
    );

    return ReportEntity(
      reportId: reportId,
      reportType: reportTypeEnum,
      generatedAt: DateTime.tryParse(generatedAt) ?? AppTime.nowUtc(),
      assetCode: assetCode,
      fileName: fileName,
    );
  }

  @override
  List<Object?> get props => [
    reportId,
    reportType,
    generatedAt,
    assetCode,
    fileName,
    message,
  ];
}
