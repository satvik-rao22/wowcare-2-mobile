import 'package:equatable/equatable.dart';

class DiscountModel extends Equatable {
  const DiscountModel({
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

  factory DiscountModel.fromJson(Map<String, dynamic> json) => DiscountModel(
        code: (json['code'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        description: json['description'] as String?,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
        deductionAmount: (json['deductionAmount'] as num?)?.toDouble(),
        maxInvoiceAmount: (json['maxInvoiceAmount'] as num?)?.toDouble(),
        reference: json['reference'] as String?,
        discountType: json['discountType'] as String?,
        price: (json['price'] as num?)?.toDouble(),
        status: json['status'] as String?,
        school: json['school'] as String?,
        totalAmountDiscounted:
            (json['totalAmountDiscounted'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [
        code, name, description, percentage, deductionAmount,
        maxInvoiceAmount, reference, discountType, price, status, school,
        totalAmountDiscounted,
      ];
}

class DiscountPageModel extends Equatable {
  const DiscountPageModel({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.number,
    required this.last,
  });

  final List<DiscountModel> content;
  final int totalPages;
  final int totalElements;
  final int number;
  final bool last;

  factory DiscountPageModel.fromJson(Map<String, dynamic> json) {
    final raw = json['data'] as Map<String, dynamic>? ?? json;
    final list = raw['content'] as List<dynamic>? ?? [];
    return DiscountPageModel(
      content: list
          .whereType<Map<String, dynamic>>()
          .map(DiscountModel.fromJson)
          .toList(),
      totalPages: (raw['totalPages'] as int?) ?? 0,
      totalElements: (raw['totalElements'] as int?) ?? 0,
      number: (raw['number'] as int?) ?? 0,
      last: (raw['last'] as bool?) ?? true,
    );
  }

  @override
  List<Object?> get props => [content, totalPages, totalElements, number, last];
}

class DiscountRequestModel {
  const DiscountRequestModel({
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

  Map<String, dynamic> toJson() => {
        'name': name,
        'school': school,
        'percentage': percentage,
        if (description != null && description!.isNotEmpty)
          'description': description,
        if (deductionAmount != null) 'deductionAmount': deductionAmount,
        if (maxInvoiceAmount != null) 'maxInvoiceAmount': maxInvoiceAmount,
        if (reference != null && reference!.isNotEmpty) 'reference': reference,
        if (discountType != null && discountType!.isNotEmpty)
          'discountType': discountType,
        if (price != null) 'price': price,
        if (status != null && status!.isNotEmpty) 'status': status,
      };
}
