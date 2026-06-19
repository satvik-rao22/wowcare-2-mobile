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
    this.notes,
    this.currency,
  });

  final String organizationCode;
  final String schoolCode;
  final String studentCode;
  final DateTime issueDate;
  final DateTime dueDate;
  final List<CreateInvoiceItemRequestModel> items;
  final String? notes;
  final String? currency;

  Map<String, dynamic> toJson() => {
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'studentCode': studentCode,
        'issueDate': issueDate.toUtc().toIso8601String(),
        'dueDate': dueDate.toUtc().toIso8601String(),
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (currency != null && currency!.isNotEmpty) 'currency': currency,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

class UpdateInvoiceItemRequestModel {
  const UpdateInvoiceItemRequestModel({
    required this.description,
    this.quantity,
    this.unitPrice,
    this.totalPrice,
  });

  final String description;
  final int? quantity;
  final double? unitPrice;
  final double? totalPrice;

  Map<String, dynamic> toJson() => {
        'description': description,
        if (quantity != null) 'quantity': quantity,
        if (unitPrice != null) 'unitPrice': unitPrice,
        if (totalPrice != null) 'totalPrice': totalPrice,
      };
}

/// Body for `PATCH /api/v1/invoices/{invoiceCode}` — only non-null fields are
/// sent so callers can do partial updates.
class UpdateInvoiceRequestModel {
  const UpdateInvoiceRequestModel({
    this.code,
    this.studentCode,
    this.issueDate,
    this.dueDate,
    this.status,
    this.invoiceStatus,
    this.amount,
    this.total,
    this.paidAmount,
    this.subjectOwnerType,
    this.subjectOwnerCode,
    this.subscriptionCode,
    this.items,
  });

  final String? code;
  final String? studentCode;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final String? status;
  final String? invoiceStatus;
  final double? amount;
  final double? total;
  final double? paidAmount;
  final String? subjectOwnerType;
  final String? subjectOwnerCode;
  final String? subscriptionCode;
  final List<UpdateInvoiceItemRequestModel>? items;

  Map<String, dynamic> toJson() => {
        if (code != null && code!.isNotEmpty) 'code': code,
        if (studentCode != null && studentCode!.isNotEmpty)
          'studentCode': studentCode,
        if (issueDate != null) 'issueDate': issueDate!.toUtc().toIso8601String(),
        if (dueDate != null) 'dueDate': dueDate!.toUtc().toIso8601String(),
        if (status != null && status!.isNotEmpty) 'status': status,
        if (invoiceStatus != null && invoiceStatus!.isNotEmpty)
          'invoiceStatus': invoiceStatus,
        if (amount != null) 'amount': amount,
        if (total != null) 'total': total,
        if (paidAmount != null) 'paidAmount': paidAmount,
        if (subjectOwnerType != null && subjectOwnerType!.isNotEmpty)
          'subjectOwnerType': subjectOwnerType,
        if (subjectOwnerCode != null && subjectOwnerCode!.isNotEmpty)
          'subjectOwnerCode': subjectOwnerCode,
        if (subscriptionCode != null && subscriptionCode!.isNotEmpty)
          'subscriptionCode': subscriptionCode,
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
