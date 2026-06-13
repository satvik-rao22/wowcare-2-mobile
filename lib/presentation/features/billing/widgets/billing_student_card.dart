import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/cubit/bool_toggle_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_student_vertical_popup.dart';

class BillingStudentCard extends StatefulWidget {
  const BillingStudentCard({
    Key? key,
    required this.name,
    required this.classroom,
    this.fileUuid,
    required this.amount,
    required this.paidOn,
    required this.paymentMethod,
    required this.paymentNote,
    required this.lastPaymentStatus,
    required this.lastInvoiceAmount,
    required this.lastInvoiceSent,
    required this.lastInvoiceDue,
    required this.openBalance,
    this.onLongPress,
    this.showSelection = true,
    this.isSelected = false,
    this.onSelected,
    this.onMessage,
    this.onBillingProfile,
    this.onToggleSelection,
  }) : super(key: key);

  final String name;
  final String classroom;
  final String? fileUuid;
  final double amount;
  final String paidOn;
  final String paymentMethod;
  final String paymentNote;
  final String lastPaymentStatus;
  final double lastInvoiceAmount;
  final String lastInvoiceSent;
  final String lastInvoiceDue;
  final double openBalance;
  final VoidCallback? onLongPress;
  final bool showSelection;
  final bool isSelected;
  final ValueChanged<bool?>? onSelected;
  final VoidCallback? onMessage;
  final VoidCallback? onBillingProfile;
  final ValueChanged<bool>? onToggleSelection;

  @override
  State<BillingStudentCard> createState() => _BillingStudentCardState();
}

class _BillingStudentCardState extends State<BillingStudentCard> {
  late final BoolToggleCubit _cubit = BoolToggleCubit(initial: widget.isSelected);
  bool get _localSelected => _cubit.state;

  bool isExpanded = false;

  bool get _isSelectionControlled => widget.onSelected != null;

  bool get _checkboxValue => _isSelectionControlled ? widget.isSelected : _localSelected;

  @override
  void didUpdateWidget(covariant BillingStudentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSelectionControlled && widget.isSelected != oldWidget.isSelected) {
      _cubit.set(widget.isSelected);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _handleSelectionChanged(BuildContext context, bool? value) {
    if (!_isSelectionControlled) {
      _cubit.set(value ?? false);
    }
    widget.onSelected?.call(value);
    widget.onToggleSelection?.call(_checkboxValue);
    _showActionsMenu(context);
  }

  void _clearSelection() {
    if (!_isSelectionControlled) {
      _cubit.set(false);
    }
    widget.onSelected?.call(false);
    widget.onToggleSelection?.call(false);
  }

  void _showActionsMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.billingTransparentColor,
      builder: (BuildContext dialogContext) {
        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: BillingStudentVerticalPopUp(
              onMessageTap: () {
                Navigator.of(dialogContext).pop();
                widget.onMessage?.call();
              },
              onBillingProfileTap: () {
                Navigator.of(dialogContext).pop();
                widget.onBillingProfile?.call();
              },
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
    ).then((_) => _clearSelection());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BoolToggleCubit>.value(
      value: _cubit,
      child: BlocBuilder<BoolToggleCubit, bool>(
        builder: (context, _) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isTablet = screenWidth > 600;

          Color statusColor;
          switch (widget.lastPaymentStatus) {
            case 'Success':
              statusColor = AppColors.successColor;
              break;
            case 'Pending':
              statusColor = Colors.orange;
              break;
            case 'Failed':
              statusColor = AppColors.errorColor;
              break;
            default:
              statusColor = AppColors.billingTextColor;
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return IntrinsicHeight(
                child: Container(
                  width: constraints.maxWidth,
                  height: isExpanded ? null : 64.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.cardBorderColor,
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          isExpanded = !isExpanded;
                        });
                      },
                      onLongPress: widget.onLongPress,
                      child: Column(
                        children: [
                          Container(
                            height: 60,
                            padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 24 : 16),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (!isExpanded && widget.showSelection) ...[
                                  Builder(
                                    builder: (context) => CustomCheckbox(
                                      value: _checkboxValue,
                                      onChanged: (value) =>
                                          _handleSelectionChanged(
                                              context, value),
                                      scale: 1.2,
                                      borderColor: null,
                                      label: null,
                                    ),
                                  ),
                                  SizedBox(width: isTablet ? 16 : 9),
                                ],
                                DocumentImageWidget(
                                  fileUuid: widget.fileUuid ?? '',
                                  name: widget.name,
                                  size: 50,
                                  shape: BoxShape.circle,
                                  fit: BoxFit.cover,
                                  fontSize: 14,
                                  statusColor: statusColor,
                                ),
                                SizedBox(width: isTablet ? 16 : 9),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          widget.name,
                                          style: TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: isTablet ? 16 : 14,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xff573353),
                                            height: 19 / 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          widget.classroom,
                                          style: TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: isTablet ? 16 : 14,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xff573353),
                                            height: 19 / 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isExpanded) ...[
                            const Divider(
                              height: 1,
                              thickness: 1,
                              indent: 16,
                              endIndent: 16,
                              color: Color(0xFFE9ECEF),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildDetailRow(
                                    label: 'Payment Method',
                                    value: widget.paymentMethod,
                                    note: widget.paymentNote,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildDetailRow(
                                    label: 'Last Payment Status',
                                    value: widget.lastPaymentStatus,
                                    valueColor: statusColor,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildDetailRow(
                                    label: 'Last Invoice',
                                    value:
                                        '\$${widget.lastInvoiceAmount.toStringAsFixed(0)}',
                                    note:
                                        'SENT: ${widget.lastInvoiceSent}   DUE: ${widget.lastInvoiceDue}',
                                  ),
                                  const SizedBox(height: 10),
                                  _buildDetailRow(
                                    label: 'Open Balance',
                                    value:
                                        '\$${widget.openBalance.toStringAsFixed(0)}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    String? note,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xff573353),
            height: 16 / 13,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? const Color(0xff573353),
                  height: 19 / 14,
                ),
                textAlign: TextAlign.right,
              ),
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  note,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff573353),
                    height: 14 / 10,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}