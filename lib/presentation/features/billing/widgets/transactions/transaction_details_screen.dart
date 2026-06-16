import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/billing/cubit/transaction_details_cubit.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/amount_invoiced_stat_bar.dart';
import 'package:wowcare/presentation/features/billing/widgets/create_invoice_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/models/student_models.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/billing_transaction_card.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/receive_payment_issue_refund_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/send_invoice_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_action_dialog.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/view_receipt_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/view_invoice_screen.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/simmer_loader.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/gradient_circular_progress.dart';

class TransactionDetailsScreen extends StatefulWidget {
  /// Optional source transaction (when opened from a transaction card).
  final TransactionItem? transaction;

  /// Family/owner to load the ledger for (when opened from a student/family
  /// card). When [ownerCode] is set, the screen fetches the real family ledger;
  /// otherwise it falls back to demo data.
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

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  late final TransactionDetailsCubit _cubit =
      serviceLocator<TransactionDetailsCubit>();
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
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
      ),
    );
  }

  void _showMessageUnavailable() => CoreUtils.showTopSnackBar(
        context: context,
        message: 'Messaging is not available yet.',
        isWarning: true,
      );

  /// Opens the invoice in edit mode (Create Invoice screen, PATCH on save),
  /// pre-filled from the available row data, then reloads the ledger on save.
  Future<void> _openEditInvoice(TransactionItem item) async {
    final code = _invoiceCodeOrWarn(item);
    if (code == null) return;
    final dueDate = (item.endDate != null && item.endDate!.trim().isNotEmpty)
        ? DateTime.tryParse(item.endDate!.trim())
        : null;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CreateInvoiceScreen(
          selectedStudents: [Student(code: '', fullName: item.studentName)],
          initialInvoiceData: <String, dynamic>{
            'invoiceCode': code,
            'invoiceItems': [
              {
                'description': item.description,
                'amount': item.amount.toStringAsFixed(2),
              },
            ],
            'invoiceDate': item.date,
            'dueDate': dueDate,
            'internalNote': item.note ?? '',
          },
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

  Future<void> _confirmCancel(TransactionItem item) async {
    final code = _invoiceCodeOrWarn(item);
    if (code == null) return;
    final ok = await _confirmAction(
      title: 'Cancel invoice?',
      message: 'This will cancel the invoice. This action cannot be undone.',
      confirmLabel: 'Cancel invoice',
    );
    if (!ok) return;
    final success = await _cubit.cancelInvoice(code);
    if (!mounted) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: success ? 'Invoice cancelled' : _cubit.state.errorMessage,
      isError: !success,
      isSuccess: success,
    );
  }

  Future<void> _confirmDelete(TransactionItem item) async {
    final code = _invoiceCodeOrWarn(item);
    if (code == null) return;
    final ok = await _confirmAction(
      title: 'Delete invoice?',
      message: 'This will permanently delete the invoice.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!ok) return;
    final success = await _cubit.deleteInvoice(code);
    if (!mounted) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: success ? 'Invoice deleted' : _cubit.state.errorMessage,
      isError: !success,
      isSuccess: success,
    );
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

  /// Minimal zero-balance [TransactionItem] for a fresh family payment.
  TransactionItem _buildReceivePaymentTransaction(List<Student> students) {
    final Student first = students.first;
    final String name = students.length > 1
        ? '${first.fullName} +${students.length - 1}'
        : first.fullName;
    return TransactionItem(
      id: 0,
      transactionType: 'Payment',
      date: DateTime.now(),
      amount: 0,
      status: '',
      description: 'Receive Payment',
      studentName: name,
      classroom: first.roomName ?? '',
      balance: 0,
      studentOpenBalance: 0,
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TransactionDetailsCubit>.value(
      value: _cubit,
      child: BlocBuilder<TransactionDetailsCubit, TransactionDetailsState>(
        builder: (context, state) {
    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: true,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _cubit.loadSiblingTransactions(refresh: true),
            _cubit.initialize(),
          ]);
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page title
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 8, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${_familyDisplayName} Family Transactions',
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GradientAddButton(onTap: _showNewTransactionMenu),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Date range selector
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: AppColors.primaryColor.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Date Range',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primaryColor.withOpacity(0.5),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () async {
                          try {
                            final start = _startDate ??
                                DateTime.now().subtract(const Duration(days: 7));
                            final end = _endDate ?? DateTime.now();
                            final result = await showDialog<Map<String, dynamic>>(
                              context: context,
                              builder: (context) => CalendarDialog(
                                isRangePicker: true,
                                isTimePicker: false,
                                initialDate: start,
                                initialEndDate: end.isAfter(start) ? end : null,
                              ),
                            );
                            if (result != null) {
                              await _cubit.applyDateRange(
                                result['startDate'] as DateTime?,
                                result['endDate'] as DateTime?,
                              );
                            }
                          } catch (_) {}
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0x1AB1AFE9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  (_startDate != null && _endDate != null)
                                      ? '${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}'
                                      : 'Select Date Range',
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.billingTextColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFF573353),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Compact family info box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildFamilyInfoBox(),
              ),
              // Family transactions section
              _buildSiblingTransactionsSection(),
            ],
          ),
        ),
      ),
    );
        },
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
                  onPressed: () => _cubit.loadSiblingTransactions(refresh: true),
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
                  onPressed: () => _cubit.loadSiblingTransactions(refresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (_isLoadingSiblings)
          // Family transaction shimmer cards
          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: ShimmerLoaderCard(
                child: Container(
                  height: 80,
                  child: Column(
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.billingCardColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: 15,
                        width: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.billingCardColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 15,
                        width: 60,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.billingCardColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
      return ShimmerLoaderCard(
        child: Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.billingCardColor,
            borderRadius: BorderRadius.circular(12),
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ShimmerLoaderCard(
          child: Container(
            height: 60,
            child: Column(
              children: [
                Container(
                  height: 20,
                  width: double.infinity,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.billingCardColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 15,
                  width: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.billingCardColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
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

