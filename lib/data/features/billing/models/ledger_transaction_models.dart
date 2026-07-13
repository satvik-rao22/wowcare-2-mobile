import 'package:equatable/equatable.dart';

class LedgerTransactionModel extends Equatable {
  const LedgerTransactionModel({
    this.code,
    this.ledgerCode,
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
  final String? ledgerCode;
  final String? type;
  final String? description;
  final String? contraAccount;
  final double? debit;
  final double? credit;
  final double balance;
  final String? balanceType;
  final String? date;

  factory LedgerTransactionModel.fromJson(Map<String, dynamic> json) {
    return LedgerTransactionModel(
      code: (json['id'] as int?)?.toString() ?? json['code'] as String?,
      ledgerCode: json['ledgerCode'] as String?,
      type: json['voucherType'] as String? ??
          json['type'] as String? ??
          json['transactionType'] as String?,
      description: json['narration'] as String? ??
          json['description'] as String?,
      contraAccount: json['contraLedger'] as String? ??
          json['contraAccount'] as String? ??
          json['contra'] as String? ??
          json['contraAccountName'] as String?,
      debit: (json['debit'] as num?)?.toDouble(),
      credit: (json['credit'] as num?)?.toDouble(),
      balance: (json['runningBalance'] as num?)?.toDouble() ??
          (json['balance'] as num?)?.toDouble() ??
          0,
      balanceType: json['balanceType'] as String?,
      date: json['date'] as String? ?? json['transactionDate'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [code, ledgerCode, type, description, contraAccount, debit, credit, balance, balanceType, date];
}

class LedgerTransactionPageModel extends Equatable {
  const LedgerTransactionPageModel({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.size,
    required this.number,
    required this.numberOfElements,
    required this.last,
    required this.first,
  });

  final List<LedgerTransactionModel> content;
  final int totalPages;
  final int totalElements;
  final int size;
  final int number;
  final int numberOfElements;
  final bool last;
  final bool first;

  factory LedgerTransactionPageModel.fromJson(Map<String, dynamic> json) {
    final dataRaw = json['data'];
    if (dataRaw is List) {
      final items = dataRaw
          .map((e) => LedgerTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return LedgerTransactionPageModel(
        content: items,
        totalPages: 1,
        totalElements: items.length,
        size: items.length,
        number: 0,
        numberOfElements: items.length,
        last: true,
        first: true,
      );
    }
    final raw = dataRaw as Map<String, dynamic>? ?? json;
    final contentList = raw['content'] as List<dynamic>? ?? [];
    return LedgerTransactionPageModel(
      content: contentList
          .map((e) => LedgerTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPages: raw['totalPages'] as int? ?? 0,
      totalElements: raw['totalElements'] as int? ?? 0,
      size: raw['size'] as int? ?? 10,
      number: raw['number'] as int? ?? 0,
      numberOfElements: raw['numberOfElements'] as int? ?? contentList.length,
      last: raw['last'] as bool? ?? true,
      first: raw['first'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props =>
      [content, totalPages, totalElements, size, number, numberOfElements, last, first];
}

class AddTransactionRequestModel {
  const AddTransactionRequestModel({
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

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'date': date,
        if (narration != null && narration!.isNotEmpty) 'narration': narration,
        if (direction != null && direction!.isNotEmpty) 'direction': direction,
      };
}
