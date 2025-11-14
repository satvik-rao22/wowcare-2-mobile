import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_diff_card.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/view_receipt_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/view_invoice_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/simmer_loader.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/gradient_circular_progress.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final TransactionItem transaction;

  const TransactionDetailsScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  final ScrollController _scrollController = ScrollController();

  // Dummy data for UI
  List<TransactionItem> _siblingTransactions = [];
  Map<String, dynamic> _siblingSummary = {};
  bool _isLoadingSiblings = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Date range state
  DateTime? _startDate;
  DateTime? _endDate;

  // Family members (children, parents)
  bool _isLoadingFamily = false;
  List<Map<String, dynamic>> _familyChildren = [];
  List<Map<String, dynamic>> _familyParents = [];
  String _familyError = '';

  // Pagination variables
  int _currentPage = 0;
  int _pageSize = 10;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeWithDummyData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeWithDummyData() async {
    // Simulate loading
    setState(() {
      _isLoadingSiblings = true;
      _isLoadingFamily = true;
    });

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Load dummy data
    setState(() {
      _startDate = null;
      _endDate = null;
      _siblingSummary = {
        'netAmountPaid': 1250.0,
        'amountUnpaid': 450.0,
        'amountInProcess': 200.0,
        'amountRefund': 85.0,
        'amountPaid': 1500.0,
      };
      _siblingTransactions = _generateDummyTransactions();
      _familyChildren = [
        {'fullName': 'John Doe', 'photoUuid': null},
        {'fullName': 'Jane Doe', 'photoUuid': null},
      ];
      _familyParents = [
        {'fullName': 'Michael Doe'},
        {'fullName': 'Sarah Doe'},
      ];
      _isLoadingSiblings = false;
      _isLoadingFamily = false;
    });
  }

  List<TransactionItem> _generateDummyTransactions() {
    return [
      TransactionItem(
        id: 2001,
        transactionType: 'Invoice',
        date: DateTime.now().subtract(const Duration(days: 5)),
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
        date: DateTime.now().subtract(const Duration(days: 3)),
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
        date: DateTime.now().subtract(const Duration(days: 2)),
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

  Future<void> _loadSiblingTransactions({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _hasMoreData = true;
        _siblingTransactions.clear();
      });
    }

    setState(() {
      _isLoadingSiblings = true;
      _hasError = false;
    });

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      if (refresh) {
        _siblingTransactions = _generateDummyTransactions();
      } else {
        _siblingTransactions.addAll(_generateDummyTransactions());
      }
      _isLoadingSiblings = false;
      _hasMoreData = false; // No more data for dummy
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMoreData) return;

    final position = _scrollController.position;
    final threshold = position.maxScrollExtent > 200
        ? position.maxScrollExtent - 100
        : position.maxScrollExtent * 0.8;

    if (position.pixels >= threshold) {
      _loadMoreTransactions();
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoadingMore = false;
      _hasMoreData = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: true,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadSiblingTransactions(refresh: true),
            _initializeWithDummyData(),
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
                    const Text(
                      'Transaction Details',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                              setState(() {
                                _startDate = result['startDate'];
                                _endDate = result['endDate'];
                              });
                              await _loadSiblingTransactions(refresh: true);
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
                                    color: Color(0xff573353),
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
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error loading family transactions: $_errorMessage',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                  ),
                ),
                TextButton(
                  onPressed: () => _loadSiblingTransactions(refresh: true),
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
              // Row of two summary cards
              Row(
                children: [
                  Expanded(
                    child: _isLoadingSiblings
                        ? ShimmerLoaderCard(
                            child: Container(
                              height: 80,
                              child: const SizedBox(),
                            ),
                          )
                        : TransactionsSummaryBox(
                            width: double.infinity,
                            amount:
                                ' \$${(_siblingSummary['netAmountPaid'] ?? 0.0).toStringAsFixed(0)}',
                            label: 'Net Amount Paid',
                            valueFontSize: 22,
                            labelFontSize: 15,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _isLoadingSiblings
                        ? ShimmerLoaderCard(
                            child: Container(
                              height: 80,
                              child: const SizedBox(),
                            ),
                          )
                        : TransactionsSummaryBox(
                            width: double.infinity,
                            amount:
                                ' \$${(_siblingSummary['amountUnpaid'] ?? 0.0).toStringAsFixed(0)}',
                            label: 'Amount Unpaid',
                            valueFontSize: 22,
                            labelFontSize: 15,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Row: In Process (left) and Refunded (right)
              Row(
                children: [
                  Expanded(
                    child: _isLoadingSiblings
                        ? ShimmerLoaderCard(
                            child: Container(
                              height: 80,
                              child: const SizedBox(),
                            ),
                          )
                        : TransactionsSummaryBox(
                            width: double.infinity,
                            amount:
                                ' \$${(_siblingSummary['amountInProcess'] ?? 0.0).toStringAsFixed(0)}',
                            label: 'Amount in Process',
                            valueFontSize: 22,
                            labelFontSize: 15,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _isLoadingSiblings
                        ? ShimmerLoaderCard(
                            child: Container(
                              height: 80,
                              child: const SizedBox(),
                            ),
                          )
                        : TransactionsSummaryBox(
                            width: double.infinity,
                            amount:
                                ' \$${(_siblingSummary['amountRefund'] ?? 0.0).toStringAsFixed(0)}',
                            label: 'Amount Refunded',
                            valueFontSize: 22,
                            labelFontSize: 15,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _isLoadingSiblings
                        ? ShimmerLoaderCard(
                            child: Container(
                              height: 80,
                              child: const SizedBox(),
                            ),
                          )
                        : TransactionsSummaryBox(
                            width: double.infinity,
                            amount:
                                ' \$${(_siblingSummary['amountPaid'] ?? 0.0).toStringAsFixed(0)}',
                            label: 'Amount Paid',
                            valueFontSize: 22,
                            labelFontSize: 15,
                          ),
                  ),
                ],
              ),
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
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error loading family transactions: $_errorMessage',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                  ),
                ),
                TextButton(
                  onPressed: () => _loadSiblingTransactions(refresh: true),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: 15,
                        width: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 15,
                        width: 60,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                style: TextStyle(fontSize: 16, color: Color(0xff573353)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TransactionDiffCard(
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
                      onSendInvoice: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Send Invoice tapped (UI only)')),
                        );
                      },
                      onReceivePayment: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Receive Payment tapped (UI only)')),
                        );
                      },
                      onIssueRefund: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Issue Refund tapped (UI only)')),
                        );
                      },
                      onDelete: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Delete tapped (UI only)')),
                        );
                      },
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
              if (!_hasMoreData && _siblingTransactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: Text(
                      'All ${_siblingTransactions.length} family transactions loaded',
                      style: TextStyle(
                        color: AppColors.primaryColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 15,
                  width: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
          style: TextStyle(color: Colors.red.shade700, fontSize: 12),
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
                              backgroundColor: const Color(0xFFFFB74D),
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
              color: Color(0xff573353),
              fontSize: 14,
              fontFamily: 'Manrope',
            ),
          ),
          TextSpan(
            text: text,
            style: const TextStyle(
              fontWeight: FontWeight.w400,
              color: Color(0xff573353),
              fontSize: 14,
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionsSummaryBox extends StatelessWidget {
  final double width;
  final String amount;
  final String label;
  final double? valueFontSize;
  final double? labelFontSize;

  const TransactionsSummaryBox({
    super.key,
    required this.width,
    required this.amount,
    required this.label,
    this.valueFontSize,
    this.labelFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            amount.trim(),
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w700,
              fontSize: valueFontSize ?? 20,
              color: AppColors.themeColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w500,
              fontSize: labelFontSize ?? 13,
              color: AppColors.primaryColor,
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
          radius: 12,
          backgroundColor: backgroundColor,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

