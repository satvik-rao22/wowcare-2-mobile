import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/presentation/features/billing/model/billing_route_args.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/billing/view_model/transactions_cubit.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/amount_invoiced_stat_bar.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/date_range_selector.dart';
import 'package:wowcare/presentation/features/billing/view/create_invoice_screen.dart';
import 'package:wowcare/presentation/features/billing/model/invoice_draft.dart';
import 'package:wowcare/presentation/features/billing/model/student_models.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/billing_transaction_card.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/send_invoice_screen.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/receive_payment_issue_refund_screen.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/transaction_details_screen.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/view_receipt_screen.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/view_invoice_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

class TransactionsSection extends StatefulWidget {
  const TransactionsSection({
    super.key,
    this.onRegisterRefresh,
    this.onRegisterLoadNextPage,
    this.onLoadMoreNeeded,
    this.initialFilter,
    this.onNavigateToOutstanding,
  });

  /// Lets the parent (Billing page) trigger a pull-to-refresh of this tab.
  final void Function(Future<void> Function())? onRegisterRefresh;

  /// Registers the "load next page" callback with the parent's scroll handler.
  final void Function(VoidCallback)? onRegisterLoadNextPage;

  /// Asks the parent to re-check whether the next page should load (e.g. when
  /// the current content doesn't fill the viewport).
  final VoidCallback? onLoadMoreNeeded;

  /// A summary-card filter to apply on first load — set when the user taps a
  /// filter on the Student(s) tab and is routed here. Ignored for Outstanding.
  final BillingSummaryFilter? initialFilter;

  /// Routes an Outstanding tap back to the Student(s) tab (Outstanding lives
  /// there, not in the Transactions list).
  final VoidCallback? onNavigateToOutstanding;

  @override
  State<TransactionsSection> createState() => _TransactionsSectionState();
}

