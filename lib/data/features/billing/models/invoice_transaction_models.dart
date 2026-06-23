import '../../../../domain/features/billing/entities/invoice_entity.dart';

/// One row from `GET /api/v1/invoices/transactions` (UAT: `accounts/invoices/...`).
class InvoiceTransactionModel {
  const InvoiceTransactionModel({
    required this.id,
    required this.type,
    required this.date,
    required this.familyCode,
    required this.familyName,
    required this.studentCode,
    required this.studentName,
    required this.description,
    required this.status,
    required this.method,
    required this.amount,
    required this.paidAmount,
    required this.refundedAmount,
    required this.invoiceCode,
  });

  final String id;
  final String type;
  final DateTime? date;
  final String familyCode;
  final String familyName;
  final String studentCode;
  final String studentName;
  final String description;
  final String status;
  final String? method;
  final double amount;

  /// Amount already paid against this invoice. Drives whether a Cancel action is
  /// offered — a partially/fully paid invoice can no longer be cancelled.
  final double paidAmount;

  /// Amount already refunded against this invoice (max refundable = amount −
  /// refundedAmount).
  final double refundedAmount;
  final String invoiceCode;

  factory InvoiceTransactionModel.fromJson(Map<String, dynamic> json) {
    return InvoiceTransactionModel(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      date: DateTime.tryParse((json['date'] ?? '').toString()),
      familyCode: (json['familyCode'] ?? '').toString(),
      familyName: (json['familyName'] ?? '').toString(),
      studentCode: (json['studentCode'] ?? '').toString(),
      studentName: (json['studentName'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      method: (json['method'])?.toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      refundedAmount: (json['refundedAmount'] as num?)?.toDouble() ?? 0.0,
      invoiceCode: (json['invoiceCode'] ?? json['id'] ?? '').toString(),
    );
  }

  InvoiceTransactionEntity toEntity() => InvoiceTransactionEntity(
        id: id,
        type: type,
        date: date,
        familyCode: familyCode,
        familyName: familyName,
        studentCode: studentCode,
        studentName: studentName,
        description: description,
        status: status,
        method: method,
        amount: amount,
        paidAmount: paidAmount,
        refundedAmount: refundedAmount,
        invoiceCode: invoiceCode,
      );
}

/// One page of invoice transactions plus whether more pages exist.
class InvoiceTransactionsPageModel {
  const InvoiceTransactionsPageModel({
    required this.items,
    required this.hasMore,
    required this.totalElements,
  });

  final List<InvoiceTransactionModel> items;
  final bool hasMore;
  final int totalElements;

  factory InvoiceTransactionsPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final content = map['content'];
    final items = content is List
        ? content
            .whereType<Map>()
            .map((e) =>
                InvoiceTransactionModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <InvoiceTransactionModel>[];
    // Prefer the Spring `last` flag; fall back to a full page meaning more.
    final last = map['last'];
    final size = (map['size'] as num?)?.toInt() ?? items.length;
    final hasMore = last is bool ? !last : items.length >= size && size > 0;
    return InvoiceTransactionsPageModel(
      items: items,
      hasMore: hasMore,
      totalElements: (map['totalElements'] as num?)?.toInt() ?? items.length,
    );
  }

  ({List<InvoiceTransactionEntity> items, bool hasMore, int totalElements})
      toEntity() => (
            items: items.map((e) => e.toEntity()).toList(),
            hasMore: hasMore,
            totalElements: totalElements,
          );
}
