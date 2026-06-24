import 'package:equatable/equatable.dart';

/// A single line item inside an invoice (`data.content[].items[]`).
class InvoiceListLineItemEntity extends Equatable {
  const InvoiceListLineItemEntity({
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

  /// Detail-only fields (present on `GET /invoices/by-code/{code}`, used to
  /// rebuild the edit form): NEW_ITEM / TUITION_FEE / DISCOUNT / …
  final String? itemType;
  final String? sourceCode;
  final String? valueType;
  final double? valueInput;

  @override
  List<Object?> get props => [
        description,
        quantity,
        unitPrice,
        totalPrice,
        itemType,
        sourceCode,
        valueType,
        valueInput,
      ];
}

/// One invoice row from `GET /api/v1/invoices/{organizationCode}`
/// (`data.content[]`).
class InvoiceListItemEntity extends Equatable {
  const InvoiceListItemEntity({
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
  final List<InvoiceListLineItemEntity> items;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final DateTime? createdDate;
  final String? createdBy;
  final String? subscriptionCode;

  /// Outstanding balance for this invoice.
  double get balance => (total - paidAmount).clamp(0, double.infinity).toDouble();

  @override
  List<Object?> get props => [
        code,
        organization,
        school,
        studentCode,
        subjectOwnerType,
        subjectOwnerCode,
        amount,
        total,
        paidAmount,
        status,
        invoiceStatus,
        items,
        issueDate,
        dueDate,
        createdDate,
        createdBy,
        subscriptionCode,
      ];
}

/// A page of invoices plus the Spring pageable metadata needed to drive
/// infinite scroll / "load more".
class PaginatedInvoicesEntity extends Equatable {
  const PaginatedInvoicesEntity({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<InvoiceListItemEntity> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  @override
  List<Object?> get props =>
      [items, page, size, totalPages, totalElements, hasMore];
}
