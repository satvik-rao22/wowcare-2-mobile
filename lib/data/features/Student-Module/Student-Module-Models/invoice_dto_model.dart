import 'dart:convert';
import 'package:equatable/equatable.dart';

import '../../../../core/util/typedefs.dart';

class InvoiceDTO extends Equatable {
  final int? id;
  final double? amount;
  final String? dueDate;
  final String? status;

  const InvoiceDTO({this.id, this.amount, this.dueDate, this.status});

  InvoiceDTO copyWith({
    int? id,
    double? amount,
    String? dueDate,
    String? status,
  }) {
    return InvoiceDTO(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
    );
  }

  DataMap toMap() {
    return <String, dynamic>{
      'id': id,
      'amount': amount,
      'dueDate': dueDate,
      'status': status,
    };
  }

  factory InvoiceDTO.fromMap(DataMap map) {
    return InvoiceDTO(
      id: map['id'] as int?,
      amount: map['amount'] as double?,
      dueDate: map['dueDate'] as String?,
      status: map['status'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory InvoiceDTO.fromJson(String source) =>
      InvoiceDTO.fromMap(json.decode(source) as DataMap);

  @override
  List<Object?> get props => [id, amount, dueDate, status];

  @override
  bool get stringify => true;

  static const empty = InvoiceDTO(
    id: null,
    amount: null,
    dueDate: null,
    status: null,
  );

  static const demo = InvoiceDTO(
    id: 1,
    amount: 500.0,
    dueDate: '2025-10-01',
    status: 'Pending',
  );

  static const demoList = [demo];
}
