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
    this.message,
  });

  final String reportId;
  final String reportType;
  final String generatedAt;
  final String? assetCode;
  final String? fileName;
  final String? message;

  factory ReportResponseModel.fromJson(Map<String, dynamic> json) {
    // Handle wrapped response format: {success, message, data: {reportId, ...}, timestamp, error}
    final dataObject = json['data'] as Map<String, dynamic>?;
    final reportData = dataObject ?? json;

    return ReportResponseModel(
      reportId: reportData['reportId'] as String? ?? '',
      reportType: reportData['reportType'] as String? ?? '',
      generatedAt: reportData['generatedAt'] as String? ?? '',
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
  List<Object?> get props => [reportId, reportType, generatedAt, assetCode, fileName, message];
}
