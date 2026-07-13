class BillingStatementEntity {
  const BillingStatementEntity({
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
}
