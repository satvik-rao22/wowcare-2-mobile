import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../widgets/parent_transaction_card.dart';

part 'parent_billing_state.dart';

/// Owns the state for the parent-facing billing screen so the view stays
/// display-only.
///
/// Billing currently runs on demo data (see [_seedTransactions]); when the
/// WowCare billing domain is wired up, swap the seed methods for repository
/// calls without touching the view.
class ParentBillingCubit extends Cubit<ParentBillingState> {
  ParentBillingCubit() : super(const ParentBillingState.initial());

  /// Builds the initial demo dataset. Transaction dates are relative to "now",
  /// so they are generated lazily here rather than as compile-time constants.
  void loadInitial() {
    if (state.transactions.isNotEmpty) return;
    emit(
      state.copyWith(
        siblings: _seedSiblings(),
        transactions: _seedTransactions(),
      ),
    );
  }

  /// Pull-to-refresh hook. Kept as a no-op data reload for parity until the
  /// billing backend is integrated.
  Future<void> refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (isClosed) return;
    // Re-seed so relative transaction dates stay current after a refresh.
    emit(state.copyWith(transactions: _seedTransactions()));
  }

  void setDateRange(DateTime startDate, DateTime? endDate) {
    emit(
      state.copyWith(
        startDate: startDate,
        endDate: endDate ??
            DateTime(
              startDate.year,
              startDate.month,
              startDate.day,
              23,
              59,
              59,
            ),
      ),
    );
  }

  /// Simulates a "Pay Now" round-trip. Returns when the (currently faked)
  /// payment completes so the view can surface a confirmation.
  Future<void> payNow() async {
    if (state.isPaymentLoading) return;
    emit(state.copyWith(isPaymentLoading: true));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (isClosed) return;
    emit(state.copyWith(isPaymentLoading: false));
  }

  void beginAutoPay() {
    if (state.isAutoPayLoading) return;
    emit(state.copyWith(isAutoPayLoading: true));
  }

  void endAutoPay() {
    if (!state.isAutoPayLoading) return;
    emit(state.copyWith(isAutoPayLoading: false));
  }

  List<Map<String, String>> _seedSiblings() => const [
        {'name': 'Emma Johnson', 'room': 'Ladybugs • Room 101'},
        {'name': 'Liam Johnson', 'room': 'Caterpillars • Room 202'},
        {'name': 'Olivia Johnson', 'room': 'Butterflies • Room 305'},
      ];

  List<DemoTransaction> _seedTransactions() {
    final now = DateTime.now();
    return [
      DemoTransaction(
        id: '1',
        type: 'Invoice',
        amount: 450.00,
        date: now.subtract(const Duration(days: 5)),
        status: 'Unpaid',
        description: 'Monthly Tuition Fee - January 2024',
        studentName: 'Emma Johnson',
        studentRoom: 'Ladybugs • Room 101',
      ),
      DemoTransaction(
        id: '2',
        type: 'Payment',
        amount: 450.00,
        date: now.subtract(const Duration(days: 10)),
        status: 'Completed',
        paymentMode: 'Credit Card',
        description: 'Payment for Invoice #1234',
        studentName: 'Emma Johnson',
        studentRoom: 'Ladybugs • Room 101',
      ),
      DemoTransaction(
        id: '3',
        type: 'Invoice',
        amount: 320.00,
        date: now.subtract(const Duration(days: 8)),
        status: 'In Process',
        description: 'Activity Fee - Art Supplies',
        studentName: 'Liam Johnson',
        studentRoom: 'Caterpillars • Room 202',
      ),
      DemoTransaction(
        id: '4',
        type: 'Payment',
        amount: 280.00,
        date: now.subtract(const Duration(days: 15)),
        status: 'Completed',
        paymentMode: 'Bank Transfer',
        description: 'Payment for Invoice #1230',
        studentName: 'Olivia Johnson',
        studentRoom: 'Butterflies • Room 305',
      ),
      DemoTransaction(
        id: '5',
        type: 'Refund',
        amount: 50.00,
        date: now.subtract(const Duration(days: 20)),
        status: 'Completed',
        paymentMode: 'Credit Card',
        description: 'Refund for Cancelled Field Trip',
        studentName: 'Emma Johnson',
        studentRoom: 'Ladybugs • Room 101',
      ),
    ];
  }
}
