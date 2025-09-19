import 'dart:convert';
import 'package:equatable/equatable.dart';

import '../../../../core/util/typedefs.dart';
import 'invoice_dto_model.dart';
import 'student_data_model.dart';

class TransactionDTO extends Equatable {
  final int? id;
  final String? transactionType;
  final String? date;
  final String? endDate;
  final String? createdDate;
  final double? amount;
  final double? receivedAmount;
  final double? balance;
  final String? processStatus;
  final String? description;
  final String? paymentMode;
  final String? chequeNumber;
  final String? transactionNumber;
  final String? note;
  final bool? isLedgerTransaction;
  final bool? isRefund;
  final bool? isSendEmail;
  final String? refTable;
  final int? refTableId;
  final List<StudentDataModel>? students;
  final int? schoolId;
  final String? status;
  final String? lastModified;
  final String? lastModifiedBy;
  final InvoiceDTO? dummyInvoice;
  final double? localBalanceAmount;
  final int? familyId;
  final Map<String, dynamic>? transactionObj;

  const TransactionDTO({
    this.id,
    this.transactionType,
    this.date,
    this.endDate,
    this.createdDate,
    this.amount,
    this.receivedAmount,
    this.balance,
    this.processStatus,
    this.description,
    this.paymentMode,
    this.chequeNumber,
    this.transactionNumber,
    this.note,
    this.isLedgerTransaction,
    this.isRefund,
    this.isSendEmail,
    this.refTable,
    this.refTableId,
    this.students,
    this.schoolId,
    this.status,
    this.lastModified,
    this.lastModifiedBy,
    this.dummyInvoice,
    this.localBalanceAmount,
    this.familyId,
    this.transactionObj,
  });

  TransactionDTO copyWith({
    int? id,
    String? transactionType,
    String? date,
    String? endDate,
    String? createdDate,
    double? amount,
    double? receivedAmount,
    double? balance,
    String? processStatus,
    String? description,
    String? paymentMode,
    String? chequeNumber,
    String? transactionNumber,
    String? note,
    bool? isLedgerTransaction,
    bool? isRefund,
    bool? isSendEmail,
    String? refTable,
    int? refTableId,
    List<StudentDataModel>? students,
    int? schoolId,
    String? status,
    String? lastModified,
    String? lastModifiedBy,
    InvoiceDTO? dummyInvoice,
    double? localBalanceAmount,
    int? familyId,
    Map<String, dynamic>? transactionObj,
  }) {
    return TransactionDTO(
      id: id ?? this.id,
      transactionType: transactionType ?? this.transactionType,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      createdDate: createdDate ?? this.createdDate,
      amount: amount ?? this.amount,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      balance: balance ?? this.balance,
      processStatus: processStatus ?? this.processStatus,
      description: description ?? this.description,
      paymentMode: paymentMode ?? this.paymentMode,
      chequeNumber: chequeNumber ?? this.chequeNumber,
      transactionNumber: transactionNumber ?? this.transactionNumber,
      note: note ?? this.note,
      isLedgerTransaction: isLedgerTransaction ?? this.isLedgerTransaction,
      isRefund: isRefund ?? this.isRefund,
      isSendEmail: isSendEmail ?? this.isSendEmail,
      refTable: refTable ?? this.refTable,
      refTableId: refTableId ?? this.refTableId,
      students: students ?? this.students,
      schoolId: schoolId ?? this.schoolId,
      status: status ?? this.status,
      lastModified: lastModified ?? this.lastModified,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      dummyInvoice: dummyInvoice ?? this.dummyInvoice,
      localBalanceAmount: localBalanceAmount ?? this.localBalanceAmount,
      familyId: familyId ?? this.familyId,
      transactionObj: transactionObj ?? this.transactionObj,
    );
  }

  DataMap toMap() {
    return <String, dynamic>{
      'id': id,
      'transactionType': transactionType,
      'date': date,
      'endDate': endDate,
      'createdDate': createdDate,
      'amount': amount,
      'receivedAmount': receivedAmount,
      'balance': balance,
      'processStatus': processStatus,
      'description': description,
      'paymentMode': paymentMode,
      'chequeNumber': chequeNumber,
      'transactionNumber': transactionNumber,
      'note': note,
      'isLedgerTransaction': isLedgerTransaction,
      'isRefund': isRefund,
      'isSendEmail': isSendEmail,
      'refTable': refTable,
      'refTableId': refTableId,
      'students': students?.map((x) => x.toMap()).toList(),
      'schoolId': schoolId,
      'status': status,
      'lastModified': lastModified,
      'lastModifiedBy': lastModifiedBy,
      'dummyInvoice': dummyInvoice?.toMap(),
      'localBalanceAmount': localBalanceAmount,
      'familyId': familyId,
      'transactionObj': transactionObj,
    };
  }

