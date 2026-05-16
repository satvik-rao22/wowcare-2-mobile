import 'package:equatable/equatable.dart';

/// Lightweight UI model that mirrors the legacy ledger account payload.
class LedgerAccountModel extends Equatable {
  const LedgerAccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.openBalance,
    this.description,
    this.agencyId,
    this.schoolId,
    this.status,
    this.invoiced,
    this.received,
    this.isSubsidy = false,
  });

  final String id;
  final String name;
  final String type;
  final double openBalance;
  final double? invoiced;
  final double? received;
  final String? description;
  final String? agencyId;
  final String? schoolId;
  final String? status;
  final bool isSubsidy;

  double get availableBalance =>
      openBalance + (invoiced ?? 0) - (received ?? 0);

  LedgerAccountModel copyWith({
    String? name,
    String? type,
    double? openBalance,
    double? invoiced,
    double? received,
    String? description,
    String? agencyId,
    String? schoolId,
    String? status,
    bool? isSubsidy,
  }) {
    return LedgerAccountModel(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      openBalance: openBalance ?? this.openBalance,
      invoiced: invoiced ?? this.invoiced,
      received: received ?? this.received,
      description: description ?? this.description,
      agencyId: agencyId ?? this.agencyId,
      schoolId: schoolId ?? this.schoolId,
      status: status ?? this.status,
      isSubsidy: isSubsidy ?? this.isSubsidy,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    openBalance,
    invoiced,
    received,
    description,
    agencyId,
    schoolId,
    status,
    isSubsidy,
  ];
}
