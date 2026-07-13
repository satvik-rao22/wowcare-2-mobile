import 'package:equatable/equatable.dart';

/// Data models for the invoice "catalog" lookups consumed by the Create Invoice
/// screen: fee structures (tuition), other fees, and subsidies. Discounts reuse
/// the existing discount models. All three share the same paginated envelope
/// (`data.content`), mirrored from [DiscountPageModel].

// ─── Fee structures (tuition) ────────────────────────────────────────────────

class FeeDetailModel extends Equatable {
  const FeeDetailModel({
    required this.code,
    required this.billingCycle,
    required this.cost,
    this.status,
  });

  final String code;
  final String billingCycle;
  final double cost;
  final String? status;

  factory FeeDetailModel.fromJson(Map<String, dynamic> json) => FeeDetailModel(
        code: (json['code'] as String?) ?? '',
        billingCycle: (json['billingCycle'] as String?) ?? '',
        cost: (json['cost'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String?,
      );

  @override
  List<Object?> get props => [code, billingCycle, cost, status];
}

class FeeStructureModel extends Equatable {
  const FeeStructureModel({
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
  final List<FeeDetailModel> feesDetails;
  final String? status;

  factory FeeStructureModel.fromJson(Map<String, dynamic> json) {
    final details = (json['feesDetails'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(FeeDetailModel.fromJson)
        .toList();
    return FeeStructureModel(
      code: (json['code'] as String?) ?? '',
      ageGroupName: (json['ageGroupName'] as String?) ?? '',
      daysPerWeek: (json['daysPerWeek'] as num?)?.toInt() ?? 0,
      availabilityType: json['availabilityType'] as String?,
      feesDetails: details,
      status: json['status'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [code, ageGroupName, daysPerWeek, availabilityType, feesDetails, status];
}

// ─── Other fees ──────────────────────────────────────────────────────────────

class OtherFeeModel extends Equatable {
  const OtherFeeModel({
    required this.code,
    required this.description,
    required this.cost,
    this.status,
  });

  final String code;
  final String description;
  final double cost;
  final String? status;

  factory OtherFeeModel.fromJson(Map<String, dynamic> json) => OtherFeeModel(
        code: (json['code'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        cost: (json['cost'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String?,
      );

  @override
  List<Object?> get props => [code, description, cost, status];
}

// ─── Subsidies ───────────────────────────────────────────────────────────────

class SubsidyModel extends Equatable {
  const SubsidyModel({
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

  factory SubsidyModel.fromJson(Map<String, dynamic> json) => SubsidyModel(
        code: (json['code'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        description: json['description'] as String?,
        deductionAmount: (json['deductionAmount'] as num?)?.toDouble(),
        price: (json['price'] as num?)?.toDouble(),
        discountType: json['discountType'] as String?,
        status: json['status'] as String?,
      );

  @override
  List<Object?> get props =>
      [code, name, description, deductionAmount, price, discountType, status];
}

// ─── Generic paged envelope parser ───────────────────────────────────────────

/// Extracts the `data.content` list (falling back to a top-level `content`)
/// from the standard API envelope and maps each entry with [fromJson].
List<T> parseCatalogContent<T>(
  Map<String, dynamic> json,
  T Function(Map<String, dynamic>) fromJson,
) {
  final raw = json['data'] as Map<String, dynamic>? ?? json;
  final list = raw['content'] as List<dynamic>? ?? const [];
  return list.whereType<Map<String, dynamic>>().map(fromJson).toList();
}
