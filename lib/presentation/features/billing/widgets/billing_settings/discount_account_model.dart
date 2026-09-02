import 'package:wowcare/domain/features/billing/entities/discount_entity.dart';

class DiscountAccountModel {
  const DiscountAccountModel({
    required this.code,
    required this.name,
    this.description,
    this.percentage = 0,
    this.deductionAmount,
    this.maxInvoiceAmount,
    this.reference,
    this.discountType,
    this.price,
    this.status,
    this.school,
    this.totalAmountDiscounted = 0,
  });

  final String code;
  final String name;
  final String? description;
  final double percentage;
  final double? deductionAmount;
  final double? maxInvoiceAmount;
  final String? reference;
  final String? discountType;
  final double? price;
  final String? status;
  final String? school;

  /// Lifetime amount actually deducted across invoices by this discount —
  /// distinct from [deductionAmount], the fixed per-use deduction configured
  /// for a `FIXED`-type discount (null for `PERCENTAGE`-type ones).
  final double totalAmountDiscounted;

  bool get isActive => (status ?? 'ACTIVE') != 'INACTIVE';

  static DiscountAccountModel fromEntity(DiscountEntity e) =>
      DiscountAccountModel(
        code: e.code,
        name: e.name,
        description: e.description,
        percentage: e.percentage,
        deductionAmount: e.deductionAmount,
        maxInvoiceAmount: e.maxInvoiceAmount,
        reference: e.reference,
        discountType: e.discountType,
        price: e.price,
        status: e.status,
        school: e.school,
        totalAmountDiscounted: e.totalAmountDiscounted,
      );

  DiscountAccountModel copyWith({
    String? code,
    String? name,
    String? description,
    double? percentage,
    double? deductionAmount,
    double? maxInvoiceAmount,
    String? reference,
    String? discountType,
    double? price,
    String? status,
    String? school,
    double? totalAmountDiscounted,
  }) =>
      DiscountAccountModel(
        code: code ?? this.code,
        name: name ?? this.name,
        description: description ?? this.description,
        percentage: percentage ?? this.percentage,
        deductionAmount: deductionAmount ?? this.deductionAmount,
        maxInvoiceAmount: maxInvoiceAmount ?? this.maxInvoiceAmount,
        reference: reference ?? this.reference,
        discountType: discountType ?? this.discountType,
        price: price ?? this.price,
        status: status ?? this.status,
        school: school ?? this.school,
        totalAmountDiscounted:
            totalAmountDiscounted ?? this.totalAmountDiscounted,
      );
}
