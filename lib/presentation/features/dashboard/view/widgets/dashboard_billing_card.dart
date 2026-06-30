import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/cubit/parent_billing_cubit.dart';
import 'package:wowcare/presentation/features/billing/cubit/transactions_cubit.dart';
import 'package:wowcare/presentation/features/billing/view/billing_screen.dart';
import 'package:wowcare/presentation/features/billing/view/parent_billing_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';

// ---------------------------------------------------------------------------
// Shared view-models (plain data the presentation widget renders)
// ---------------------------------------------------------------------------

class _BillingTotal {
  const _BillingTotal(this.label, this.value, {this.emphasize = false});

  final String label;
  final double value;
  final bool emphasize;
}

class _BillingTxn {
  const _BillingTxn({
    required this.type,
    required this.status,
    required this.name,
    required this.amount,
    required this.date,
  });

  final String type;
  final String status;
  final String name;
  final double amount;
  final DateTime? date;
}

// ---------------------------------------------------------------------------
// Admin variant — overview totals + first 5 transactions
// (GET /invoices/overview + GET /invoices/transactions)
// ---------------------------------------------------------------------------

class AdminBillingCard extends StatelessWidget {
  const AdminBillingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return BlocProvider<TransactionsCubit>(
      create: (_) => serviceLocator<TransactionsCubit>()..setDateRange(from, to),
      child: BlocBuilder<TransactionsCubit, TransactionsState>(
        builder: (context, state) {
          final totals = <_BillingTotal>[
            _BillingTotal('Net Paid', state.netPaidAmount, emphasize: true),
            _BillingTotal('Amount Invoiced', state.totalInvoiced),
            _BillingTotal('Paid', state.paidAmount),
            _BillingTotal('Refunded', state.refundedAmount),
            _BillingTotal('In-Process', state.inProcessAmount),
            _BillingTotal('Outstanding', state.outstandingAmount),
          ];

          final txns = state.transactions.take(5).map((r) {
            final i = r.item;
            return _BillingTxn(
              type: i.transactionType,
              status: i.status,
              name: i.studentName,
              amount: i.amount,
              date: i.date,
            );
          }).toList();

          return _BillingCardView(
            isLoading: state.isLoading,
            errorMessage: state.errorMessage,
            totals: totals,
            transactions: txns,
            onRedirect: () => context.push(BillingScreen.routeName),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Parent variant — family-ledger summary + first 5 transactions
// (GET /invoices/family-ledger/by-guardian)
// ---------------------------------------------------------------------------

class ParentBillingDashboardCard extends StatelessWidget {
  const ParentBillingDashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ParentBillingCubit>(
      create: (_) => serviceLocator<ParentBillingCubit>()..load(),
      child: BlocBuilder<ParentBillingCubit, ParentBillingState>(
        builder: (context, state) {
          final totals = <_BillingTotal>[
            _BillingTotal('Net Paid', state.netPaid, emphasize: true),
            _BillingTotal('Open Balance', state.openBalance),
            _BillingTotal('Paid', state.paid),
            _BillingTotal('Refunded', state.refunded),
            _BillingTotal('In-Process', state.inProcess),
            _BillingTotal('Unpaid', state.unpaid),
          ];

          final txns = state.visibleTransactions.take(5).map((t) {
            return _BillingTxn(
              type: t.transactionType,
              status: t.status,
              name: t.studentName,
              amount: t.amount,
              date: t.date,
            );
          }).toList();

          return _BillingCardView(
            isLoading: state.isLoading,
            errorMessage: state.errorMessage,
            totals: totals,
            transactions: txns,
            onRedirect: () => context.push(ParentBillingScreen.routeName),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared presentation widget
// ---------------------------------------------------------------------------

class _BillingCardView extends StatefulWidget {
  const _BillingCardView({
    required this.isLoading,
    required this.errorMessage,
    required this.totals,
    required this.transactions,
    required this.onRedirect,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<_BillingTotal> totals;
  final List<_BillingTxn> transactions;
  final VoidCallback onRedirect;

  @override
  State<_BillingCardView> createState() => _BillingCardViewState();
}

class _BillingCardViewState extends State<_BillingCardView> {
  bool _isMinimized = false;

  static String _money(double v) {
    final negative = v < 0;
    final abs = v.abs().toStringAsFixed(2);
    // Group the integer part with commas (no intl dependency).
    final parts = abs.split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i != 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '${negative ? '-' : ''}\$$buf.${parts[1]}';
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Color _badgeColor(String type) {
    switch (type.trim().toUpperCase()) {
      case 'PAYMENT':
        return AppColors.billingPaymentBadgeColor;
      case 'REFUND':
        return AppColors.billingRefundBadgeColor;
      case 'INVOICE':
        return AppColors.billingInvoiceBadgeColor;
      default:
        return AppColors.billingCardColor;
    }
  }

  Widget _totalTile(_BillingTotal t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.billingCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.billingCardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _money(t.value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.emphasize ? AppColors.themeColor : AppColors.primaryColor,
              fontSize: t.emphasize ? 20 : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            t.label,
            style: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _txnTile(_BillingTxn t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.billingCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.billingCardBorderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _badgeColor(t.type),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    t.type,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.name.trim().isNotEmpty ? t.name : 'Family',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (t.status.trim().isNotEmpty)
                  Text(
                    'Status: ${t.status}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryColor.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _money(t.amount),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (t.date != null) ...[
                const SizedBox(height: 2),
                Text(
                  _formatDate(t.date!),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (widget.isLoading && widget.totals.every((t) => t.value == 0)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.errorMessage != null &&
        widget.errorMessage!.isNotEmpty &&
        widget.transactions.isEmpty &&
        widget.totals.every((t) => t.value == 0)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            widget.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.primaryColor),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Totals grid (Net Paid + all the rest).
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
          ),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: widget.totals.length,
          itemBuilder: (_, i) => _totalTile(widget.totals[i]),
        ),
        const SizedBox(height: 16),
        Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No transactions',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primaryColor.withValues(alpha: 0.6),
                ),
              ),
            ),
          )
        else
          ...widget.transactions.map(_txnTile),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DashboardCardHeader(
              title: 'Billing',
              minimized: _isMinimized,
              onToggle: () => setState(() => _isMinimized = !_isMinimized),
              showRedirect: true,
              onRedirect: widget.onRedirect,
            ),
            if (!_isMinimized) ...[
              const SizedBox(height: 16),
              _body(),
            ],
          ],
        ),
      ),
    );
  }
}
