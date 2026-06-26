import 'package:wowcare/domain/features/billing/entities/billing_statement_entity.dart';

class BillingStatementModel {
  const BillingStatementModel({
    required this.code,
    required this.subscriberCode,
    required this.school,
    required this.statementType,
    required this.periodStart,
    required this.periodEnd,
    this.generatedAt,
    required this.generatedBy,
    required this.status,
    this.assetCode,
  });

  final String code;
  final String subscriberCode;
  final String school;
  final String statementType;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime? generatedAt;
  final String generatedBy;
  final String status;
  final String? assetCode;

  factory BillingStatementModel.fromJson(Map<String, dynamic> json) {
    return BillingStatementModel(
      code: (json['code'] as String?) ?? '',
      subscriberCode: (json['subscriberCode'] as String?) ?? '',
      school: (json['school'] as String?) ?? '',
      statementType: (json['statementType'] as String?) ?? '',
      periodStart: DateTime.parse((json['periodStart'] as String)),
      periodEnd: DateTime.parse((json['periodEnd'] as String)),
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : null,
      generatedBy: (json['generatedBy'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      assetCode: json['assetCode'] as String?,
    );
  }

  BillingStatementEntity toEntity() => BillingStatementEntity(
        code: code,
        subscriberCode: subscriberCode,
        school: school,
        statementType: statementType,
        periodStart: periodStart,
        periodEnd: periodEnd,
        generatedAt: generatedAt,
        generatedBy: generatedBy,
        status: status,
        assetCode: assetCode,
      );
}
