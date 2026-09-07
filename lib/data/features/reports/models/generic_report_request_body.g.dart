// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generic_report_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$GenericReportRequestBodyToJson(
    GenericReportRequestBody instance) {
  final val = <String, dynamic>{
    'reportType': instance.reportType,
    'format': instance.format,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('schoolName', instance.schoolName);
  writeNotNull('periodType', instance.periodType);
  writeNotNull('date', instance.date);
  writeNotNull('asOfDate', instance.asOfDate);
  writeNotNull('dateFrom', instance.dateFrom);
  writeNotNull('dateTo', instance.dateTo);
  writeNotNull('startDate', instance.startDate);
  writeNotNull('endDate', instance.endDate);
  writeNotNull('roomCodes', instance.roomCodes);
  writeNotNull('classroomCodes', instance.classroomCodes);
  writeNotNull('studentCodes', instance.studentCodes);
  writeNotNull('staffCodes', instance.staffCodes);
  writeNotNull('tagCodes', instance.tagCodes);
  writeNotNull('search', instance.search);
  writeNotNull('grouping', instance.grouping);
  writeNotNull('invoiceStatuses', instance.invoiceStatuses);
  writeNotNull('transactionStatuses', instance.transactionStatuses);
  writeNotNull('transactionTypes', instance.transactionTypes);
  writeNotNull('paymentMethods', instance.paymentMethods);
  writeNotNull('schoolCode', instance.schoolCode);
  writeNotNull('organizationCode', instance.organizationCode);
  writeNotNull('generatedBy', instance.generatedBy);
  return val;
}
