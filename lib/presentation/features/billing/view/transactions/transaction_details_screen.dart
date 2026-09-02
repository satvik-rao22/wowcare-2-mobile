import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/billing_events.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/billing/cubit/admin_statements_cubit.dart';
import 'package:wowcare/presentation/features/billing/cubit/transaction_details_cubit.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/amount_invoiced_stat_bar.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/date_range_selector.dart';
import 'package:wowcare/presentation/features/billing/widgets/admin_statements_tab.dart';
import 'package:wowcare/presentation/features/billing/view/create_invoice_screen.dart';
import 'package:wowcare/presentation/features/billing/view/generate_statement_screen.dart';
import 'package:wowcare/presentation/features/billing/model/student_models.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/add_credit_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/billing_transaction_card.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/receive_payment_issue_refund_screen.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/send_invoice_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_action_dialog.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/view_receipt_screen.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/view_invoice_screen.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/shared/common/widgets/gradient_circular_progress.dart';
import 'package:wowcare/core/util/billing_school_time.dart';

class TransactionDetailsScreen extends StatefulWidget {
  /// Optional source transaction (when opened from a transaction card).
  final TransactionItem? transaction;

  /// Family/owner to load the ledger for (when opened from a student/family
  /// card). When [ownerCode] is set, the screen fetches the real family ledger;
  /// otherwise the screen stays empty (no demo data).
  final String? ownerType;
  final String? ownerCode;
  final String? familyName;

