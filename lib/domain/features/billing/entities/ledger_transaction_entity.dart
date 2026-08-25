import 'package:equatable/equatable.dart';

class LedgerTransactionEntity extends Equatable {
  const LedgerTransactionEntity({
    this.code,
    this.type,
    this.description,
    this.contraAccount,
    this.debit,
    this.credit,
    this.balance = 0,
    this.balanceType,
    this.date,
  });

  final String? code;
  final String? type;
  final String? description;
  final String? contraAccount;
  final double? debit;
  final double? credit;
  final double balance;
  final String? balanceType;
  final String? date;

  @override
  List<Object?> get props => [
    code,
    type,
    description,
    contraAccount,
    debit,
    credit,
    balance,
    balanceType,
    date,
  ];
}

class LedgerTransactionPageEntity extends Equatable {
  const LedgerTransactionPageEntity({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.size,
    required this.number,
    required this.numberOfElements,
    required this.last,
  });

  final List<LedgerTransactionEntity> content;
  final int totalPages;
  final int totalElements;
  final int size;
  final int number;
  final int numberOfElements;
  final bool last;

  bool get hasMore => !last;

  int get fromEntry => totalElements == 0 ? 0 : number * size + 1;
  int get toEntry => number * size + numberOfElements;

  @override
  List<Object?> get props => [
    content,
    totalPages,
    totalElements,
    size,
    number,
    numberOfElements,
    last,
  ];
}

class AddTransactionParams {
  const AddTransactionParams({
    required this.ledgerCode,
    required this.amount,
    required this.date,
    this.narration,
    this.direction,
  });

  final String ledgerCode;
  final double amount;
  final String date;
  final String? narration;
  final String? direction;
}
