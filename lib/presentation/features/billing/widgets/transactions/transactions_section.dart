import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/core_utils.dart';
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
  const TransactionsSection({
    super.key,
    this.onRegisterRefresh,
    this.scrollController,
  });

  /// Lets the parent (Billing page) trigger a pull-to-refresh of this tab.
  final void Function(Future<void> Function())? onRegisterRefresh;

  /// The Billing page's scroll controller. When provided, the list auto-loads
  /// the next page as the user nears the bottom (infinite scroll).
  final ScrollController? scrollController;

  @override
  State<TransactionsSection> createState() => _TransactionsSectionState();
}

class _TransactionsSectionState extends State<TransactionsSection> {
  late final TransactionsCubit _cubit = serviceLocator<TransactionsCubit>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit.load();
    widget.onRegisterRefresh?.call(_refresh);
    widget.scrollController?.addListener(_onScroll);
  }

  /// Reloads the invoice list (page 0) and the overview totals for this tab.
  Future<void> _refresh() async {
    await _cubit.load();
  }

  /// Auto-loads the next page when the user scrolls within 300px of the bottom.
  void _onScroll() {
    final controller = widget.scrollController;
    if (controller == null || !controller.hasClients) return;
    final position = controller.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _cubit.loadNextPage();
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TransactionsCubit>.value(
      value: _cubit,
      child: BlocListener<TransactionsCubit, TransactionsState>(
        listenWhen: (p, c) =>
            (p.errorMessage != c.errorMessage && c.errorMessage != null) ||
            (p.successMessage != c.successMessage && c.successMessage != null),
        listener: (context, state) {
          if (state.errorMessage != null) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: state.errorMessage!,
              isError: true,
            );
          } else if (state.successMessage != null) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: state.successMessage!,
              isSuccess: true,
            );
          }
        },
        child: BlocBuilder<TransactionsCubit, TransactionsState>(
          builder: (context, state) {
            final List<TransactionRecord> visibleTransactions =
                state.visibleTransactions;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 4),
                AccountingDateRangeSelector(
                  initialStartDate: state.dateFrom,
                  initialEndDate: state.dateTo,
                  onRangeChanged: (start, end) =>
                      _cubit.setDateRange(start, end),
                ),
                const SizedBox(height: 12),
                AmountInvoicedStatBar(
                  totalAmount: state.totalInvoiced,
                  paidPercentage: state.paidPercent,
                  grossPaidPercentage: state.grossPaidPercent,
                  inProcessPercentage: state.inProcessPercent,
                  unpaidPercentage: state.unpaidPercent,
                  refundPercentage: state.refundPercent,
                ),
                const SizedBox(height: 12),
                _buildSearchBar(context),
                const SizedBox(height: 16),
                if (state.isLoadingList && visibleTransactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  )
                else if (visibleTransactions.isEmpty)
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
                else ...<Widget>[
                  Column(
                    children: visibleTransactions
                        .map(
                          (TransactionRecord record) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: BillingTransactionCard(
                              transaction: record.item,
                              onView: () => _openViewInvoice(record.item),
                              onViewReceipt: () =>
                                  _openViewReceipt(record.item, 'receipt'),
                              onSendInvoice: () => _openSendInvoice(record.item),
                              onReceivePayment: () =>
                                  _openReceivePayment(record.item),
                              onIssueRefund: () => _openIssueRefund(record.item),
                              onEditInvoice: _showEditUnavailable,
                              onBillingProfile: () =>
                                  _openTransactionDetails(record.item),
                              onMessage: _showMessageUnavailable,
                              onCancel: () => _confirmCancel(record.item),
                              onDelete: () => _confirmDelete(record.item),
                              onLongPress: () =>
                                  _openTransactionDetails(record.item),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  _buildPaginationFooter(state),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Bottom-of-list affordance: a spinner while a page is appending, or a
  /// "Load More" button when more pages remain (a fallback for when the
  /// content doesn't fill the screen / the scroll controller is absent).
  Widget _buildPaginationFooter(TransactionsState state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      );
    }
    if (state.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: TextButton(
            onPressed: () => _cubit.loadNextPage(),
            child: const Text(
              'Load More',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 8);
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

  void _showMessageUnavailable() {
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Messaging is not available yet.',
      isWarning: true,
    );
  }

  void _showEditUnavailable() {
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Editing invoices is not available yet.',
      isWarning: true,
    );
  }

  /// Guards against rows without a backend invoice code (cannot act on them).
  String? _invoiceCodeOrWarn(TransactionItem item) {
    final code = item.invoiceCode?.trim();
    if (code == null || code.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'This invoice cannot be modified.',
        isWarning: true,
      );
      return null;
    }
    return code;
  }

  Future<void> _confirmCancel(TransactionItem item) async {
    final code = _invoiceCodeOrWarn(item);
    if (code == null) return;
    final confirmed = await _confirmAction(
      title: 'Cancel invoice?',
      message: 'This will cancel the invoice. This action cannot be undone.',
      confirmLabel: 'Cancel invoice',
    );
    if (confirmed) await _cubit.cancelInvoice(code);
  }

  Future<void> _confirmDelete(TransactionItem item) async {
    final code = _invoiceCodeOrWarn(item);
    if (code == null) return;
    final confirmed = await _confirmAction(
      title: 'Delete invoice?',
      message: 'This will permanently delete the invoice.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed) await _cubit.deleteInvoice(code);
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor:
                  isDestructive ? AppColors.errorColor : AppColors.primaryColor,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
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
