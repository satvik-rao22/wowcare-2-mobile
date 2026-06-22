import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/billing/cubit/receive_payment_refund_cubit.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class ReceivePaymentIssueRefundScreen extends StatefulWidget {
  const ReceivePaymentIssueRefundScreen({
    super.key,
    required this.transaction,
    this.isRefund = false,
    this.studentCode,
    this.ownerType,
    this.ownerCode,
  });

  final TransactionItem transaction;
  final bool isRefund;

  /// Identifiers sent to the payment/refund API (resolved from the selected
  /// student / family when available).
  final String? studentCode;
  final String? ownerType;
  final String? ownerCode;

  @override
  State<ReceivePaymentIssueRefundScreen> createState() =>
      _ReceivePaymentIssueRefundScreenState();
}

class _ReceivePaymentIssueRefundScreenState
    extends State<ReceivePaymentIssueRefundScreen> {
  late final ReceivePaymentRefundCubit _cubit =
      serviceLocator<ReceivePaymentRefundCubit>();
  late final TextEditingController _amountController;
  late final TextEditingController _internalNoteController;
  late final TextEditingController _staffNoteController;
  late final TextEditingController _chequeNumberController;

  /// Per-sibling Custom Amount inputs, keyed by student code.
  final Map<String, TextEditingController> _studentControllers = {};

  double? _amountUnpaid;

  /// Receive method: false = pay the current outstanding balance, true = a
  /// custom amount the user types.
  bool _useCustomAmount = false;

  final List<String> _paymentTypeOptions = <String>[
    'Cash',
    'Cheque',
    'Online',
    'Others',
  ];

  // Read-only proxies onto the cubit state.
  bool get _isSubmitting => _cubit.state.isSubmitting;
  bool get _amountError => _cubit.state.amountError;
  bool get _sendEmailNotification => _cubit.state.sendEmailNotification;
  String? get _selectedPaymentType => _cubit.state.selectedPaymentType;

  @override
  void initState() {
    super.initState();
    // Custom-amount entry starts empty; the "Current Outstanding" option uses
    // the account balance directly.
    _amountController = TextEditingController();
    _internalNoteController = TextEditingController();
    _staffNoteController = TextEditingController();
    _chequeNumberController = TextEditingController();

    _amountUnpaid = widget.transaction.balance;

    // Payments support per-sibling amounts; load the family's students (with
    // their outstanding) so the Custom Amount section can list each one.
    if (!widget.isRefund) {
      _cubit.loadPayableStudents(
        ownerType: widget.ownerType,
        ownerCode: widget.ownerCode,
        fallbackName: widget.transaction.studentName,
        fallbackStudentCode: widget.studentCode,
        fallbackOutstanding: widget.transaction.balance ?? 0,
      );
    }
  }

  @override
  void dispose() {
    _cubit.close();
    _amountController.dispose();
    _internalNoteController.dispose();
    _staffNoteController.dispose();
    _chequeNumberController.dispose();
    for (final TextEditingController c in _studentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// A persistent controller for a sibling's Custom Amount input.
  TextEditingController _controllerFor(String code) {
    return _studentControllers.putIfAbsent(code, () => TextEditingController());
  }

  List<String> _getFilteredPaymentOptions() {
    if (!widget.isRefund) {
      return _paymentTypeOptions.where((String t) => t != 'Online').toList();
    }
    return _paymentTypeOptions;
  }

  double get _outstandingValue => _amountUnpaid ?? 0.0;

  String get _narration => _internalNoteController.text.trim().isEmpty
      ? _staffNoteController.text.trim()
      : _internalNoteController.text.trim();

  Future<void> _onSave() async {
    if (!widget.isRefund) {
      await _onSavePayment();
      return;
    }
    await _onSaveRefund();
  }

  /// Receive Payment: one payment per sibling. In Custom Amount mode each typed
  /// amount is validated against that sibling's outstanding; otherwise each
  /// sibling's full outstanding is paid.
  Future<void> _onSavePayment() async {
    final List<PayableStudent> students = _cubit.state.payableStudents;
    final Map<String, double> amounts = <String, double>{};
    if (_useCustomAmount) {
      for (final PayableStudent s in students) {
        final double value =
            double.tryParse(_controllerFor(s.code).text.trim()) ?? 0;
        if (value > s.outstanding + 0.001) {
          _showMessage(
            'Amount for ${s.name} exceeds outstanding '
            '(\$${s.outstanding.toStringAsFixed(2)}).',
            isError: true,
          );
          return;
        }
        amounts[s.code] = value;
      }
    } else {
      for (final PayableStudent s in students) {
        amounts[s.code] = s.outstanding;
      }
    }
    final result = await _cubit.submitPayments(
      amountsByCode: amounts,
      chequeNumber: _chequeNumberController.text,
      ownerType: widget.ownerType,
      ownerCode: widget.ownerCode,
      narration: _narration,
    );
    if (!mounted) return;
    _handleResult(result);
  }

  /// Issue Refund: single amount, capped at the invoice amount.
  Future<void> _onSaveRefund() async {
    if (_useCustomAmount) {
      final double value = double.tryParse(_amountController.text.trim()) ?? 0;
      if (value > widget.transaction.amount + 0.001) {
        _showMessage(
          'Refund cannot exceed the invoice amount '
          '(\$${widget.transaction.amount.toStringAsFixed(2)}).',
          isError: true,
        );
        return;
      }
    }
    final String amount = _useCustomAmount
        ? _amountController.text
        : _outstandingValue.toStringAsFixed(2);
    final result = await _cubit.validateAndSave(
      amount: amount,
      chequeNumber: _chequeNumberController.text,
      isRefund: true,
      studentCode: widget.studentCode,
      ownerType: widget.ownerType,
      ownerCode: widget.ownerCode,
      narration: _narration,
    );
    if (!mounted) return;
    _handleResult(result);
  }

  void _handleResult(ReceivePaymentRefundResult result) {
    switch (result) {
      case ReceivePaymentRefundResult.missingAmount:
        _showMessage('Please enter an amount', isError: true);
      case ReceivePaymentRefundResult.missingType:
        _showMessage('Please select a payment type', isError: true);
      case ReceivePaymentRefundResult.missingCheque:
        _showMessage('Please enter cheque number', isError: true);
      case ReceivePaymentRefundResult.failure:
        _showMessage(
          _cubit.state.errorMessage ??
              (widget.isRefund
                  ? 'Could not process the refund.'
                  : 'Could not process the payment.'),
          isError: true,
        );
      case ReceivePaymentRefundResult.success:
        _showMessage(
          widget.isRefund
              ? 'Refund processed successfully.'
              : 'Payment received successfully.',
          isSuccess: true,
        );
        Navigator.of(context).maybePop(true);
    }
  }

  void _showMessage(String message,
      {bool isError = false, bool isSuccess = false}) {
    CoreUtils.showTopSnackBar(
      context: context,
      message: message,
      isError: isError,
      isSuccess: isSuccess,
    );
  }

  // ── Shared field styling (matches the Add Staff / Create Invoice forms) ────

  TextStyle _labelStyle(ResponsiveHelper responsive) => TextStyle(
        fontSize: responsive.labelFontSize,
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w400,
        color: AppColors.billingTextColor,
      );

  Widget _fieldLabel(
    ResponsiveHelper responsive,
    String text, {
    bool required = false,
  }) {
    return RichText(
      text: TextSpan(
        style: _labelStyle(responsive),
        children: <InlineSpan>[
          TextSpan(text: text),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.errorColor),
            ),
        ],
      ),
    );
  }

  BoxDecoration _fieldBox(ResponsiveHelper responsive) => BoxDecoration(
        color: AppColors.billingCardColor,
        border: Border.all(color: const Color(0x66573353)),
        borderRadius:
            BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
      );

  EdgeInsets _fieldPadding(ResponsiveHelper responsive) => EdgeInsets.symmetric(
        horizontal: responsive.isTablet ? 16.0 : 12.0,
        vertical: responsive.isTablet ? 16.0 : 12.0,
      );

  Widget _outlinedTextField(
    ResponsiveHelper responsive, {
    required TextEditingController controller,
    required String hint,
    int minLines = 1,
    int maxLines = 1,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: _fieldBox(responsive),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        minLines: minLines,
        maxLines: maxLines,
        onChanged: onChanged,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: responsive.inputFontSize,
          fontWeight: FontWeight.w600,
          color: const Color(0xff573353),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: _labelStyle(responsive).copyWith(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: _fieldPadding(responsive),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReceivePaymentRefundCubit>.value(
      value: _cubit,
      child: BlocBuilder<ReceivePaymentRefundCubit, ReceivePaymentRefundState>(
        builder: (context, state) {
          final ResponsiveHelper responsive = ResponsiveHelper(context);
          final double verticalSpacing = responsive.verticalSpacing;
          final double labelGap = responsive.isTablet ? 8.0 : 6.0;

          return StaffFormLayout(
            title: widget.isRefund ? 'Issue Refund' : 'Receive Payment',
            bottomBar: _buildBottomBar(responsive),
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                _buildUserInfoSection(),
                SizedBox(height: verticalSpacing),
                _buildPaymentTypeField(responsive, labelGap),
                if (_selectedPaymentType == 'Cheque') ...<Widget>[
                  SizedBox(height: verticalSpacing),
                  _fieldLabel(responsive, 'Cheque Number', required: true),
                  SizedBox(height: labelGap),
                  _outlinedTextField(
                    responsive,
                    controller: _chequeNumberController,
                    hint: 'Enter cheque number',
                  ),
                ],
                SizedBox(height: verticalSpacing),
                _buildReceiveMethod(responsive),
                SizedBox(height: verticalSpacing),
                _outlinedTextField(
                  responsive,
                  controller: _internalNoteController,
                  hint: 'Add Optional Note',
                  minLines: 3,
                  maxLines: 4,
                ),
                SizedBox(height: verticalSpacing),
                CustomCheckbox(
                  value: _sendEmailNotification,
                  onChanged: (bool? value) =>
                      _cubit.setSendEmailNotification(value ?? true),
                  label: 'Send Email Notification To Parents On Payment',
                  labelStyle: _labelStyle(responsive),
                ),
                SizedBox(height: verticalSpacing),
                _fieldLabel(responsive, 'Admin Only Note'),
                SizedBox(height: labelGap),
                _outlinedTextField(
                  responsive,
                  controller: _staffNoteController,
                  hint: 'Admin Only Note',
                  minLines: 3,
                  maxLines: 4,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Receive Method ─────────────────────────────────────────────────────────

  Widget _buildReceiveMethod(ResponsiveHelper responsive) {
    final bool isRefund = widget.isRefund;
    final List<PayableStudent> students = _cubit.state.payableStudents;
    // "Current Outstanding" pays the full balance — for a family that's the sum
    // of every sibling's outstanding.
    final double totalOutstanding = isRefund
        ? _outstandingValue
        : students.fold<double>(0, (double sum, PayableStudent s) => sum + s.outstanding);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Receive Method',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: responsive.isTablet ? 18.0 : 16.0,
            fontWeight: FontWeight.w700,
            color: AppColors.billingTextColor,
          ),
        ),
        const SizedBox(height: 12),
        _methodRadio(
          responsive,
          selected: !_useCustomAmount,
          label: isRefund
              ? 'Current Outstanding'
              : 'Current Outstanding (Family Balance)',
          onTap: () => setState(() => _useCustomAmount = false),
        ),
        const SizedBox(height: 8),
        _buildAmountBox(
          responsive,
          active: !_useCustomAmount,
          readOnlyText: totalOutstanding.toStringAsFixed(2),
        ),
        const SizedBox(height: 12),
        _methodRadio(
          responsive,
          selected: _useCustomAmount,
          label: 'Custom Amount',
          onTap: () => setState(() => _useCustomAmount = true),
        ),
        if (_useCustomAmount) ...<Widget>[
          const SizedBox(height: 8),
          if (isRefund)
            _buildAmountBox(
              responsive,
              active: true,
              controller: _amountController,
            )
          else if (_cubit.state.isLoadingStudents)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            ...students.map(
              (PayableStudent s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildStudentAmountRow(responsive, s),
              ),
            ),
        ],
        if (_amountError)
          const Padding(
            padding: EdgeInsets.only(top: 4.0, left: 2.0),
            child: Text(
              '*Please enter an amount.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  /// One sibling row in the Custom Amount section: avatar + name + outstanding
  /// on the left, a `$` amount input on the right, with an inline error when
  /// the typed amount exceeds that sibling's outstanding.
  Widget _buildStudentAmountRow(
    ResponsiveHelper responsive,
    PayableStudent student,
  ) {
    final TextEditingController controller = _controllerFor(student.code);
    final double typed = double.tryParse(controller.text.trim()) ?? 0;
    final bool over = typed > student.outstanding + 0.001;
    final double radius = responsive.isTablet ? 12.0 : 8.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.billingCardColor,
        border: Border.all(
          color: over ? AppColors.errorColor : const Color(0x33573353),
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _avatar(student.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      student.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.billingTextColor,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Outstanding: \$${student.outstanding.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.billingGrey,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 130,
                child: _buildAmountBox(
                  responsive,
                  active: true,
                  controller: controller,
                  onChanged: () => setState(() {}),
                ),
              ),
            ],
          ),
          if (over)
            const Padding(
              padding: EdgeInsets.only(top: 6.0, left: 2.0),
              child: Text(
                '*Amount exceeds outstanding.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  /// Initials avatar (matches the staff-card 50px size) for a sibling row.
  Widget _avatar(String name) {
    const List<Color> palette = <Color>[
      Color(0xFFB983FF),
      Color(0xFFF6D365),
      Color(0xFF6F8CFF),
      Color(0xFF7ED9A6),
      Color(0xFFFF9AA2),
    ];
    final Color color = palette[name.hashCode.abs() % palette.length];
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          _initials(name),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Manrope',
          ),
        ),
      ),
    );
  }

  Widget _methodRadio(
    ResponsiveHelper responsive, {
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isSubmitting ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: <Widget>[
          Radio<bool>(
            value: true,
            groupValue: selected,
            onChanged: _isSubmitting ? null : (_) => onTap(),
            activeColor: AppColors.themeColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: responsive.isTablet ? 17.0 : 15.0,
                fontWeight: FontWeight.w500,
                color: AppColors.billingTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Amount box with a `$` prefix. Editable when [controller] is provided,
  /// otherwise shows [readOnlyText]. Greyed when [active] is false.
  Widget _buildAmountBox(
    ResponsiveHelper responsive, {
    required bool active,
    TextEditingController? controller,
    String? readOnlyText,
    VoidCallback? onChanged,
  }) {
    final TextStyle valueStyle = TextStyle(
      fontFamily: 'Manrope',
      fontSize: responsive.inputFontSize,
      fontWeight: FontWeight.w600,
      color: const Color(0xff573353),
    );
    final double radius = responsive.isTablet ? 12.0 : 8.0;

    return Container(
      constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
      decoration: BoxDecoration(
        color: active ? AppColors.billingCardColor : const Color(0xFFF4F4F6),
        border: Border.all(color: const Color(0x66573353)),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: <Widget>[
          Container(
            alignment: Alignment.center,
            padding: _fieldPadding(responsive),
            decoration: BoxDecoration(
              color: const Color(0x1AB1AFE9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(radius),
                bottomLeft: Radius.circular(radius),
              ),
            ),
            child: Text(r'$', style: valueStyle),
          ),
          Expanded(
            child: controller != null
                ? TextField(
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      _cubit.clearAmountError();
                      onChanged?.call();
                    },
                    style: valueStyle,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: _labelStyle(responsive)
                          .copyWith(color: AppColors.billingGrey),
                      border: InputBorder.none,
                      contentPadding: _fieldPadding(responsive),
                    ),
                  )
                : Padding(
                    padding: _fieldPadding(responsive),
                    child: Text(readOnlyText ?? '0.00', style: valueStyle),
                  ),
          ),
        ],
      ),
    );
  }

  /// Payment Type as a bordered dropdown that visually matches the Amount box
  /// next to it (white fill, themed border, same height/padding).
  Widget _buildPaymentTypeField(ResponsiveHelper responsive, double labelGap) {
    final List<String> options = _getFilteredPaymentOptions();
    final String? selected =
        options.contains(_selectedPaymentType) ? _selectedPaymentType : null;
    final TextStyle valueStyle = TextStyle(
      fontFamily: 'Manrope',
      fontSize: responsive.inputFontSize,
      fontWeight: FontWeight.w600,
      color: const Color(0xff573353),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _fieldLabel(responsive, 'Payment Type', required: true),
        SizedBox(height: labelGap),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Container(
              constraints:
                  BoxConstraints(minHeight: responsive.inputFieldHeight),
              decoration: _fieldBox(responsive),
              child: PopupMenuButton<String>(
                enabled: !_isSubmitting,
                padding: EdgeInsets.zero,
                position: PopupMenuPosition.under,
                color: Colors.white,
                // Make the menu span the full width of the field.
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  maxWidth: constraints.maxWidth,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
                ),
                onSelected: (String value) => _cubit.setPaymentType(value),
                itemBuilder: (BuildContext context) => options
                    .map(
                      (String type) => PopupMenuItem<String>(
                        value: type,
                        child: Text(
                          type,
                          style: valueStyle.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                child: Padding(
                  padding: _fieldPadding(responsive),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          selected ?? 'Select payment type',
                          style: selected != null
                              ? valueStyle
                              : _labelStyle(responsive)
                                  .copyWith(color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.primaryColor,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(ResponsiveHelper responsive) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    return Container(
      padding:
          EdgeInsets.only(bottom: safeAreaBottom, left: 16, right: 16, top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
          topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
        ),
      ),
      child: Container(
        height: responsive.buttonHeight,
        decoration: BoxDecoration(
          gradient: _isSubmitting ? null : AppColors.buildPrimaryGradient(),
          color: _isSubmitting ? AppColors.billingGreyLight : null,
          borderRadius:
              BorderRadius.circular(responsive.isTablet ? 16.0 : 8.0),
        ),
        child: TextButton(
          onPressed: _isSubmitting ? null : _onSave,
          child: _isSubmitting
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.billingButtonTextColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Processing...',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: responsive.buttonFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.billingCardColor,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Save',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: responsive.buttonFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.billingCardColor,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    final double effectiveBalance =
        _amountUnpaid != null ? _amountUnpaid!.toDouble() : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getUserInitials(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.transaction.studentName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.billingTextColor,
                  fontFamily: 'Manrope',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.isRefund
              ? 'Invoice Amount : \$ ${widget.transaction.amount.toStringAsFixed(2)}'
              : 'Account Balance : \$ ${effectiveBalance.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.billingTextColor,
            fontFamily: 'Manrope',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 1.5,
          decoration: BoxDecoration(
            gradient: AppColors.buildSecondaryGradient(),
          ),
        ),
      ],
    );
  }

  String _getUserInitials() => _initials(widget.transaction.studentName);

  String _initials(String rawName) {
    final String name = rawName.trim();
    if (name.isEmpty) return 'NA';
    final List<String> parts = name.split(' ');
    if (parts.length >= 2) {
      final String first = parts[0].isNotEmpty ? parts[0][0] : '';
      final String second =
          parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
      return (first + second).toUpperCase();
    } else if (parts.length == 1 && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'NA';
  }
}

