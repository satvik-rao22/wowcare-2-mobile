import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/cubit/transaction_card_cubit.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_student_vertical_popup.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

class BillingTransactionCard extends StatefulWidget {
  const BillingTransactionCard({
    super.key,
    required this.transaction,
    this.showSelection = true,
    this.isSelected = false,
    this.onSelected,
    this.onToggleSelection,
    this.onMessage,
    this.onBillingProfile,
    this.onEditInvoice,
    this.onMore,
    this.onSendInvoice,
    this.onReceivePayment,
    this.onView,
    this.onViewReceipt,
    this.onIssueRefund,
    this.onCancel,
    this.onDelete,
    this.onLongPress,
  });

  final TransactionItem transaction;
  final bool showSelection;
  final bool isSelected;
  final ValueChanged<bool?>? onSelected;
  final ValueChanged<bool>? onToggleSelection;
  final VoidCallback? onMessage;
  final VoidCallback? onBillingProfile;
  final VoidCallback? onEditInvoice;
  final VoidCallback? onMore;
  final VoidCallback? onSendInvoice;
  final VoidCallback? onReceivePayment;
  final VoidCallback? onView;
  final VoidCallback? onViewReceipt;
  final VoidCallback? onIssueRefund;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;

  @override
  State<BillingTransactionCard> createState() => _BillingTransactionCardState();
}

class _BillingTransactionCardState extends State<BillingTransactionCard> {
  late final TransactionCardCubit _cubit = TransactionCardCubit(
    initialSelected: widget.isSelected,
  );
  bool get _isExpanded => _cubit.state.isExpanded;
  bool get _localSelected => _cubit.state.localSelected;

  bool get _isSelectionControlled => widget.onSelected != null;

  bool get _checkboxValue =>
      _isSelectionControlled ? widget.isSelected : _localSelected;

