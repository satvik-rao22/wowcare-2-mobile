/// Response model for `GET /api/v1/invoices/analytics`.
class InvoiceAnalyticsModel {
  const InvoiceAnalyticsModel({
    required this.revenue,
    required this.invoiced,
    required this.refunds,
    required this.subsidies,
  });

  final List<AnalyticsMonthValueModel> revenue;
  final List<AnalyticsMonthValueModel> invoiced;
  final List<AnalyticsMonthValueModel> refunds;
  final List<AnalyticsSubsidyModel> subsidies;

  factory InvoiceAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    List<T> parseList<T>(
      String key,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      final raw = data[key];
      if (raw is! List) return [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList();
    }

    return InvoiceAnalyticsModel(
      revenue: parseList('revenue', AnalyticsMonthValueModel.fromJson),
      invoiced: parseList('invoiced', AnalyticsMonthValueModel.fromJson),
      refunds: parseList('refunds', AnalyticsMonthValueModel.fromJson),
      subsidies: parseList('subsidies', AnalyticsSubsidyModel.fromJson),
    );
  }
}

class AnalyticsMonthValueModel {
  const AnalyticsMonthValueModel({required this.name, required this.value});

  final String name;
  final double value;

  factory AnalyticsMonthValueModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsMonthValueModel(
      name: (json['name'] as String?) ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AnalyticsSubsidyModel {
  const AnalyticsSubsidyModel({
    required this.name,
    required this.invoiced,
    required this.received,
    required this.balance,
  });

  final String name;
  final double invoiced;
  final double received;
  final double balance;

  factory AnalyticsSubsidyModel.fromJson(Map<String, dynamic> json) {
    double d(String k) => (json[k] as num?)?.toDouble() ?? 0;
    return AnalyticsSubsidyModel(
      name: (json['name'] as String?) ?? '',
      invoiced: d('invoiced'),
      received: d('received'),
      balance: d('balance'),
    );
  }
}
