import 'package:equatable/equatable.dart';
import '../../../../domain/features/reports/entities/report_metadata_entity.dart';
import '../../../../domain/features/reports/entities/report_type.dart';

class RecentReportModel extends Equatable {
  const RecentReportModel({
    required this.reportId,
    required this.reportType,
    required this.generatedAt,
    this.assetCode,
    this.fileName,
  });

  final String reportId;
  final String reportType;
  final String generatedAt;
  final String? assetCode;
  final String? fileName;

  factory RecentReportModel.fromJson(Map<String, dynamic> json) {
    return RecentReportModel(
      reportId: json['reportId'] as String? ?? '',
      reportType: json['reportType'] as String? ?? '',
      generatedAt: json['generatedAt'] as String? ?? '',
      assetCode: json['assetCode'] as String?,
      fileName: json['fileName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'reportType': reportType,
      'generatedAt': generatedAt,
      if (assetCode != null) 'assetCode': assetCode,
      if (fileName != null) 'fileName': fileName,
    };
  }

  /// Convert model to metadata entity.
  ///
  /// Throws [FormatException] for an unrecognized `reportType`. The caller
  /// (`ReportsRepositoryImpl.getRecentReports`) catches this per-item so one
  /// unparseable entry is skipped and logged instead of either crashing the
  /// whole list or silently mislabeling the report.
  ReportMetadataEntity toEntity() {
    final reportTypeEnum = ReportType.values.firstWhere(
      (e) => e.backendValue == reportType,
      orElse: () =>
          throw FormatException('Unknown reportType in response: $reportType'),
    );

    return ReportMetadataEntity(
      reportId: reportId,
      reportType: reportTypeEnum,
      generatedAt: DateTime.tryParse(generatedAt) ?? DateTime.now(),
      assetCode: assetCode,
      fileName: fileName,
    );
  }

  @override
  List<Object?> get props => [reportId, reportType, generatedAt, assetCode, fileName];
}
