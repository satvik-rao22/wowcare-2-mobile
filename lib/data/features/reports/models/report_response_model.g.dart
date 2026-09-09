// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportResponseModel _$ReportResponseModelFromJson(Map<String, dynamic> json) =>
    ReportResponseModel(
      reportId: json['reportId'] as String,
      reportType: json['reportType'] as String,
      generatedAt: json['generatedAt'] as String,
      assetCode: json['assetCode'] as String?,
      fileName: json['fileName'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$ReportResponseModelToJson(ReportResponseModel instance) {
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
  writeNotNull('message', instance.message);
  return val;
}
