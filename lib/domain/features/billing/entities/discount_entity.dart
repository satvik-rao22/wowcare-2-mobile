import 'package:equatable/equatable.dart';

class DiscountEntity extends Equatable {
  const DiscountEntity({
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

  bool get isActive => (status ?? 'ACTIVE') != 'INACTIVE';

  @override
  List<Object?> get props => [
        code, name, description, percentage, deductionAmount,
        maxInvoiceAmount, reference, discountType, price, status, school,
      ];
}

class DiscountPageEntity extends Equatable {
  const DiscountPageEntity({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.number,
    required this.last,
  });

  final List<DiscountEntity> content;
  final int totalPages;
  final int totalElements;
  final int number;
  final bool last;

  bool get hasMore => !last;

  @override
  List<Object?> get props =>
      [content, totalPages, totalElements, number, last];
}

class CreateDiscountParams extends Equatable {
  const CreateDiscountParams({
    required this.name,
    required this.school,
    this.percentage = 0,
    this.description,
    this.deductionAmount,
    this.maxInvoiceAmount,
    this.reference,
    this.discountType,
    this.price,
    this.status,
  });

  final String name;
  final String school;
  final double percentage;
  final String? description;
  final double? deductionAmount;
  final double? maxInvoiceAmount;
  final String? reference;
  final String? discountType;
  final double? price;
  final String? status;

  @override
  List<Object?> get props => [
        name, school, percentage, description, deductionAmount,
        maxInvoiceAmount, reference, discountType, price, status,
      ];
}
