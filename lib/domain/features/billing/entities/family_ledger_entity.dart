import 'package:equatable/equatable.dart';

/// A student or guardian row inside a family ledger.
class FamilyLedgerPersonEntity extends Equatable {
  const FamilyLedgerPersonEntity({
    required this.code,
    required this.fullName,
    required this.role,
    required this.outstanding,
  });

  final String code;
  final String fullName;
  final String role;
  final double outstanding;

  @override
  List<Object?> get props => [code, fullName, role, outstanding];
}

/// One transaction row inside a family ledger.
class FamilyLedgerTransactionEntity extends Equatable {
  const FamilyLedgerTransactionEntity({
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
  final DateTime? date;

  @override
  List<Object?> get props => [
        id,
        invoiceCode,
        recurring,
        subscriptionCode,
        studentCode,
        studentName,
        transactionType,
        status,
        method,
        description,
        items,
        amount,
        balance,
        date,
      ];
}

/// The full family billing ledger from `GET /api/v1/invoices/family-ledger`.
class FamilyLedgerEntity extends Equatable {
  const FamilyLedgerEntity({
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
  final List<FamilyLedgerPersonEntity> students;
  final List<FamilyLedgerPersonEntity> guardians;
  final List<FamilyLedgerTransactionEntity> transactions;

  @override
  List<Object?> get props => [
        ownerType,
        ownerCode,
        familyName,
        openBalance,
        paid,
        refunded,
        netPaid,
        inProcess,
        unpaid,
        students,
        guardians,
        transactions,
      ];
}