  const TransactionDetailsScreen({
    super.key,
    this.transaction,
    this.ownerType,
    this.ownerCode,
    this.familyName,
  });

  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen>
    with TickerProviderStateMixin {
  late final TransactionDetailsCubit _cubit =
      serviceLocator<TransactionDetailsCubit>();
  late final AdminStatementsCubit _statementsCubit =
      serviceLocator<AdminStatementsCubit>();
  late final TabController _tabController =
      TabController(length: 2, vsync: this);
  final ScrollController _scrollController = ScrollController();

  // Read-only proxies onto the cubit state so the build helpers stay unchanged.
  List<TransactionItem> get _siblingTransactions =>
      _cubit.state.siblingTransactions;
  bool get _isLoadingSiblings => _cubit.state.isLoadingSiblings;
  bool get _hasError => _cubit.state.hasError;
  String get _errorMessage => _cubit.state.errorMessage;
  DateTime? get _startDate => _cubit.state.startDate;
  DateTime? get _endDate => _cubit.state.endDate;
  bool get _isLoadingFamily => _cubit.state.isLoadingFamily;
  List<Map<String, dynamic>> get _familyChildren => _cubit.state.familyChildren;
  List<Map<String, dynamic>> get _familyParents => _cubit.state.familyParents;
  String get _familyError => _cubit.state.familyError;
  bool get _isLoadingMore => _cubit.state.isLoadingMore;

  double get _netPaidAmount => _cubit.state.netPaidAmount;
  double get _amountUnpaid => _cubit.state.amountUnpaid;
  double get _amountInProcess => _cubit.state.amountInProcess;
  double get _amountRefund => _cubit.state.amountRefund;
  double get _familyTotalInvoiced => _cubit.state.familyTotalInvoiced;

  String get _familyDisplayName {
    final ledgerName = _cubit.state.familyName.trim();
    if (ledgerName.isNotEmpty) return ledgerName;
    final passedName = widget.familyName?.trim() ?? '';
    if (passedName.isNotEmpty) return passedName;
    String? familyName = _extractFamilyNameFromList(_familyParents);
    familyName ??= _extractFamilyNameFromList(_familyChildren);
    familyName ??= _extractFamilyName(widget.transaction?.studentName);
    return (familyName?.isNotEmpty ?? false) ? familyName! : 'Family';
  }

  String? _extractFamilyNameFromList(List<Map<String, dynamic>> members) {
    if (members.isEmpty) return null;
    final first = members.first['fullName']?.toString();
    return _extractFamilyName(first);
  }

  String? _extractFamilyName(String? fullName) {
    if (fullName == null) return null;
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first;
    return parts.last;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final ownerCode = widget.ownerCode?.trim() ?? '';
    if (ownerCode.isNotEmpty) {
      _cubit.loadFamilyLedger(
        ownerCode: ownerCode,
        ownerType: widget.ownerType ?? 'FAMILY',
      );
    } else {
      _cubit.initialize();
    }
    // Reload this family's ledger after any billing mutation (payment / refund /
    // credit / invoice change) triggered here or in a pushed sub-screen.
    BillingEvents.tick.addListener(_onBillingChanged);
  }

  void _onBillingChanged() {
    if (!mounted) return;
    if ((widget.ownerCode?.trim() ?? '').isEmpty) return;
    _cubit.refresh();
  }

  @override
  void dispose() {
    BillingEvents.tick.removeListener(_onBillingChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    _statementsCubit.close();
    _cubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _isLoadingMore ||
        !_cubit.state.hasMoreData) {
      return;
    }
    final position = _scrollController.position;
    final threshold = position.maxScrollExtent > 200
        ? position.maxScrollExtent - 100
        : position.maxScrollExtent * 0.8;
    if (position.pixels >= threshold) {
      _cubit.loadMore();
    }
  }

  /// This family's students mapped to the [Student] shape that Create Invoice /
  /// Receive Payment consume — so they're pre-selected (no re-selection step).
  List<Student> _familyStudents() {
    return _familyChildren
        .map((c) => Student(
              code: (c['code'] ?? '').toString(),
              fullName: (c['fullName'] ?? '').toString(),
              photoUuid: c['photoUuid'] as String?,
            ))
        .where((s) => s.code.isNotEmpty)
        .toList();
  }

  void _showNewTransactionMenu() {
    final students = _familyStudents();
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students found for this family.')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => TransactionActionDialog(
        onSelectCreateInvoice: () {
          Navigator.of(ctx).maybePop();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CreateInvoiceScreen(selectedStudents: students),
            ),
          );
        },
        onSelectReceivePayment: () {
          Navigator.of(ctx).maybePop();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ReceivePaymentIssueRefundScreen(
                transaction: _buildReceivePaymentTransaction(students),
                studentCode: students.first.code,
                ownerType: widget.ownerType,
                ownerCode: widget.ownerCode,
              ),
            ),
          );
        },
        onSelectAddCredit: () {
          Navigator.of(ctx).maybePop();
          Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => AddCreditScreen(
                ownerType: widget.ownerType,
                ownerCode: widget.ownerCode,
                familyName: _familyDisplayName,
              ),
            ),
          ).then((added) {
            if (added == true) _cubit.refresh();
          });
        },
      ),
    );
  }

  void _openGenerateStatement() {
    Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => GenerateStatementScreen(
          cubit: _statementsCubit,
          subscriberCode: widget.ownerCode ?? '',
          ownerType: widget.ownerType ?? 'FAMILY',
          familyChildren: _familyChildren,
        ),
      ),
    );
  }

  void _showMessageUnavailable() => CoreUtils.showTopSnackBar(
        context: context,
        message: 'Messaging is not available yet.',
        isWarning: true,
      );

  /// Opens the invoice in edit mode (Create Invoice screen). The form is
  /// hydrated from `GET /invoices/by-code/{code}` and PATCHes on save; the
  /// ledger reloads afterwards.
  Future<void> _openEditInvoice(TransactionItem item) async {
    final code = _invoiceCodeOrWarn(item);
    if (code == null) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CreateInvoiceScreen(
          selectedStudents: [Student(code: '', fullName: item.studentName)],
          initialInvoiceData: <String, dynamic>{'invoiceCode': code},
        ),
      ),
    );
    if (result == true && mounted) {
      final ownerCode = widget.ownerCode?.trim() ?? '';
      if (ownerCode.isNotEmpty) {
        _cubit.loadFamilyLedger(
          ownerCode: ownerCode,
          ownerType: widget.ownerType ?? 'FAMILY',
        );
      }
    }
  }

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

  void _confirmCancel(TransactionItem item) {
    final code = _invoiceCodeOrWarn(item);
    if (code == null) return;
    _showInvoiceActionSheet(
      item: item,
      type: 'invoice_cancel',
      action: () => _cubit.cancelInvoice(code),
      successMessage: 'Invoice cancelled',
    );
  }

  void _confirmDelete(TransactionItem item) {
    final code = _invoiceCodeOrWarn(item);
    if (code == null) return;
    _showInvoiceActionSheet(
      item: item,
      type: 'invoice_delete',
      action: () => _cubit.deleteInvoice(code),
      successMessage: 'Invoice deleted',
    );
  }

  /// Confirms a cancel/delete via the shared bottom sheet. The action runs while
  /// the sheet shows its loading state, then the sheet closes and the result is
  /// surfaced as a top snackbar.
  void _showInvoiceActionSheet({
    required TransactionItem item,
    required String type,
    required Future<bool> Function() action,
    required String successMessage,
  }) {
    final name =
        item.description.trim().isNotEmpty ? item.description : item.studentName;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => DeleteConfirmationBottomSheet(
        name: name,
        type: type,
        onDelete: () async {
          final success = await action();
          if (mounted) Navigator.of(sheetCtx).pop();
          if (!mounted) return;
          CoreUtils.showTopSnackBar(
            context: context,
            message: success ? successMessage : _cubit.state.errorMessage,
            isError: !success,
            isSuccess: success,
          );
        },
        onCancel: () => Navigator.of(sheetCtx).pop(),
      ),
    );
  }

  /// [TransactionItem] for a fresh family payment, pre-filled with the family's
  /// outstanding balance so Receive Payment shows the amount to collect.
  TransactionItem _buildReceivePaymentTransaction(List<Student> students) {
    final Student first = students.first;
    final String name = students.length > 1
        ? '${first.fullName} +${students.length - 1}'
        : first.fullName;
    final double outstanding = _cubit.state.openBalance;
    return TransactionItem(
      id: 0,
      transactionType: 'Payment',
      date: billingSchoolNow(),
      amount: outstanding,
      status: '',
      description: 'Receive Payment',
      studentName: name,
      classroom: first.roomName ?? '',
      balance: outstanding,
      studentOpenBalance: outstanding,
    );
  }

  void _openTransactionDetails(TransactionItem item) {
    if (item.id == widget.transaction?.id) {
      return;
    }
    // Replace, don't stack — otherwise tapping multiple siblings builds up
    // a deep navigator stack of TransactionDetailsScreen copies and back
    // walks through every one.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => TransactionDetailsScreen(transaction: item),
      ),
    );
  }

  List<Map<String, dynamic>> get _statementsChildren => _familyChildren
      .map((c) => <String, dynamic>{
            'fullName': (c['fullName'] ?? '').toString(),
            'name': (c['fullName'] ?? '').toString(),
            'room': '',
            'roomName': '',
          })
      .toList();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TransactionDetailsCubit>.value(
      value: _cubit,
      child: BlocBuilder<TransactionDetailsCubit, TransactionDetailsState>(
        builder: (context, state) {
          return GlobalScaffold(
            hasBackButton: true,
            showCustomNavigationBar: true,
            body: Column(
              children: [
                // Family name header + add button
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 8, right: 16, bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$_familyDisplayName Family',
                          style: const TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (_, __) {
                          final isStatementsTab = _tabController.index == 1;
                          return GradientAddButton(
                            onTap: isStatementsTab
                                ? _openGenerateStatement
                                : _showNewTransactionMenu,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Tab bar
                Container(
                  color: AppColors.cardColor,
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicator: const UnderlineTabIndicator(
                      borderSide:
                          BorderSide(color: AppColors.themeColor, width: 2),
                    ),
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorPadding: const EdgeInsets.only(bottom: 8),
                    labelColor: AppColors.themeColor,
                    unselectedLabelColor:
                        AppColors.primaryColor.withValues(alpha: 0.5),
                    labelStyle: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                    ),
                    tabs: const [
                      Tab(text: 'Transactions'),
                      Tab(text: 'Statements'),
                    ],
                  ),
                ),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTransactionsTab(),
                      AdminStatementsTab(
                        cubit: _statementsCubit,
                        ownerCode: widget.ownerCode ?? '',
                        familyChildren: _statementsChildren,
                        customStartDate: _startDate,
                        customEndDate: _endDate,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return CustomRefreshIndicator(
      onRefresh: () async => _cubit.refresh(),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            AccountingDateRangeSelector(
              initialStartDate: _startDate,
              initialEndDate: _endDate,
              onRangeChanged: (start, end) => _cubit.applyDateRange(start, end),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildFamilyInfoBox(),
            ),
            _buildSiblingTransactionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSiblingTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        if (_hasError)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.billingErrorBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.billingErrorBorderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.billingErrorIconColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error loading family transactions: $_errorMessage',
                    style: TextStyle(color: AppColors.billingErrorTextColor, fontSize: 14),
                  ),
                ),
                TextButton(
                  onPressed: () => _cubit.refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        // Always show summary cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Family Transaction Summary',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildFamilyStatBar(),
              const SizedBox(height: 16),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Transaction list section
        if (_hasError)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.billingErrorBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.billingErrorBorderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.billingErrorIconColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error loading family transactions: $_errorMessage',
                    style: TextStyle(color: AppColors.billingErrorTextColor, fontSize: 14),
                  ),
                ),
                TextButton(
                  onPressed: () => _cubit.refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (_isLoadingSiblings)
          // Transaction-card-shaped shimmer (avatar + name/badge + amount/date).
          ...List.generate(
            5,
            (index) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: BillingTransactionShimmer(),
            ),
          )
        else if (_siblingTransactions.isEmpty && !_hasError)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'No family transactions found',
                style: TextStyle(fontSize: 16, color: AppColors.billingTextColor),
              ),
            ),
          )
        else if (_siblingTransactions.isNotEmpty)
          Column(
            children: [
              // Family transaction cards
              Column(
                children: _siblingTransactions.map((transaction) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 6.0),
                    child: BillingTransactionCard(
                      transaction: transaction,
                      // Already on the Billing profile — don't offer to reopen it.
                      showBillingProfile: false,
                      onView: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ViewInvoiceScreen(
                              transaction: transaction,
                            ),
                          ),
                        );
                      },
                      onViewReceipt: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ViewReceiptScreen(
                              transaction: transaction,
                              viewType: 'receipt',
                            ),
                          ),
                        );
                      },
                      onSendInvoice: () => Navigator.of(context).push(
                        MaterialPageRoute<bool>(
                          builder: (_) =>
                              SendInvoiceScreen(transaction: transaction),
                        ),
                      ),
                      onReceivePayment: () => Navigator.of(context).push(
                        MaterialPageRoute<bool>(
                          builder: (_) => ReceivePaymentIssueRefundScreen(
                            transaction: transaction,
                            ownerType: widget.ownerType,
                            ownerCode: widget.ownerCode,
                          ),
                        ),
                      ),
                      onIssueRefund: () => Navigator.of(context).push(
                        MaterialPageRoute<bool>(
                          builder: (_) => ReceivePaymentIssueRefundScreen(
                            transaction: transaction,
                            isRefund: true,
                            ownerType: widget.ownerType,
                            ownerCode: widget.ownerCode,
                          ),
                        ),
                      ),
                      onEditInvoice: () => _openEditInvoice(transaction),
                      onMessage: _showMessageUnavailable,
                      onBillingProfile: () => _openTransactionDetails(transaction),
                      onCancel: () => _confirmCancel(transaction),
                      onDelete: () => _confirmDelete(transaction),
                    ),
                  );
                }).toList(),
              ),
              // Loading more indicator
              if (_isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: GradientCircularProgress(
                      size: 40,
                      strokeWidth: 3,
                      loadingText: 'Loading more...',
                    ),
                  ),
                ),
              // End of list indicator
              // if (!_hasMoreData && _siblingTransactions.isNotEmpty)
              //   Padding(
              //     padding: const EdgeInsets.only(top: 16),
              //     child: Center(
              //       child: Text(
              //         'All ${_siblingTransactions.length} family transactions loaded',
              //         style: TextStyle(
              //           color: AppColors.primaryColor.withOpacity(0.7),
              //           fontSize: 12,
              //         ),
              //       ),
              //     ),
              //   ),
            ],
          ),
      ],
    );
  }

  Widget _buildFamilyStatBar() {
    if (_isLoadingSiblings) {
      Widget bar(double w, double h, {double radius = 4}) => Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radius),
            ),
          );
      // Mirrors AmountInvoicedStatBar: title, the segmented amount bar, and a
      // legend row.
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(140, 14),
              const SizedBox(height: 12),
              bar(double.infinity, 16, radius: 8),
              const SizedBox(height: 12),
              Row(
                children: List.generate(
                  4,
                  (_) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: bar(56, 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final total = _familyTotalInvoiced;
    if (total <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorderColor),
        ),
        child: const Text(
          'No invoiced data available for this family.',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return AmountInvoicedStatBar(
      totalAmount: total,
      netPaidAmount: _netPaidAmount,
      paidAmount: _netPaidAmount,
      inProcessAmount: _amountInProcess,
      outstandingAmount: _amountUnpaid,
      refundedAmount: _amountRefund,
      title: 'Invoiced Amount',
    );
  }

  Widget _buildFamilyInfoBox() {
    if (_isLoadingFamily) {
      Widget bar(double w, double h) => Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          );
      // Mirrors the real family-info box: a row of child chips (avatar + name)
      // and the "Parents: …" line below.
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  2,
                  (_) => Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        bar(64, 12),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              bar(200, 12),
            ],
          ),
        ),
      );
    }

    if (_familyError.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          'Failed to load family: $_familyError',
          style: TextStyle(color: AppColors.billingErrorTextColor, fontSize: 12),
        ),
      );
    }

    if (_familyChildren.isEmpty && _familyParents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_familyChildren.isNotEmpty) ...[
            SizedBox(
              height: 30,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _familyChildren
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _FamilyChip(
                              name: (c['fullName'] ?? '').toString(),
                              photoUuid: c['photoUuid'],
                              backgroundColor: AppColors.warningColor,
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (_familyParents.isNotEmpty) _buildParentsLine(),
        ],
      ),
    );
  }

  Widget _buildParentsLine() {
    final names = _familyParents
        .map((p) => (p['fullName'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toList();
    final text = names.isEmpty ? '-' : names.join(', ');
    return RichText(
      text: TextSpan(
        children: [
          const TextSpan(
            text: 'Parents: ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.billingTextColor,
              fontSize: 14,
              fontFamily: 'Manrope',
            ),
          ),
          TextSpan(
            text: text,
            style: const TextStyle(
              fontWeight: FontWeight.w400,
              color: AppColors.billingTextColor,
              fontSize: 14,
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyChip extends StatelessWidget {
  final String name;
  final dynamic photoUuid;
  final Color backgroundColor;

  const _FamilyChip({
    required this.name,
    this.photoUuid,
    required this.backgroundColor,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r"\s+"));
    final first = parts.isNotEmpty ? parts.first : '';
    final last = parts.length > 1 ? parts.last : '';
    return ((first.isNotEmpty ? first[0] : '') + (last.isNotEmpty ? last[0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: backgroundColor,
          child: Text(
            initials,
            style: const TextStyle(
              color: AppColors.billingCardColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

