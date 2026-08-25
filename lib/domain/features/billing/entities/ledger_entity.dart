import 'package:equatable/equatable.dart';

class LedgerEntity extends Equatable {
  const LedgerEntity({
    required this.code,
    required this.name,
    this.description,
    this.ledgerType,
    this.category,
    this.nature,
    this.currency,
    this.status,
    this.system = false,
    this.openingBalance = 0,
    this.openingBalanceType,
    this.currentBalance,
    this.balanceType,
  });

  final String code;
  final String name;
  final String? description;
  final String? ledgerType;
  final String? category;
  final String? nature;
  final String? currency;
  final String? status;
  final bool system;
  final double openingBalance;
  final String? openingBalanceType;
  final double? currentBalance;
  final String? balanceType;

  @override
  List<Object?> get props => [
    code,
    name,
    description,
    ledgerType,
    category,
    nature,
    currency,
    status,
    system,
    openingBalance,
    openingBalanceType,
    currentBalance,
    balanceType,
  ];
}

class LedgerPageEntity extends Equatable {
  const LedgerPageEntity({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.number,
    required this.last,
  });

  final List<LedgerEntity> content;
  final int totalPages;
  final int totalElements;
  final int number;
  final bool last;

  bool get hasMore => !last;

  @override
  List<Object?> get props => [content, totalPages, totalElements, number, last];
}

class CreateLedgerParams {
  const CreateLedgerParams({
    required this.name,
    required this.organization,
    required this.school,
    this.ledgerType,
    this.code,
    this.description,
    this.category,
    this.currency,
    this.openingBalanceType,
    this.openingBalance,
    this.allowManualBalance = true,
  });

  final String name;
  final String? code;
  final String organization;
  final String school;
  final String? ledgerType;
  final String? description;
  final String? category;
  final String? currency;
  final String? openingBalanceType;
  final String? openingBalance;
  final bool allowManualBalance;
}
