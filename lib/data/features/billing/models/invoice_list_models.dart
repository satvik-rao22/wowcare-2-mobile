import 'package:wowcare/domain/features/billing/entities/invoice_list_entity.dart';

/// One `items[]` line inside an invoice row.
class InvoiceListLineItemModel {
  const InvoiceListLineItemModel({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.itemType,
    this.sourceCode,
    this.valueType,
    this.valueInput,
  });

  final String description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? itemType;
  final String? sourceCode;
  final String? valueType;
  final double? valueInput;

  factory InvoiceListLineItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceListLineItemModel(
      description: (json['description'] as String?) ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      itemType: json['itemType'] as String?,
      sourceCode: json['sourceCode'] as String?,
      valueType: json['valueType'] as String?,
      valueInput: (json['valueInput'] as num?)?.toDouble(),
    );
  }

  InvoiceListLineItemEntity toEntity() => InvoiceListLineItemEntity(
        description: description,
        quantity: quantity,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
        itemType: itemType,
        sourceCode: sourceCode,
        valueType: valueType,
        valueInput: valueInput,
      );
}

/// One invoice row from `data.content[]`.
class InvoiceListItemModel {
  const InvoiceListItemModel({
    required this.code,
    required this.organization,
    required this.school,
    required this.studentCode,
    required this.subjectOwnerType,
    required this.subjectOwnerCode,
    required this.amount,
    required this.total,
    required this.paidAmount,
    required this.status,
    required this.invoiceStatus,
    required this.items,
    this.issueDate,
    this.dueDate,
    this.periodStart,
    this.periodEnd,
    this.createdDate,
    this.createdBy,
    this.subscriptionCode,
  });

  final String code;
  final String organization;
  final String school;
  final String studentCode;
  final String subjectOwnerType;
  final String subjectOwnerCode;
  final double amount;
  final double total;
  final double paidAmount;
  final String status;
  final String invoiceStatus;
  final List<InvoiceListLineItemModel> items;
  final DateTime? issueDate;
  final DateTime? dueDate;

  /// Optional service period (Date of Service from/to) — used to repopulate the
  /// edit form's Date-of-Service fields.
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? createdDate;
  final String? createdBy;
  final String? subscriptionCode;

  factory InvoiceListItemModel.fromJson(Map<String, dynamic> json) {
    double d(String key) => (json[key] as num?)?.toDouble() ?? 0;
    String s(String key) => (json[key] as String?) ?? '';
    DateTime? dt(String key) {
      final raw = json[key];
      return raw is String ? DateTime.tryParse(raw) : null;
    }

    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(InvoiceListLineItemModel.fromJson)
        .toList(growable: false);

    return InvoiceListItemModel(
      code: s('code'),
      organization: s('organization'),
      school: s('school'),
      studentCode: s('studentCode'),
      subjectOwnerType: s('subjectOwnerType'),
      subjectOwnerCode: s('subjectOwnerCode'),
      amount: d('amount'),
      total: d('total'),
      paidAmount: d('paidAmount'),
      status: s('status'),
      invoiceStatus: s('invoiceStatus'),
      items: items,
      issueDate: dt('issueDate'),
      dueDate: dt('dueDate'),
      periodStart: dt('periodStart'),
      periodEnd: dt('periodEnd'),
      createdDate: dt('createdDate'),
      createdBy: json['createdBy'] as String?,
      subscriptionCode: json['subscriptionCode'] as String?,
    );
  }

  InvoiceListItemEntity toEntity() => InvoiceListItemEntity(
        code: code,
        organization: organization,
        school: school,
        studentCode: studentCode,
        subjectOwnerType: subjectOwnerType,
        subjectOwnerCode: subjectOwnerCode,
        amount: amount,
        total: total,
        paidAmount: paidAmount,
        status: status,
        invoiceStatus: invoiceStatus,
        items: items.map((e) => e.toEntity()).toList(growable: false),
        issueDate: issueDate,
        dueDate: dueDate,
        periodStart: periodStart,
        periodEnd: periodEnd,
        createdDate: createdDate,
        createdBy: createdBy,
        subscriptionCode: subscriptionCode,
      );
}

/// The Spring `Page` envelope under the standard `{ data: {...} }` wrapper.
class PaginatedInvoicesModel {
  const PaginatedInvoicesModel({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<InvoiceListItemModel> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  factory PaginatedInvoicesModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    final content = data['content'] as List<dynamic>? ?? const [];
    final pageNumber = (data['number'] as num?)?.toInt() ?? 0;
    final pageSize = (data['size'] as num?)?.toInt() ?? content.length;
    final totalPages = (data['totalPages'] as num?)?.toInt() ?? 0;
    final totalElements =
        (data['totalElements'] as num?)?.toInt() ?? content.length;

    final items = content
        .whereType<Map<String, dynamic>>()
        .map(InvoiceListItemModel.fromJson)
        .toList(growable: false);

    // Prefer the explicit `last` flag when present; fall back to page math.
    final last = data['last'];
    final hasMore =
        last is bool ? !last : (pageNumber + 1 < totalPages);

    return PaginatedInvoicesModel(
      items: items,
      page: pageNumber,
      size: pageSize,
      totalPages: totalPages,
      totalElements: totalElements,
      hasMore: hasMore,
    );
  }

  PaginatedInvoicesEntity toEntity() => PaginatedInvoicesEntity(
        items: items.map((e) => e.toEntity()).toList(growable: false),
        page: page,
        size: size,
        totalPages: totalPages,
        totalElements: totalElements,
        hasMore: hasMore,
      );
}
