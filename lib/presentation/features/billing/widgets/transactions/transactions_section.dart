import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/billing/cubit/transactions_cubit.dart';
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
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';

class TransactionsSection extends StatefulWidget {
  const TransactionsSection({super.key});

  @override
  State<TransactionsSection> createState() => _TransactionsSectionState();
}

class _TransactionsSectionState extends State<TransactionsSection> {
  late final TransactionsCubit _cubit = TransactionsCubit();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TransactionsCubit>.value(
      value: _cubit,
      child: BlocBuilder<TransactionsCubit, TransactionsState>(
        builder: (context, state) {
    final List<TransactionRecord> visibleTransactions =
        state.visibleTransactions;
    final double totalInvoiced = state.totalInvoiced;
    final double paidPercent = state.paidPercent;
    final double inProcessPercent = state.inProcessPercent;
    final double unpaidPercent = state.unpaidPercent;
    final double refundPercent = state.refundPercent;

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
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          )
        else
          Column(
            children: visibleTransactions
                .map(
                  (TransactionRecord record) => Padding(
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
        },
      ),
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
                  onChanged: (value) => _cubit.setSearchQuery(value),
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
    _searchController.clear();
    _cubit.clearSearch();
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