class _TransactionsSectionState extends State<TransactionsSection> {
  late final TransactionsCubit _cubit = serviceLocator<TransactionsCubit>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit.loadOverview();
    final TransactionFilter? initial =
        transactionFilterOf(widget.initialFilter);
    if (initial != null) {
      _cubit.applyFilter(initial);
    } else {
      _cubit.loadTransactions();
    }
    widget.onRegisterRefresh?.call(_refresh);
    widget.onRegisterLoadNextPage?.call(_cubit.loadNextPage);
  }

  /// Reloads the overview totals + the transactions list for this tab.
  Future<void> _refresh() async {
    await Future.wait<void>([
      _cubit.loadOverview(),
      _cubit.loadTransactions(),
    ]);
  }

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
                  netPaidAmount: state.netPaidAmount,
                  paidAmount: state.paidAmount,
                  inProcessAmount: state.inProcessAmount,
                  outstandingAmount: state.outstandingAmount,
                  refundedAmount: state.refundedAmount,
                  selectedFilter: billingFilterOf(state.activeFilter),
                  onFilterTap: _onFilterTap,
                ),
                const SizedBox(height: 12),
                _buildSearchBar(context),
                const SizedBox(height: 16),
                if (state.isLoading)
                  ...List.generate(
                    5,
                    (_) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: BillingTransactionShimmer(),
                    ),
                  )
                else if (visibleTransactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        BillingStrings.noTransactionsMatchYourFilters,
                        style: TextStyle(
                          fontFamily: Fonts.manrope,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  )
                else ...[
                  // Short content → ask the parent to load the next page.
                  if (state.hasMore)
                    Builder(builder: (_) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        widget.onLoadMoreNeeded?.call();
                      });
                      return const SizedBox.shrink();
                    }),
                  ...visibleTransactions.map(
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
                        onEditInvoice: () => _openEditInvoice(record.item),
                        onBillingProfile: () =>
                            _openTransactionDetails(record.item),
                        onMessage: _showMessageUnavailable,
                        onCancel: () => _confirmCancel(record.item),
                        onDelete: () => _confirmDelete(record.item),
                        onLongPress: () =>
                            _openTransactionDetails(record.item),
                      ),
                    ),
                  ),
                  if (state.isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: PrimaryCircularLoader()),
                    ),
                ],
              ],
            );
          },
        ),
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
                  hintText: BillingStrings.searchByStudentIdOrDescription,
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

  /// Handles a summary-card tap. The four list filters scope the Transactions
  /// list in place (re-tapping the active one clears it); Outstanding routes
  /// back to the Student(s) tab.
  void _onFilterTap(BillingSummaryFilter filter) {
    if (filter == BillingSummaryFilter.outstanding) {
      widget.onNavigateToOutstanding?.call();
      return;
    }
    final tapped = transactionFilterOf(filter);
    final next = _cubit.state.activeFilter == tapped ? null : tapped;
    _cubit.applyFilter(next);
  }

  void _clearSearch() {
    _searchController.clear();
    _cubit.clearSearch();
    _cubit.applyFilter(null);
  }

  void _showMessageUnavailable() {
    CoreUtils.showTopSnackBar(
      context: context,
      message: BillingStrings.messagingIsNotAvailableYet,
      isWarning: true,
    );
  }

  /// Opens the invoice in edit mode (Create Invoice screen). The form is
  /// hydrated from `GET /invoices/by-code/{code}` and PATCHes on save.
  void _openEditInvoice(TransactionItem item) {
    final code = _invoiceCodeOrWarn(item);
    if (code == null) return;
    context.push<bool>(
      CreateInvoiceScreen.routeName,
      extra: CreateInvoiceArgs(
        selectedStudents: [Student(code: '', fullName: item.studentName)],
        initialInvoiceData: InvoiceDraft(invoiceCode: code),
      ),
    );
  }

  /// Guards against rows without a backend invoice code (cannot act on them).
  String? _invoiceCodeOrWarn(TransactionItem item) {
    final code = item.invoiceCode?.trim();
    if (code == null || code.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: BillingStrings.thisInvoiceCannotBeModified,
        isWarning: true,
      );
      return null;
    }
    return code;
  }

  void _confirmCancel(TransactionItem item) {
    final code = _invoiceCodeOrWarn(item);
    if (code == null) return;
    _showInvoiceActionSheet(
      item: item,
      type: 'invoice_cancel',
      action: () => _cubit.cancelInvoice(code),
    );
  }

  void _confirmDelete(TransactionItem item) {
    final code = _invoiceCodeOrWarn(item);
    if (code == null) return;
    _showInvoiceActionSheet(
      item: item,
      type: 'invoice_delete',
      action: () => _cubit.deleteInvoice(code),
    );
  }

  /// Confirms a cancel/delete via the shared bottom sheet; the cubit emits the
  /// success/error message which the BlocListener surfaces.
  void _showInvoiceActionSheet({
    required TransactionItem item,
    required String type,
    required Future<void> Function() action,
  }) {
    final name =
        item.description.trim().isNotEmpty ? item.description : item.studentName;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparentColor,
      builder: (sheetCtx) => DeleteConfirmationBottomSheet(
        name: name,
        type: type,
        onDelete: () async {
          await action();
          if (mounted) Navigator.of(sheetCtx).pop();
        },
        onCancel: () => Navigator.of(sheetCtx).pop(),
      ),
    );
  }

  void _openSendInvoice(TransactionItem item) {
    context.push<bool>(
      SendInvoiceScreen.routeName,
      extra: SendInvoiceArgs(transaction: item),
    );
  }

  void _openReceivePayment(TransactionItem item) {
    context.push<bool>(
      ReceivePaymentIssueRefundScreen.routeName,
      extra: ReceivePaymentRefundArgs(transaction: item),
    );
  }

  void _openIssueRefund(TransactionItem item) {
    context.push<bool>(
      ReceivePaymentIssueRefundScreen.routeName,
      extra: ReceivePaymentRefundArgs(
        transaction: item,
        isRefund: true,
      ),
    );
  }

  void _openTransactionDetails(TransactionItem item) {
    final familyCode = (item.familyCode ?? '').trim();
    context.push(
      TransactionDetailsScreen.routeName,
      extra: TransactionDetailsArgs(
        transaction: item,
        // When we know the family, load the real family ledger.
        ownerType: familyCode.isNotEmpty ? 'FAMILY' : null,
        ownerCode: familyCode.isNotEmpty ? familyCode : null,
        familyName: item.studentName,
      ),
    );
  }

  void _openViewReceipt(TransactionItem item, String viewType) {
    context.push(
      ViewReceiptScreen.routeName,
      extra: ViewReceiptArgs(
        transaction: item,
        viewType: viewType,
      ),
    );
  }

  void _openViewInvoice(TransactionItem item) {
    context.push(
      ViewInvoiceScreen.routeName,
      extra: ViewInvoiceArgs(transaction: item),
    );
  }
}
