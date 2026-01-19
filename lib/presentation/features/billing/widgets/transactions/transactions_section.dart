import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/amount_invoiced_stat_bar.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/date_range_selector.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/billing_transaction_card.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/send_invoice_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/receive_payment_issue_refund_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_details_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/view_receipt_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/view_invoice_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';

class TransactionsSection extends StatefulWidget {
  const TransactionsSection({super.key});

  @override
  State<TransactionsSection> createState() => _TransactionsSectionState();
}

class _TransactionsSectionState extends State<TransactionsSection> {
  final TextEditingController _searchController = TextEditingController();

  // TODO: Replace with real API data when the backend is ready.
  final List<_TransactionRecord> _transactions = <_TransactionRecord>[
    _TransactionRecord(
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
    _TransactionRecord(
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
    _TransactionRecord(
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
    _TransactionRecord(
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
    _TransactionRecord(
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
    _TransactionRecord(
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<_TransactionRecord> visibleTransactions = _visibleTransactions();
    final double totalInvoiced = _totalAmountFor(
      <TransactionStatus>{
        TransactionStatus.paid,
        TransactionStatus.inProcess,
        TransactionStatus.unpaid,
      },
    );
    final double totalPaid = _totalAmountFor(<TransactionStatus>{TransactionStatus.paid});
    final double totalInProcess =
        _totalAmountFor(<TransactionStatus>{TransactionStatus.inProcess});
    final double paidPercent = _percentage(totalPaid, totalInvoiced);
    final double inProcessPercent = _percentage(totalInProcess, totalInvoiced);
    final double unpaidPercent =
        _percentage(_totalAmountFor(<TransactionStatus>{TransactionStatus.unpaid}), totalInvoiced);
    final double totalRefund =
        _totalAmountFor(<TransactionStatus>{TransactionStatus.refund});
    final double refundPercent = _percentage(totalRefund, totalInvoiced);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 4),
        // Text(
        //   'Transactions',
        //   style: const TextStyle(
        //     fontFamily: 'Manrope',
        //     fontSize: 17,
        //     fontWeight: FontWeight.w600,
        //     color: AppColors.primaryColor,
        //   ),
        // ),
        // const SizedBox(height: 16),
        const AccountingDateRangeSelector(),
        const SizedBox(height: 12),
        AmountInvoicedStatBar(
          totalAmount: totalInvoiced,
          paidPercentage: paidPercent,
          inProcessPercentage: inProcessPercent,
          unpaidPercentage: unpaidPercent,
          refundPercentage: refundPercent,
        ),
        const SizedBox(height: 12),
        _buildSearchBar(context),
        const SizedBox(height: 16),
        if (visibleTransactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No transactions match your filters.',
                style: AppTextStyles.title.copyWith(
                  fontSize: 15,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          )
        else
          Column(
            children: visibleTransactions
                .map(
                  (_TransactionRecord record) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: BillingTransactionCard(
                      transaction: record.item,
                      onView: () => _openViewInvoice(record.item),
                      onViewReceipt: () => _openViewReceipt(record.item, 'receipt'),
                      onSendInvoice: () => _openSendInvoice(record.item),
                      onReceivePayment: () => _openReceivePayment(record.item),
                      onIssueRefund: () => _openIssueRefund(record.item),
                      onBillingProfile: () => _openTransactionDetails(record.item),
                      onDelete: () => _showActionFeedback('Delete confirmed'),
                      onLongPress: () => _openTransactionDetails(record.item),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return CustomSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Search by student, ID, or description',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: <Widget>[
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Material(
                      color: AppColors.billingCardColor,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {},
                        child: Center(
                          child: SvgPicture.asset(
                            MediaRes.filterIcon,
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  CustomClearAllChip(
                    onTap: _clearSearch,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
    });
  }

  List<_TransactionRecord> _visibleTransactions() {
    final String query = _searchController.text.trim().toLowerCase();
    final Iterable<_TransactionRecord> filtered = _transactions.where((_TransactionRecord transaction) {
      final TransactionItem item = transaction.item;
      final bool matchesQuery = query.isEmpty ||
          item.studentName.toLowerCase().contains(query) ||
          item.id.toString().contains(query) ||
          item.description.toLowerCase().contains(query);
      return matchesQuery;
    });
    return filtered.toList();
  }

  double _totalAmountFor(Set<TransactionStatus> statuses) {
    return _transactions
        .where((_TransactionRecord transaction) => statuses.contains(transaction.status))
        .fold<double>(0, (double sum, _TransactionRecord record) => sum + record.item.amount);
  }

  double _percentage(double value, double total) {
    if (total <= 0) {
      return 0;
    }
    return (value / total) * 100;
  }

  void _showActionFeedback(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label tapped (UI only).'),
      ),
    );
  }

  void _openSendInvoice(TransactionItem item) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => SendInvoiceScreen(transaction: item),
      ),
    );
  }

  void _openReceivePayment(TransactionItem item) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) =>
            ReceivePaymentIssueRefundScreen(transaction: item),
      ),
    );
  }

  void _openIssueRefund(TransactionItem item) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => ReceivePaymentIssueRefundScreen(
          transaction: item,
          isRefund: true,
        ),
      ),
    );
  }

  void _openTransactionDetails(TransactionItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionDetailsScreen(
          transaction: item,
        ),
      ),
    );
  }

  void _openViewReceipt(TransactionItem item, String viewType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ViewReceiptScreen(
          transaction: item,
          viewType: viewType,
        ),
      ),
    );
  }

  void _openViewInvoice(TransactionItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ViewInvoiceScreen(
          transaction: item,
        ),
      ),
    );
  }
}

class _TransactionRecord {
  const _TransactionRecord({
    required this.item,
    required this.status,
  });

  final TransactionItem item;
  final TransactionStatus status;
}

enum TransactionStatus {
  paid,
  inProcess,
  unpaid,
  refund,
  failed,
}

extension on TransactionStatus {
  String get displayLabel {
    switch (this) {
      case TransactionStatus.paid:
        return 'Paid';
      case TransactionStatus.inProcess:
        return 'In Process';
      case TransactionStatus.unpaid:
        return 'Unpaid';
      case TransactionStatus.refund:
        return 'Refund';
      case TransactionStatus.failed:
        return 'Failed';
    }
  }
}


