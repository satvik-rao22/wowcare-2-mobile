import 'package:equatable/equatable.dart';

class LedgerModel extends Equatable {
  const LedgerModel({
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

  factory LedgerModel.fromJson(Map<String, dynamic> json) {
    return LedgerModel(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      ledgerType: json['ledgerType'] as String?,
      category: json['category'] as String?,
      nature: json['nature'] as String?,
      currency: json['currency'] as String?,
      status: json['status'] as String?,
      system: json['system'] as bool? ?? false,
      openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0,
      openingBalanceType: json['openingBalanceType'] as String?,
      currentBalance: (json['currentBalance'] as num?)?.toDouble(),
      balanceType: json['balanceType'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        if (description != null) 'description': description,
        if (ledgerType != null) 'ledgerType': ledgerType,
        if (category != null) 'category': category,
        if (nature != null) 'nature': nature,
        if (currency != null) 'currency': currency,
        if (status != null) 'status': status,
        'system': system,
        'openingBalance': openingBalance,
        if (openingBalanceType != null) 'openingBalanceType': openingBalanceType,
        if (currentBalance != null) 'currentBalance': currentBalance,
        if (balanceType != null) 'balanceType': balanceType,
      };

  @override
  List<Object?> get props => [
        code, name, description, ledgerType, category, nature,
        currency, status, system, openingBalance, openingBalanceType,
        currentBalance, balanceType,
      ];
}

class LedgerPageModel extends Equatable {
  const LedgerPageModel({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.size,
    required this.number,
    required this.first,
    required this.last,
    required this.empty,
  });

  final List<LedgerModel> content;
  final int totalPages;
  final int totalElements;
  final int size;
  final int number;
  final bool first;
  final bool last;
  final bool empty;

  factory LedgerPageModel.fromJson(Map<String, dynamic> json) {
    final raw = json['data'] as Map<String, dynamic>? ?? json;
    final contentList = raw['content'] as List<dynamic>? ?? [];
    return LedgerPageModel(
      content: contentList
          .map((e) => LedgerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPages: raw['totalPages'] as int? ?? 0,
      totalElements: raw['totalElements'] as int? ?? 0,
      size: raw['size'] as int? ?? 0,
      number: raw['number'] as int? ?? 0,
      first: raw['first'] as bool? ?? true,
      last: raw['last'] as bool? ?? true,
      empty: raw['empty'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props =>
      [content, totalPages, totalElements, size, number, first, last, empty];
}

class LedgerRequestModel {
  const LedgerRequestModel({
    required this.name,
    required this.organization,
    required this.school,
    this.ledgerType,
    this.code,
    this.currency,
    this.openingBalanceType,
    this.allowManualBalance = true,
    this.openingBalance,
    this.description,
    this.category,
  });

  final String name;
  final String? code;
  final String organization;
  final String school;
  final String? ledgerType;
  final String? currency;
  final String? openingBalanceType;
  final bool allowManualBalance;
  final String? openingBalance;
  final String? description;
  final String? category;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (code != null) 'code': code,
        'organization': organization,
        'school': school,
        if (ledgerType != null && ledgerType!.isNotEmpty) 'ledgerType': ledgerType,
        if (currency != null) 'currency': currency,
        if (openingBalanceType != null) 'openingBalanceType': openingBalanceType,
        'allowManualBalance': allowManualBalance,
        if (openingBalance != null) 'openingBalance': openingBalance,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
      };
}
