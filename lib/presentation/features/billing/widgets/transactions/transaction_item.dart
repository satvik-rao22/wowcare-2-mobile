class TransactionItem {
  TransactionItem({
    required this.id,
    required this.transactionType,
    required this.date,
    required this.amount,
    required this.status,
    required this.description,
    required this.studentName,
    required this.classroom,
    this.studentId,
    this.studentPhotoUuid,
    this.refTable,
    this.refTableId,
    this.balance,
    this.note,
    this.endDate,
    this.paymentMode,
    this.studentOpenBalance,
  });

  final int id;
  final String transactionType;
  final DateTime date;
  final double amount;
  final String status;
  final String description;
  final String studentName;
  final String classroom;
  final int? studentId;
  final String? studentPhotoUuid;
  final String? refTable;
  final int? refTableId;
  final double? balance;
  final String? note;
  final String? endDate;
  final String? paymentMode;
  final double? studentOpenBalance;

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    final List<dynamic> students =
        (map['students'] as List<dynamic>? ?? <dynamic>[]);
    final Map<String, dynamic>? firstStudent =
        students.isNotEmpty ? students.first as Map<String, dynamic> : null;

    return TransactionItem(
      id: map['id'] as int,
      transactionType: (map['transactionType'] ?? '').toString(),
      date: DateTime.tryParse((map['date'] ?? '').toString()) ??
          DateTime.now(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      status: (map['processStatus'] ?? map['status'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      studentName: (firstStudent?['fullName'] ?? 'Unknown').toString(),
      classroom: (firstStudent?['roomName'] ?? '').toString(),
      studentId: firstStudent?['id'] as int?,
      studentPhotoUuid: firstStudent?['photoUuid'] as String?,
      refTable: map['refTable'] as String?,
      refTableId: map['refTableId'] as int?,
      balance: (map['balance'] as num?)?.toDouble(),
      note: map['note'] as String?,
      endDate: map['endDate'] as String?,
      paymentMode: map['paymentMode'] as String?,
      studentOpenBalance:
          (firstStudent?['balance'] as num?)?.toDouble(),
    );
  }

  String get displayDescription => description.isEmpty ? '-' : description;
}

