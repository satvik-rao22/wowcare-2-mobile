import 'package:equatable/equatable.dart';

/// Domain entities for the Create Invoice catalog lookups (tuition fee
/// structures, other fees, subsidies). Discounts reuse [DiscountEntity].

class FeeDetailEntity extends Equatable {
  const FeeDetailEntity({
    required this.code,
    required this.billingCycle,
    required this.cost,
    this.status,
  });

  final String code;
  final String billingCycle;
  final double cost;
  final String? status;

  bool get isActive => (status ?? 'ACTIVE') != 'INACTIVE';

  @override
  List<Object?> get props => [code, billingCycle, cost, status];
}

class FeeStructureEntity extends Equatable {
  const FeeStructureEntity({
    required this.code,
    required this.ageGroupName,
    required this.daysPerWeek,
    required this.availabilityType,
    required this.feesDetails,
    this.status,
  });

  final String code;
  final String ageGroupName;
  final int daysPerWeek;
  final String? availabilityType;
  final List<FeeDetailEntity> feesDetails;
  final String? status;

  @override
  List<Object?> get props =>
      [code, ageGroupName, daysPerWeek, availabilityType, feesDetails, status];
}

class OtherFeeEntity extends Equatable {
  const OtherFeeEntity({
    required this.code,
    required this.description,
    required this.cost,
    this.status,
  });

  final String code;
  final String description;
  final double cost;
  final String? status;

  @override
  List<Object?> get props => [code, description, cost, status];
}

class SubsidyEntity extends Equatable {
  const SubsidyEntity({
    required this.code,
    required this.name,
    this.description,
    this.deductionAmount,
    this.price,
    this.discountType,
    this.status,
  });

  final String code;
  final String name;
  final String? description;
  final double? deductionAmount;
  final double? price;
  final String? discountType;
  final String? status;

  @override
  List<Object?> get props =>
      [code, name, description, deductionAmount, price, discountType, status];
}
