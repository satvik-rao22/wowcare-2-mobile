// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_report_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecentReportModel _$RecentReportModelFromJson(Map<String, dynamic> json) =>
    RecentReportModel(
      reportId: json['reportId'] as String? ?? '',
      reportType: json['reportType'] as String? ?? '',
      generatedAt: json['generatedAt'] as String? ?? '',
      assetCode: json['assetCode'] as String?,
      fileName: json['fileName'] as String?,
    );

Map<String, dynamic> _$RecentReportModelToJson(RecentReportModel instance) {
  final val = <String, dynamic>{
    'reportId': instance.reportId,
    'reportType': instance.reportType,
    'generatedAt': instance.generatedAt,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('assetCode', instance.assetCode);
  writeNotNull('fileName', instance.fileName);
  return val;
}