  factory TransactionDTO.fromMap(DataMap map) {
    return TransactionDTO(
      id: map['id'] as int?,
      transactionType: map['transactionType'] as String?,
      date: map['date'] as String?,
      endDate: map['endDate'] as String?,
      createdDate: map['createdDate'] as String?,
      amount: map['amount'] as double?,
      receivedAmount: map['receivedAmount'] as double?,
      balance: map['balance'] as double?,
      processStatus: map['processStatus'] as String?,
      description: map['description'] as String?,
      paymentMode: map['paymentMode'] as String?,
      chequeNumber: map['chequeNumber'] as String?,
      transactionNumber: map['transactionNumber'] as String?,
      note: map['note'] as String?,
      isLedgerTransaction: map['isLedgerTransaction'] as bool?,
      isRefund: map['isRefund'] as bool?,
      isSendEmail: map['isSendEmail'] as bool?,
      refTable: map['refTable'] as String?,
      refTableId: map['refTableId'] as int?,
      students: (map['students'] as List<dynamic>?)
          ?.map<StudentDataModel>((x) => StudentDataModel.fromMap(x as DataMap))
          .toList(),
      schoolId: map['schoolId'] as int?,
      status: map['status'] as String?,
      lastModified: map['lastModified'] as String?,
      lastModifiedBy: map['lastModifiedBy'] as String?,
      dummyInvoice: map['dummyInvoice'] != null
          ? InvoiceDTO.fromMap(map['dummyInvoice'] as DataMap)
          : null,
      localBalanceAmount: map['localBalanceAmount'] as double?,
      familyId: map['familyId'] as int?,
      transactionObj: map['transactionObj'] as Map<String, dynamic>?,
    );
  }

  String toJson() => json.encode(toMap());

  factory TransactionDTO.fromJson(String source) =>
      TransactionDTO.fromMap(json.decode(source) as DataMap);

  @override
  List<Object?> get props => [
    id,
    transactionType,
    date,
    endDate,
    createdDate,
    amount,
    receivedAmount,
    balance,
    processStatus,
    description,
    paymentMode,
    chequeNumber,
    transactionNumber,
    note,
    isLedgerTransaction,
    isRefund,
    isSendEmail,
    refTable,
    refTableId,
    students,
    schoolId,
    status,
    lastModified,
    lastModifiedBy,
    dummyInvoice,
    localBalanceAmount,
    familyId,
    transactionObj,
  ];

  @override
  bool get stringify => true;

  static const empty = TransactionDTO(
    id: null,
    transactionType: null,
    date: null,
    endDate: null,
    createdDate: null,
    amount: null,
    receivedAmount: null,
    balance: null,
    processStatus: null,
    description: null,
    paymentMode: null,
    chequeNumber: null,
    transactionNumber: null,
    note: null,
    isLedgerTransaction: null,
    isRefund: null,
    isSendEmail: null,
    refTable: null,
    refTableId: null,
    students: null,
    schoolId: null,
    status: null,
    lastModified: null,
    lastModifiedBy: null,
    dummyInvoice: null,
    localBalanceAmount: null,
    familyId: null,
    transactionObj: null,
  );

  static final demo = TransactionDTO(
    id: 1,
    transactionType: 'Payment',
    date: '2025-09-18',
    endDate: null,
    createdDate: '2025-09-18',
    amount: 500.0,
    receivedAmount: 500.0,
    balance: 0.0,
    processStatus: 'Completed',
    description: 'Tuition Fee',
    paymentMode: 'Credit Card',
    chequeNumber: null,
    transactionNumber: 'TXN001',
    note: 'Paid on time',
    isLedgerTransaction: true,
    isRefund: false,
    isSendEmail: true,
    refTable: 'Invoice',
    refTableId: 1,
    students: null, // Replace with null or provide a valid list if needed
    schoolId: 1,
    status: 'Active',
    lastModified: '2025-09-18',
    lastModifiedBy: 'Admin',
    dummyInvoice:
        null, // Replace with null or provide a valid InvoiceDTO if needed
    localBalanceAmount: 0.0,
    familyId: 101,
    transactionObj: {'key': 'value'},
  );

  static final demoList = demo;
}