  @override
  void didUpdateWidget(covariant BillingTransactionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSelectionControlled && widget.isSelected != oldWidget.isSelected) {
      _cubit.setSelected(widget.isSelected);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _toggleExpanded() => _cubit.toggleExpanded();

  BillingPopupType? _popupTypeFor(String type) {
    switch (type) {
      case 'invoice':
        return BillingPopupType.invoice;
      case 'payment':
        return BillingPopupType.payment;
      case 'refund':
        return BillingPopupType.refund;
      default:
        return null;
    }
  }

  /// Picks the invoice action set from the invoice status.
  BillingInvoiceMenuVariant _invoiceVariant() {
    final String s = widget.transaction.status.toUpperCase();
    if (s.contains('CANCEL')) return BillingInvoiceMenuVariant.cancelled;
    if (s == 'PAID' || s == 'COMPLETED') return BillingInvoiceMenuVariant.paid;
    if (s.contains('DRAFT')) return BillingInvoiceMenuVariant.draft;
    return BillingInvoiceMenuVariant.sent;
  }

  void _showActionsMenu(BuildContext context, BillingPopupType popupType) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.billingTransparentColor,
      builder: (BuildContext dialogContext) {
        bool showMoreOptions = false;
        final BillingInvoiceMenuVariant? invoiceVariant =
            popupType == BillingPopupType.invoice ? _invoiceVariant() : null;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showMoreOptions)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: BillingMoreOptionsPopup(
                          popupType: popupType,
                          invoiceVariant: invoiceVariant,
                          transaction: widget.transaction,
                          onMessageTap: _dialogCallback(
                            dialogContext,
                            widget.onMessage,
                          ),
                          onBillingProfileTap: _dialogCallback(
                            dialogContext,
                            widget.onBillingProfile,
                          ),
                          onCancelTap: _dialogCallback(
                            dialogContext,
                            widget.onCancel,
                          ),
                          onDeleteTap: _dialogCallback(
                            dialogContext,
                            widget.onDelete,
                          ),
                        ),
                      ),
                    BillingStudentVerticalPopUp(
                      popupType: popupType,
                      invoiceVariant: invoiceVariant,
                      transaction: widget.transaction,
                      onViewTap: _dialogCallback(
                        dialogContext,
                        _viewActionFor(popupType),
                      ),
                      onEditTap: _dialogCallback(
                        dialogContext,
                        widget.onEditInvoice,
                      ),
                      onResendTap: _dialogCallback(
                        dialogContext,
                        widget.onSendInvoice,
                      ),
                      onReceivePaymentTap: _dialogCallback(
                        dialogContext,
                        widget.onReceivePayment,
                      ),
                      onIssueRefundTap: _dialogCallback(
                        dialogContext,
                        widget.onIssueRefund,
                      ),
                      onCancelTap: _dialogCallback(
                        dialogContext,
                        widget.onCancel,
                      ),
                      onDeleteTap: _dialogCallback(
                        dialogContext,
                        widget.onDelete,
                      ),
                      onBillingProfileTap: _dialogCallback(
                        dialogContext,
                        widget.onBillingProfile,
                      ),
                      onMoreTap: () {
                        widget.onMore?.call();
                        setDialogState(() {
                          showMoreOptions = !showMoreOptions;
                        });
                      },
                      onClose: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) => _clearSelection());
  }

  VoidCallback? _dialogCallback(
    BuildContext dialogContext,
    VoidCallback? callback,
  ) {
    if (callback == null) {
      return null;
    }
    return () {
      Navigator.of(dialogContext).pop();
      callback();
    };
  }

  VoidCallback? _viewActionFor(BillingPopupType popupType) {
    if (popupType == BillingPopupType.payment ||
        popupType == BillingPopupType.refund) {
      return widget.onViewReceipt ?? widget.onView;
    }
    return widget.onView;
  }

  void _handleSelectionChanged(BuildContext context, bool? value, String type) {
    if (!_isSelectionControlled) {
      _cubit.setSelected(value ?? false);
    }
    widget.onSelected?.call(value);
    widget.onToggleSelection?.call(value ?? false);

    if (value == true) {
      final BillingPopupType? popupType = _popupTypeFor(type);
      if (popupType != null) {
        _showActionsMenu(context, popupType);
      }
    }
  }

  void _clearSelection() {
    if (!_isSelectionControlled) {
      _cubit.setSelected(false);
    }
    widget.onSelected?.call(false);
    widget.onToggleSelection?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TransactionCardCubit>.value(
      value: _cubit,
      child: BlocBuilder<TransactionCardCubit, TransactionCardState>(
        builder: (context, state) {
          final String type = widget.transaction.transactionType.toLowerCase();
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: AppColors.billingTransparentColor,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _toggleExpanded,
                onLongPress: widget.onLongPress,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: 50, child: _buildHeader(type)),
                      const SizedBox(height: 4),
                      if (_isExpanded) ..._buildExpandedContent(type),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String type) {
    final String dateLabel = _dateLabel(widget.transaction, type);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (widget.showSelection && !_isExpanded) ...<Widget>[
          Builder(
            builder: (BuildContext checkboxContext) => CustomCheckbox(
              value: _checkboxValue,
              onChanged: (bool? value) =>
                  _handleSelectionChanged(checkboxContext, value, type),
              scale: 1.2,
              borderColor: null,
              label: null,
            ),
          ),
          const SizedBox(width: 8),
        ],
        DocumentImageWidget(
          fileUuid: widget.transaction.studentPhotoUuid ?? '',
          name: widget.transaction.studentName,
          size: 50,
          shape: BoxShape.circle,
          fit: BoxFit.cover,
          fontSize: 14,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.transaction.studentName,
                style: AppTextStyles.title.copyWith(
                  fontSize: 14,
                  color: AppColors.billingTextColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 3),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _badgeColor(type, widget.transaction.status),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        _badgeLabel(type),
                        style: AppTextStyles.label.copyWith(
                          fontSize: 13,
                          color: AppColors.billingTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          '(${_formatStatus(widget.transaction.status)})',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.billingTextColor.withValues(
                              alpha: 0.7,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              _formatCurrency(widget.transaction.amount),
              style: AppTextStyles.title.copyWith(
                fontSize: 14,
                color: AppColors.billingTextColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              dateLabel,
              style: AppTextStyles.small.copyWith(
                fontSize: 13,
                color: AppColors.billingTextColor.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildExpandedContent(String type) {
    final List<Widget> content = <Widget>[
      const Divider(height: 1, thickness: 1, color: Color(0xFFE9ECEF)),
      const SizedBox(height: 8),
      _studentInfoRow(),
      const SizedBox(height: 8),
    ];

    if (type == 'invoice') {
      content
        ..add(_infoRow('Description', widget.transaction.displayDescription))
        ..add(const SizedBox(height: 10))
        ..add(_primaryButton('View Invoice', widget.onView));
    } else if (type == 'payment') {
      if (widget.transaction.paymentMode != null &&
          widget.transaction.paymentMode!.isNotEmpty) {
        content
          ..add(_infoRow('Payment Method', widget.transaction.paymentMode!))
          ..add(const SizedBox(height: 10));
      }
      content
        ..add(_infoRow('Description', widget.transaction.displayDescription))
        ..add(const SizedBox(height: 10))
        ..add(_primaryButton('View Receipt', widget.onViewReceipt));
    } else if (type == 'refund') {
      if (widget.transaction.paymentMode != null &&
          widget.transaction.paymentMode!.isNotEmpty) {
        content
          ..add(_infoRow('Payment Method', widget.transaction.paymentMode!))
          ..add(const SizedBox(height: 10));
      }
      content
        ..add(_infoRow('Description', widget.transaction.displayDescription))
        ..add(const SizedBox(height: 10))
        ..add(_primaryButton('View Receipt', widget.onViewReceipt));
    } else {
      content.add(_primaryButton('View', widget.onView));
    }
    return content;
  }

  Widget _studentInfoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Student Name',
          style: AppTextStyles.small.copyWith(
            fontSize: 13,
            color: AppColors.billingTextColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                widget.transaction.studentName,
                textAlign: TextAlign.end,
                style: AppTextStyles.value.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.billingTextColor,
                ),
              ),
              if (widget.transaction.classroom.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  widget.transaction.classroom,
                  style: AppTextStyles.small.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.billingTextColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _badgeLabel(String type) {
    switch (type) {
      case 'invoice':
        return 'Invoice';
      case 'payment':
        return 'Payment';
      case 'refund':
        return 'Refund';
      default:
        return widget.transaction.transactionType;
    }
  }

  Color _badgeColor(String type, String status) {
    // Check status first for special colors
    final String statusLower = status.toLowerCase();
    if (statusLower.contains('in progress') ||
        statusLower.contains('pending')) {
      return AppColors.billingStatusInProgressColor;
    }
    if (statusLower.contains('cancelled') || statusLower.contains('canceled')) {
      return AppColors.billingStatusCancelledColor;
    }

    // Fall back to type-based colors
    switch (type) {
      case 'invoice':
        return AppColors.billingInvoiceBadgeColor;
      case 'payment':
        return AppColors.billingPaymentBadgeColor;
      case 'refund':
        return AppColors.billingRefundBadgeColor;
      default:
        return AppColors.billingDefaultBadgeColor;
    }
  }

  Widget _infoRow(String label, String value, {String? subtitle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.small.copyWith(
            fontSize: 13,
            color: AppColors.billingTextColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                value,
                textAlign: TextAlign.end,
                style: AppTextStyles.label.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.billingTextColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.small.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.billingTextColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: AppColors.buildPrimaryGradient(),
            ),
            child: TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                label,
                style: AppTextStyles.button(
                  color: AppColors.billingButtonTextColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _dateLabel(TransactionItem tx, String type) {
    final DateFormat formatter = DateFormat('MMM dd, yyyy');
    if (type == 'invoice') {
      final DateTime? dueDate = tx.endDate != null
          ? DateTime.tryParse(tx.endDate!)
          : null;
      return 'Due Date: ${formatter.format(dueDate ?? tx.date)}';
    }

    if (type == 'refund') {
      return 'Refunded On: ${formatter.format(tx.date)}';
    }

    return 'Paid On: ${formatter.format(tx.date)}';
  }

  String _formatCurrency(double value) {
    final NumberFormat formatter = NumberFormat.currency(symbol: '\$');
    return formatter.format(value);
  }

  String _formatStatus(String status) {
    // Format status for display in badge
    if (status.isEmpty) return 'Pending';

    // Common status mappings
    switch (status.toLowerCase()) {
      case 'sent':
      case 'invoice sent':
        return 'Sent';
      case 'pending':
      case 'in progress':
        return 'In Progress';
      case 'paid':
      case 'completed':
        return 'Paid';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      default:
        // Capitalize first letter of each word
        return status
            .split(' ')
            .map((word) {
              if (word.isEmpty) return word;
              return word[0].toUpperCase() + word.substring(1).toLowerCase();
            })
            .join(' ');
    }
  }
}
