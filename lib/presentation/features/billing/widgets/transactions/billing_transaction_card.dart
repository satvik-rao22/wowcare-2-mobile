import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_student_vertical_popup.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';

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
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;

  @override
  State<BillingTransactionCard> createState() => _BillingTransactionCardState();
}

class _BillingTransactionCardState extends State<BillingTransactionCard> {
  bool _isExpanded = false;
  late bool _localSelected;

  bool get _isSelectionControlled => widget.onSelected != null;

  bool get _checkboxValue => _isSelectionControlled ? widget.isSelected : _localSelected;

  @override
  void initState() {
    super.initState();
    _localSelected = widget.isSelected;
  }

  @override
  void didUpdateWidget(covariant BillingTransactionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSelectionControlled && widget.isSelected != oldWidget.isSelected) {
      _localSelected = widget.isSelected;
    }
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  BillingPopupType? _popupTypeFor(String type) {
    switch (type) {
      case 'invoice':
        return BillingPopupType.invoice;
      case 'payment':
        return BillingPopupType.payment;
      default:
        return null;
    }
  }

  void _showActionsMenu(BuildContext context, BillingPopupType popupType) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        bool showMoreOptions = false;
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
                          onMessageTap: _dialogCallback(dialogContext, widget.onMessage),
                          onBillingProfileTap: _dialogCallback(dialogContext, widget.onBillingProfile),
                          onCancelTap: popupType == BillingPopupType.invoice
                              ? _dialogCallback(dialogContext, widget.onDelete ?? widget.onLongPress)
                              : null,
                        ),
                      ),
                    BillingStudentVerticalPopUp(
                      popupType: popupType,
                      onViewTap: _dialogCallback(dialogContext, _viewActionFor(popupType)),
                      onEditTap: _dialogCallback(dialogContext, widget.onEditInvoice),
                      onResendTap: _dialogCallback(dialogContext, widget.onSendInvoice),
                      onReceivePaymentTap: _dialogCallback(dialogContext, widget.onReceivePayment),
                      onIssueRefundTap: _dialogCallback(dialogContext, widget.onIssueRefund),
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

  VoidCallback? _dialogCallback(BuildContext dialogContext, VoidCallback? callback) {
    if (callback == null) {
      return null;
    }
    return () {
      Navigator.of(dialogContext).pop();
      callback();
    };
  }

  VoidCallback? _viewActionFor(BillingPopupType popupType) {
    if (popupType == BillingPopupType.payment) {
      return widget.onViewReceipt ?? widget.onView;
    }
    return widget.onView;
  }


  void _handleSelectionChanged(BuildContext context, bool? value, String type) {
    if (!_isSelectionControlled) {
      setState(() {
        _localSelected = value ?? false;
      });
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
      setState(() {
        _localSelected = false;
      });
    }
    widget.onSelected?.call(false);
    widget.onToggleSelection?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    final String type = widget.transaction.transactionType.toLowerCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.2)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _toggleExpanded,
          onLongPress: widget.onLongPress,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  height: 54,
                  child: _buildHeader(type),
                ),
                const SizedBox(height: 4),
                if (_isExpanded) ..._buildExpandedContent(type),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildHeader(String type) {
    final String dateLabel = _dateLabel(widget.transaction, type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (widget.showSelection) ...<Widget>[
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _badgeColor(type),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _badgeLabel(type),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  color: Color(0xff573353),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            Text(
              _formatCurrency(widget.transaction.amount),
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xff573353),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            Text(
              'Status: ${widget.transaction.status}',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                color: Color(0xff573353),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              dateLabel,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                color: Color(0xff573353),
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildExpandedContent(String type) {
    final List<Widget> content = <Widget>[
      Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),
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
      if (widget.transaction.paymentMode != null && widget.transaction.paymentMode!.isNotEmpty) {
        content
          ..add(_infoRow('Payment Method', widget.transaction.paymentMode!))
          ..add(const SizedBox(height: 10));
      }
      content
        ..add(_infoRow('Description', widget.transaction.displayDescription))
        ..add(const SizedBox(height: 10))
        ..add(_primaryButton('View Receipt', widget.onViewReceipt));
    } else if (type == 'refund') {
      if (widget.transaction.paymentMode != null && widget.transaction.paymentMode!.isNotEmpty) {
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
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xff573353),
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
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff573353),
                ),
              ),
              if (widget.transaction.classroom.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  widget.transaction.classroom,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff573353),
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

  Color _badgeColor(String type) {
    switch (type) {
      case 'invoice':
        return const Color.fromRGBO(203, 246, 255, 0.4);
      case 'payment':
        return const Color.fromRGBO(227, 255, 203, 0.4);
      case 'refund':
        return const Color.fromRGBO(229, 231, 235, 0.4);
      default:
        return const Color(0xFFE4E7F5);
    }
  }

  Widget _infoRow(String label, String value, {String? subtitle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xff573353),
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
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff573353),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff573353),
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
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
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
      final DateTime? dueDate =
          tx.endDate != null ? DateTime.tryParse(tx.endDate!) : null;
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
}