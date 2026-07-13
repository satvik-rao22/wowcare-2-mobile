/// Response model for `GET /api/v1/invoices/family-summary` (data is a list).
class FamilySummaryModel {
  const FamilySummaryModel({
    required this.ownerType,
    required this.ownerCode,
    required this.studentCodes,
    required this.familyName,
    required this.guardianName,
    required this.lastInvoiceAmount,
    required this.lastInvoiceDate,
    required this.lastInvoiceDueDate,
    required this.lastInvoiceStatus,
    required this.lastPaymentAmount,
    required this.lastPaymentDate,
    required this.lastPaymentMethod,
    required this.openBalance,
  });

  final String ownerType;
  final String ownerCode;
  final List<String> studentCodes;
  final String familyName;
  final String guardianName;
  final double lastInvoiceAmount;
  final DateTime? lastInvoiceDate;
  final DateTime? lastInvoiceDueDate;
  final String lastInvoiceStatus;
  final double lastPaymentAmount;
  final DateTime? lastPaymentDate;
  final String lastPaymentMethod;
  final double openBalance;

  factory FamilySummaryModel.fromJson(Map<String, dynamic> json) {
    double d(String key) => (json[key] as num?)?.toDouble() ?? 0;
    DateTime? dt(String key) {
      final raw = json[key];
      return raw is String ? DateTime.tryParse(raw) : null;
    }

    return FamilySummaryModel(
      ownerType: (json['ownerType'] as String?) ?? '',
      ownerCode: (json['ownerCode'] as String?) ?? '',
      studentCodes: (json['studentCodes'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const <String>[],
      familyName: (json['familyName'] as String?) ?? '',
      guardianName: (json['guardianName'] as String?) ?? '',
      lastInvoiceAmount: d('lastInvoiceAmount'),
      lastInvoiceDate: dt('lastInvoiceDate'),
      lastInvoiceDueDate: dt('lastInvoiceDueDate'),
      lastInvoiceStatus: (json['lastInvoiceStatus'] as String?) ?? '',
      lastPaymentAmount: d('lastPaymentAmount'),
      lastPaymentDate: dt('lastPaymentDate'),
      lastPaymentMethod: (json['lastPaymentMethod'] as String?) ?? '',
      openBalance: d('openBalance'),
    );
  }

  /// Extracts and maps the `data` list from the standard API envelope.
  static List<FamilySummaryModel> listFromJson(Map<String, dynamic> json) {
    final list = json['data'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(FamilySummaryModel.fromJson)
        .toList();
  }
}
