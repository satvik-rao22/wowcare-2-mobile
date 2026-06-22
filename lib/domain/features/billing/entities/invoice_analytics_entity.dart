/// Domain entity for `GET /api/v1/invoices/analytics`.
class InvoiceAnalyticsEntity {
  const InvoiceAnalyticsEntity({
    required this.revenue,
    required this.invoiced,
    required this.refunds,
    required this.subsidies,
  });

  final List<AnalyticsMonthValueEntity> revenue;
  final List<AnalyticsMonthValueEntity> invoiced;
  final List<AnalyticsMonthValueEntity> refunds;
  final List<AnalyticsSubsidyEntity> subsidies;
}

class AnalyticsMonthValueEntity {
  const AnalyticsMonthValueEntity({required this.name, required this.value});

  final String name;
  final double value;
}

class AnalyticsSubsidyEntity {
  const AnalyticsSubsidyEntity({
    required this.name,
    required this.invoiced,
    required this.received,
    required this.balance,
  });

  final String name;
  final double invoiced;
  final double received;
  final double balance;
}
