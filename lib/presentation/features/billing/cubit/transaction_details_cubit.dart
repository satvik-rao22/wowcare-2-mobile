import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../widgets/transactions/transaction_item.dart';

part 'transaction_details_state.dart';

/// Owns the family/sibling transaction-details screen state: the sibling list,
/// family members, summary totals, date range, and loading/error flags. Data is
/// dummy today; swap the `_generate*` helpers for repository calls when billing
/// has a backend.
class TransactionDetailsCubit extends Cubit<TransactionDetailsState> {
  TransactionDetailsCubit() : super(const TransactionDetailsState.initial());

  Future<void> initialize() async {
    emit(state.copyWith(isLoadingSiblings: true, isLoadingFamily: true));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (isClosed) return;
    emit(state.copyWith(
      startDate: () => null,
      endDate: () => null,
      siblingSummary: const {
        'netAmountPaid': 1250.0,
        'amountUnpaid': 450.0,
        'amountInProcess': 200.0,
        'amountRefund': 85.0,
        'amountPaid': 1500.0,
      },
      siblingTransactions: _generateDummyTransactions(),
      familyChildren: const [
        {'fullName': 'John Doe', 'photoUuid': null},
        {'fullName': 'Jane Doe', 'photoUuid': null},
      ],
      familyParents: const [
        {'fullName': 'Michael Doe'},
        {'fullName': 'Sarah Doe'},
      ],
      isLoadingSiblings: false,
      isLoadingFamily: false,
    ));
  }

  Future<void> loadSiblingTransactions({bool refresh = false}) async {
    if (refresh) {
      emit(state.copyWith(
        hasMoreData: true,
        siblingTransactions: const <TransactionItem>[],
      ));
    }
    emit(state.copyWith(isLoadingSiblings: true, hasError: false));
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (isClosed) return;
    emit(state.copyWith(
      siblingTransactions: refresh
          ? _generateDummyTransactions()
          : <TransactionItem>[
              ...state.siblingTransactions,
              ..._generateDummyTransactions(),
            ],
      isLoadingSiblings: false,
      hasMoreData: false,
    ));
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMoreData) return;
    emit(state.copyWith(isLoadingMore: true));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (isClosed) return;
    emit(state.copyWith(isLoadingMore: false, hasMoreData: false));
  }

  /// Applies a new date range and reloads the sibling transactions.
  Future<void> applyDateRange(DateTime? start, DateTime? end) async {
    emit(state.copyWith(startDate: () => start, endDate: () => end));
    await loadSiblingTransactions(refresh: true);
  }

  List<TransactionItem> _generateDummyTransactions() {
    final now = DateTime.now();
    return [
      TransactionItem(
        id: 2001,
        transactionType: 'Invoice',
        date: now.subtract(const Duration(days: 5)),
        amount: 275.0,
        status: 'Success',
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
      TransactionItem(
        id: 2002,
        transactionType: 'Payment',
        date: now.subtract(const Duration(days: 3)),
        amount: 190.0,
        status: 'In-Process',
        description: 'After School Activities',
        studentName: 'Jane Doe',
        classroom: 'Grade 3 - B',
        studentId: 202,
        refTable: 'Payment',
        refTableId: 6001,
        paymentMode: 'Credit Card',
        balance: 90.0,
        note: 'Awaiting payment confirmation',
        endDate: '2025-11-12',
        studentOpenBalance: 90.0,
      ),
      TransactionItem(
        id: 2003,
        transactionType: 'Invoice',
        date: now.subtract(const Duration(days: 2)),
        amount: 320.0,
        status: 'Success',
        description: 'Meal Plan - Quarter 4',
        studentName: 'John Doe',
        classroom: 'Grade 5 - A',
        studentId: 201,
        refTable: 'Invoice',
        refTableId: 5002,
        paymentMode: 'Cash',
        balance: 0,
        note: 'Payment received at front desk',
        endDate: '2025-11-15',
        studentOpenBalance: 0,
      ),
    ];
  }
}
