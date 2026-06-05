import 'package:equatable/equatable.dart';
import '../../../../domain/features/reports/entities/report_entity.dart';
import '../../../../domain/features/reports/entities/report_type.dart';

class ReportResponseModel extends Equatable {
  const ReportResponseModel({
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

  factory ReportResponseModel.fromJson(Map<String, dynamic> json) {
    return ReportResponseModel(
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

  /// Convert model to domain entity.
  ReportEntity toEntity() {
    ReportType? reportTypeEnum;
    try {
      reportTypeEnum =
          ReportType.values.firstWhere((e) => e.backendValue == reportType);
    } catch (_) {
      // Fallback if report type is unknown
      reportTypeEnum = ReportType.studentDailyAttendance;
    }

    return ReportEntity(
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
