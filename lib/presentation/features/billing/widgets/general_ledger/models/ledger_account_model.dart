import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/billing/entities/ledger_entity.dart';

/// UI model for a ledger account. The [id] field carries the API [code]
/// so all existing widget references continue to work unchanged.
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
    // Fields from the real API response
    this.nature,
    this.currency,
    this.category,
    this.openingBalanceType,
    this.currentBalance,
    this.balanceType,
    this.system = false,
  });

  /// Maps a [LedgerEntity] from the domain layer to this UI model.
  factory LedgerAccountModel.fromEntity(LedgerEntity entity) {
    return LedgerAccountModel(
      id: entity.code,
      name: entity.name,
      type: entity.ledgerType ?? '',
      openBalance: entity.openingBalance,
      description: entity.description,
      status: entity.status,
      nature: entity.nature,
      currency: entity.currency,
      category: entity.category,
      openingBalanceType: entity.openingBalanceType,
      currentBalance: entity.currentBalance,
      balanceType: entity.balanceType,
      system: entity.system,
    );
  }

  // ─── Existing fields (kept as-is for UI compatibility) ────────────────────
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

  // ─── API fields ───────────────────────────────────────────────────────────
  final String? nature;
  final String? currency;
  final String? category;
  final String? openingBalanceType;
  final double? currentBalance;
  final String? balanceType;
  final bool system;

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
    String? nature,
    String? currency,
    String? category,
    String? openingBalanceType,
    double? currentBalance,
    String? balanceType,
    bool? system,
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
      nature: nature ?? this.nature,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      openingBalanceType: openingBalanceType ?? this.openingBalanceType,
      currentBalance: currentBalance ?? this.currentBalance,
      balanceType: balanceType ?? this.balanceType,
      system: system ?? this.system,
    );
  }

  @override
  List<Object?> get props => [
        id, name, type, openBalance, invoiced, received, description,
        agencyId, schoolId, status, isSubsidy, nature, currency, category,
        openingBalanceType, currentBalance, balanceType, system,
      ];
}
