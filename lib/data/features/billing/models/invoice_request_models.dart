/// Request + result models for `POST /api/v1/invoices`.

class CreateInvoiceItemRequestModel {
  const CreateInvoiceItemRequestModel({
    required this.itemType,
    required this.description,
    required this.amount,
    this.quantity = 1,
    this.sourceCode,
    this.valueType,
    this.valueInput,
  });

  final String itemType;
  final String description;
  final double amount;
  final int quantity;
  final String? sourceCode;
  final String? valueType;
  final double? valueInput;

  Map<String, dynamic> toJson() => {
        'itemType': itemType,
        'description': description,
        'quantity': quantity,
        'amount': amount,
        if (sourceCode != null && sourceCode!.isNotEmpty)
          'sourceCode': sourceCode,
        if (valueType != null && valueType!.isNotEmpty) 'valueType': valueType,
        if (valueInput != null) 'valueInput': valueInput,
      };
}

class CreateInvoiceRequestModel {
  const CreateInvoiceRequestModel({
    required this.organizationCode,
    required this.schoolCode,
    required this.studentCode,
    required this.issueDate,
    required this.dueDate,
    required this.items,
    this.periodStart,
    this.periodEnd,
    this.notes,
    this.currency,
  });

  final String organizationCode;
  final String schoolCode;
  final String studentCode;
  final DateTime issueDate;
  final DateTime dueDate;

  /// Optional service period (Date of Service range).
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final List<CreateInvoiceItemRequestModel> items;
  final String? notes;
  final String? currency;

  Map<String, dynamic> toJson() => {
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'studentCode': studentCode,
        'issueDate': issueDate.toUtc().toIso8601String(),
        'dueDate': dueDate.toUtc().toIso8601String(),
        if (periodStart != null)
          'periodStart': periodStart!.toUtc().toIso8601String(),
        if (periodEnd != null)
          'periodEnd': periodEnd!.toUtc().toIso8601String(),
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (currency != null && currency!.isNotEmpty) 'currency': currency,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

/// Body for `PATCH /api/v1/invoices/{invoiceCode}/draft` — same shape as create.
/// Items reuse [CreateInvoiceItemRequestModel] (each carries `itemType`/`amount`).
/// Only non-null fields are sent so callers can do partial updates; `schoolCode`
/// is required by the backend.
class UpdateInvoiceRequestModel {
  const UpdateInvoiceRequestModel({
    this.organizationCode,
    this.schoolCode,
    this.studentCode,
    this.ownerType,
    this.ownerCode,
    this.issueDate,
    this.dueDate,
    this.periodStart,
    this.periodEnd,
    this.currency,
    this.notes,
    this.items,
  });

  final String? organizationCode;
  final String? schoolCode;
  final String? studentCode;
  final String? ownerType;
  final String? ownerCode;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String? currency;
  final String? notes;
  final List<CreateInvoiceItemRequestModel>? items;

  Map<String, dynamic> toJson() => {
        if (organizationCode != null && organizationCode!.isNotEmpty)
          'organizationCode': organizationCode,
        if (schoolCode != null && schoolCode!.isNotEmpty)
          'schoolCode': schoolCode,
        if (studentCode != null && studentCode!.isNotEmpty)
          'studentCode': studentCode,
        if (ownerType != null && ownerType!.isNotEmpty) 'ownerType': ownerType,
        if (ownerCode != null && ownerCode!.isNotEmpty) 'ownerCode': ownerCode,
        if (issueDate != null) 'issueDate': issueDate!.toUtc().toIso8601String(),
        if (dueDate != null) 'dueDate': dueDate!.toUtc().toIso8601String(),
        if (periodStart != null)
          'periodStart': periodStart!.toUtc().toIso8601String(),
        if (periodEnd != null)
          'periodEnd': periodEnd!.toUtc().toIso8601String(),
        if (currency != null && currency!.isNotEmpty) 'currency': currency,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (items != null) 'items': items!.map((i) => i.toJson()).toList(),
      };
}

/// Body for `POST /api/v1/invoices/payments` and `/refunds` (same shape).
class InvoicePaymentRequestModel {
  const InvoicePaymentRequestModel({
    required this.schoolCode,
    required this.amount,
    required this.date,
    this.ownerType,
    this.ownerCode,
    this.studentCode,
    this.method,
    this.reference,
    this.narration,
  });

  final String schoolCode;
  final double amount;
  final DateTime date;
  final String? ownerType;
  final String? ownerCode;
  final String? studentCode;
  final String? method;
  final String? reference;
  final String? narration;

  Map<String, dynamic> toJson() => {
        if (ownerType != null && ownerType!.isNotEmpty) 'ownerType': ownerType,
        if (ownerCode != null && ownerCode!.isNotEmpty) 'ownerCode': ownerCode,
        if (studentCode != null && studentCode!.isNotEmpty)
          'studentCode': studentCode,
        'schoolCode': schoolCode,
        'amount': amount,
        'date': date.toUtc().toIso8601String(),
        if (method != null && method!.isNotEmpty) 'method': method,
        if (reference != null && reference!.isNotEmpty) 'reference': reference,
        if (narration != null && narration!.isNotEmpty) 'narration': narration,
      };
}

class CreateCreditRequestModel {
  const CreateCreditRequestModel({
    required this.schoolCode,
    required this.amount,
    this.ownerType,
    this.ownerCode,
    this.studentCode,
    this.reason,
    this.description,
  });

  final String schoolCode;
  final double amount;
  final String? ownerType;
  final String? ownerCode;
  final String? studentCode;
  final String? reason;
  final String? description;

  Map<String, dynamic> toJson() => {
        if (ownerType != null && ownerType!.isNotEmpty) 'ownerType': ownerType,
        if (ownerCode != null && ownerCode!.isNotEmpty) 'ownerCode': ownerCode,
        if (studentCode != null && studentCode!.isNotEmpty)
          'studentCode': studentCode,
        'schoolCode': schoolCode,
        'amount': amount,
        if (reason != null && reason!.isNotEmpty) 'reason': reason,
        if (description != null && description!.isNotEmpty)
          'description': description,
      };
}

class InvoicePaymentResultModel {
  const InvoicePaymentResultModel({
    this.ledgerCode,
    this.amount,
    this.amountApplied,
    this.creditBalance,
  });

  final String? ledgerCode;
  final double? amount;
  final double? amountApplied;
  final double? creditBalance;

  factory InvoicePaymentResultModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return InvoicePaymentResultModel(
      ledgerCode: data['ledgerCode'] as String?,
      amount: (data['amount'] as num?)?.toDouble(),
      amountApplied: (data['amountApplied'] as num?)?.toDouble(),
      creditBalance: (data['creditBalance'] as num?)?.toDouble(),
    );
  }
}

class InvoiceResultModel {
  const InvoiceResultModel({
    required this.code,
    this.status,
    this.invoiceStatus,
    this.total,
  });

  final String code;
  final String? status;
  final String? invoiceStatus;
  final double? total;

  factory InvoiceResultModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return InvoiceResultModel(
      code: (data['code'] as String?) ?? '',
      status: data['status'] as String?,
      invoiceStatus: data['invoiceStatus'] as String?,
      total: (data['total'] as num?)?.toDouble(),
    );
  }
}
