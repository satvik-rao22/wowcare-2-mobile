import 'package:equatable/equatable.dart';
import 'report_type.dart';

class ReportMetadataEntity extends Equatable {
  const ReportMetadataEntity({
    required this.reportId,
    required this.reportType,
    required this.generatedAt,
    this.assetCode,
    this.fileName,
  });

  final String reportId;
  final ReportType reportType;
  final DateTime generatedAt;
  final String? assetCode;
  final String? fileName;

  ReportMetadataEntity copyWith({
    String? reportId,
    ReportType? reportType,
    DateTime? generatedAt,
    String? assetCode,
    String? fileName,
  }) {
    return ReportMetadataEntity(
      reportId: reportId ?? this.reportId,
      reportType: reportType ?? this.reportType,
      generatedAt: generatedAt ?? this.generatedAt,
      assetCode: assetCode ?? this.assetCode,
      fileName: fileName ?? this.fileName,
    );
  }

  @override
  List<Object?> get props => [reportId, reportType, generatedAt, assetCode, fileName];
}
