import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../widgets/transactions/transaction_item.dart';

part 'transactions_state.dart';

enum TransactionStatus { paid, inProcess, unpaid, refund, failed }

class TransactionRecord {
  const TransactionRecord({required this.item, required this.status});

  final TransactionItem item;
  final TransactionStatus status;
}

/// Owns the Transactions tab's list + search state. Records are demo data
/// today; swap [_seedTransactions] for a repository call when billing has a
/// backend.
class TransactionsCubit extends Cubit<TransactionsState> {
  TransactionsCubit() : super(TransactionsState.initial());

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void clearSearch() {
    emit(state.copyWith(searchQuery: ''));
  }

  static List<TransactionRecord> seedTransactions() => <TransactionRecord>[
        TransactionRecord(
          status: TransactionStatus.paid,
          item: TransactionItem(
            id: 1001,
            transactionType: 'Invoice',
            date: DateTime(2025, 11, 2, 9, 30),
            amount: 275.0,
            status: 'Sent',
            description: 'Tuition Invoice November',
            studentName: 'John Doe',
            classroom: 'Grade 5 - A',
            studentId: 201,
            refTable: 'Invoice',
            refTableId: 5001,
            paymentMode: 'Bank Transfer',
            balance: 0,
            note: 'Paid in full',
            endDate: '2025-11-10',
            studentOpenBalance: 0,
          ),
        ),
        TransactionRecord(
          status: TransactionStatus.inProcess,
          item: TransactionItem(
            id: 1002,
            transactionType: 'Invoice',
            date: DateTime(2025, 11, 4, 14, 10),
            amount: 190.0,
            status: 'In-Process',
            description: 'After School Activities',
            studentName: 'Emily Carter',
            classroom: 'Grade 3 - B',
            studentId: 202,
            refTable: 'Invoice',
            refTableId: 5002,
            paymentMode: 'Credit Card',
            balance: 90.0,
            note: 'Awaiting payment confirmation',
            endDate: '2025-11-12',
            studentOpenBalance: 90.0,
          ),
        ),
        TransactionRecord(
          status: TransactionStatus.unpaid,
          item: TransactionItem(
            id: 1003,
            transactionType: 'Payment',
            date: DateTime(2025, 11, 4, 16, 45),
            amount: 210.0,
            status: 'Draft',
            description: 'Transportation Plan',
            studentName: 'Liam Johnson',
            classroom: 'Grade 1 - C',
            studentId: 203,
            refTable: 'Payment',
            refTableId: 6001,
            paymentMode: 'ACH',
            balance: 210.0,
            note: 'Parent requested ACH',
            endDate: '2025-11-18',
            studentOpenBalance: 210.0,
          ),
        ),
        TransactionRecord(
          status: TransactionStatus.paid,
          item: TransactionItem(
            id: 1004,
            transactionType: 'Payment',
            date: DateTime(2025, 11, 6, 10, 5),
            amount: 320.0,
            status: 'Success',
            description: 'Meal Plan - Quarter 4',
            studentName: 'Sophia Martinez',
            classroom: 'Grade 4 - A',
            studentId: 204,
            refTable: 'Payment',
            refTableId: 6002,
            paymentMode: 'Cash',
            balance: 0,
            note: 'Payment received at front desk',
            endDate: '2025-11-15',
            studentOpenBalance: 0,
          ),
        ),
        TransactionRecord(
          status: TransactionStatus.refund,
          item: TransactionItem(
            id: 1005,
            transactionType: 'Refund',
            date: DateTime(2025, 11, 7, 11, 20),
            amount: 85.0,
            status: 'Success',
            description: 'Activity Refund',
            studentName: 'Mason Lee',
            classroom: 'Pre-K - Butterflies',
            studentId: 205,
            refTable: 'Refund',
            refTableId: 7001,
            paymentMode: 'Credit Card',
            balance: 0,
            note: 'Refund processed to card',
            endDate: '2025-11-09',
            studentOpenBalance: 0,
          ),
        ),
        TransactionRecord(
          status: TransactionStatus.failed,
          item: TransactionItem(
            id: 1006,
            transactionType: 'Payment',
            date: DateTime(2025, 11, 7, 18, 30),
            amount: 145.0,
            status: 'Failed',
            description: 'Late Fee Payment',
            studentName: 'Ava Patel',
            classroom: 'Grade 2 - A',
            studentId: 206,
            refTable: 'Payment',
            refTableId: 6003,
            paymentMode: 'Credit Card',
            balance: 145.0,
            note: 'Card declined',
            endDate: '2025-11-14',
            studentOpenBalance: 145.0,
          ),
        ),
      ];
}
