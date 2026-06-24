import 'package:wowcare/domain/features/billing/entities/family_ledger_entity.dart';

class FamilyLedgerPersonModel {
  const FamilyLedgerPersonModel({
    required this.code,
    required this.fullName,
    required this.role,
    required this.outstanding,
  });

  final String code;
  final String fullName;
  final String role;
  final double outstanding;

  factory FamilyLedgerPersonModel.fromJson(Map<String, dynamic> json) {
    return FamilyLedgerPersonModel(
      code: (json['code'] as String?) ?? '',
      fullName: (json['fullName'] as String?) ?? '',
      role: (json['role'] as String?) ?? '',
      outstanding: (json['outstanding'] as num?)?.toDouble() ?? 0,
    );
  }

  FamilyLedgerPersonEntity toEntity() => FamilyLedgerPersonEntity(
        code: code,
        fullName: fullName,
        role: role,
        outstanding: outstanding,
      );
}

class FamilyLedgerTransactionModel {
  const FamilyLedgerTransactionModel({
    required this.id,
    required this.invoiceCode,
    required this.recurring,
    required this.subscriptionCode,
    required this.studentCode,
    required this.studentName,
    required this.transactionType,
    required this.status,
    required this.method,
    required this.description,
    required this.items,
    required this.amount,
    required this.balance,
    required this.paidAmount,
    required this.ledgerDelta,
    this.date,
  });

  final String id;
  final String invoiceCode;
  final bool recurring;
  final String subscriptionCode;
  final String studentCode;
  final String studentName;
  final String transactionType;
  final String status;
  final String method;
  final String description;
  final List<String> items;
  final double amount;
  final double balance;
  final double paidAmount;
  final double ledgerDelta;
  final DateTime? date;

  factory FamilyLedgerTransactionModel.fromJson(Map<String, dynamic> json) {
    String s(String key) => (json[key] as String?) ?? '';
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final rawDate = json['date'];
    return FamilyLedgerTransactionModel(
      id: json['id']?.toString() ?? '',
      invoiceCode: s('invoiceCode'),
      recurring: json['recurring'] == true,
      subscriptionCode: s('subscriptionCode'),
      studentCode: s('studentCode'),
      studentName: s('studentName'),
      transactionType: s('transactionType'),
      status: s('status'),
      method: s('method'),
      description: s('description'),
      items: rawItems.map((e) => e.toString()).toList(growable: false),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      ledgerDelta: (json['ledgerDelta'] as num?)?.toDouble() ?? 0,
      date: rawDate is String ? DateTime.tryParse(rawDate) : null,
    );
  }

  FamilyLedgerTransactionEntity toEntity() => FamilyLedgerTransactionEntity(
        id: id,
        invoiceCode: invoiceCode,
        recurring: recurring,
        subscriptionCode: subscriptionCode,
        studentCode: studentCode,
        studentName: studentName,
        transactionType: transactionType,
        status: status,
        method: method,
        description: description,
        items: items,
        amount: amount,
        balance: balance,
        paidAmount: paidAmount,
        ledgerDelta: ledgerDelta,
        date: date,
      );
}

class FamilyLedgerModel {
  const FamilyLedgerModel({
    required this.ownerType,
    required this.ownerCode,
    required this.familyName,
    required this.openBalance,
    required this.paid,
    required this.refunded,
    required this.netPaid,
    required this.inProcess,
    required this.unpaid,
    required this.students,
    required this.guardians,
    required this.transactions,
  });

  final String ownerType;
  final String ownerCode;
  final String familyName;
  final double openBalance;
  final double paid;
  final double refunded;
  final double netPaid;
  final double inProcess;
  final double unpaid;
  final List<FamilyLedgerPersonModel> students;
  final List<FamilyLedgerPersonModel> guardians;
  final List<FamilyLedgerTransactionModel> transactions;

  factory FamilyLedgerModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    double d(String key) => (data[key] as num?)?.toDouble() ?? 0;
    String s(String key) => (data[key] as String?) ?? '';

    List<FamilyLedgerPersonModel> people(String key) =>
        (data[key] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(FamilyLedgerPersonModel.fromJson)
            .toList(growable: false);

    final transactions = (data['transactions'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(FamilyLedgerTransactionModel.fromJson)
        .toList(growable: false);

    return FamilyLedgerModel(
      ownerType: s('ownerType'),
      ownerCode: s('ownerCode'),
      familyName: s('familyName'),
      openBalance: d('openBalance'),
      paid: d('paid'),
      refunded: d('refunded'),
      netPaid: d('netPaid'),
      inProcess: d('inProcess'),
      unpaid: d('unpaid'),
      students: people('students'),
      guardians: people('guardians'),
      transactions: transactions,
    );
  }

  FamilyLedgerEntity toEntity() => FamilyLedgerEntity(
        ownerType: ownerType,
        ownerCode: ownerCode,
        familyName: familyName,
        openBalance: openBalance,
        paid: paid,
        refunded: refunded,
        netPaid: netPaid,
        inProcess: inProcess,
        unpaid: unpaid,
        students: students.map((e) => e.toEntity()).toList(growable: false),
        guardians: guardians.map((e) => e.toEntity()).toList(growable: false),
        transactions:
            transactions.map((e) => e.toEntity()).toList(growable: false),
      );
}
