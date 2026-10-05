import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_list_entity.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/presentation/features/billing/view_model/view_invoice_cubit.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_school_header.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';

class ViewInvoiceScreen extends StatelessWidget {
  const ViewInvoiceScreen({super.key, required this.transaction});

  static const String routeName = '/billing/view-invoice';

  final TransactionItem transaction;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ViewInvoiceCubit>(
      create: (_) => serviceLocator<ViewInvoiceCubit>()
        ..load(
          studentCode: transaction.studentCode,
          invoiceCode: transaction.invoiceCode,
        ),
      child: _ViewInvoiceView(transaction: transaction),
    );
  }
}

class _ViewInvoiceView extends StatelessWidget {
  const _ViewInvoiceView({required this.transaction});

  final TransactionItem transaction;

  // Unpadded day (e.g. "Aug 9, 2026") to match the web invoice modal.
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  String _formatDate(DateTime date) => _dateFormat.format(date);

  String? _invoiceNumberLabel(InvoiceListItemEntity? detail) {
    final code = (detail?.code ?? transaction.invoiceCode ?? '').trim();
    return code.isEmpty ? null : code;
  }

  String? _dueDateLabel(InvoiceListItemEntity? detail) {
    final resolved = detail?.dueDate;
    if (resolved != null) return _formatDate(resolved);
    final raw = transaction.endDate;
    if (raw != null && raw.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(raw.trim());
      if (parsed != null) return _formatDate(parsed);
    }
    return null;
  }

  String? _invoicePeriodLabel(InvoiceListItemEntity? detail) {
    final start = detail?.periodStart;
    final end = detail?.periodEnd;
    if (start == null || end == null) return null;
    return '${_formatDate(start)} to ${_formatDate(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ViewInvoiceCubit, ViewInvoiceState>(
      builder: (context, state) {
        final isStaff = context.watch<RoleCubit>().isStaff;
        return StaffFormLayout(
          title: BillingStrings.viewInvoice,
          bottomBar: _buildBottomBar(context, isStaff),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BillingSchoolHeader(),
                const SizedBox(height: 20),
                _buildBilledForRow(state.roomName),
                const SizedBox(height: 16),
                _buildInvoiceMeta(state.invoiceDetail),
                const SizedBox(height: 12),
                _buildItemsTable(state.invoiceDetail),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBilledForRow(String? roomName) {
    final classroom = (roomName ?? transaction.classroom).trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          BillingStrings.billedForColon,
          style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                transaction.studentName,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (classroom.isNotEmpty)
                Text(
                  classroom,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceMeta(InvoiceListItemEntity? detail) {
    // Matches the web invoice modal's field set (Invoice Number / Due Date /
    // Invoice Period). Falls back to the issue date only if none of those
    // resolved (e.g. the invoice-detail fetch failed and the row carried no
    // invoiceCode), so the screen never renders with no date at all.
    final rows = <Widget>[
      if (_invoiceNumberLabel(detail) != null)
        _metaRow(BillingStrings.invoiceNumber, _invoiceNumberLabel(detail)!),
      if (_dueDateLabel(detail) != null)
        _metaRow(BillingStrings.dueDate, _dueDateLabel(detail)!),
      if (_invoicePeriodLabel(detail) != null)
        _metaRow(BillingStrings.invoicePeriod, _invoicePeriodLabel(detail)!),
    ];
    if (rows.isEmpty) {
      rows.add(
        _metaRow(BillingStrings.invoiceDate, _formatDate(transaction.date)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          rows[i],
        ],
      ],
    );
  }

  Widget _metaRow(String label, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label : ',
            style: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(InvoiceListItemEntity? detail) {
    // The transaction summary only ever carries the FIRST item's description
    // flattened into one string — the fetched invoice [detail] (when it has
    // resolved) carries every line item with its own amount, matching the
    // web invoice modal's per-item breakdown instead of one combined row.
    final List<InvoiceListLineItemEntity> lineItems = detail?.items ?? const [];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.billingGreyLight,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  BillingStrings.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Text(
                BillingStrings.amount,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primaryColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          Divider(thickness: 0.5, color: AppColors.billingGreyTransparent),
          if (lineItems.isEmpty)
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    transaction.displayDescription,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '\$${transaction.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else
            for (final item in lineItems)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        item.description.isEmpty ? '-' : item.description,
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '\$${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  BillingStrings.totalAmount,
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '\$${transaction.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDownload(BuildContext context) async {
    final cubit = context.read<ViewInvoiceCubit>();
    final error = await cubit.downloadInvoice(transaction);
    if (!context.mounted) return;
    if (error != null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: error,
        isError: true,
      );
    } else {
      CoreUtils.showTopSnackBar(
        context: context,
        message: BillingStrings.downloaded,
        isSuccess: true,
      );
    }
  }

  Widget _buildBottomBar(BuildContext context, bool isStaff) {
    // Download does the (async) PDF work and gets CustomConfirmButton's
    // built-in spinner; Send Invoice just pops back (instant), so it's the
    // plain cancel-styled slot — swapped from the two buttons' usual
    // primary/secondary roles on purpose, to match which one is actually async.
    return CustomButtonLayout(
      isForm: false,
      confirmButtonLabel: BillingStrings.download,
      onPressedConfirm: () => _onDownload(context),
      showCancelButton: isStaff,
      cancelButtonLabel: BillingStrings.sendInvoice,
      onPressedCancel: () => Navigator.of(context).pop(),
    );
  }
}
