import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class ReceivePaymentIssueRefundScreen extends StatefulWidget {
  const ReceivePaymentIssueRefundScreen({
    super.key,
    required this.transaction,
    this.isRefund = false,
  });

  final TransactionItem transaction;
  final bool isRefund;

  @override
  State<ReceivePaymentIssueRefundScreen> createState() =>
      _ReceivePaymentIssueRefundScreenState();
}

class _ReceivePaymentIssueRefundScreenState
    extends State<ReceivePaymentIssueRefundScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _internalNoteController;
  late final TextEditingController _staffNoteController;
  late final TextEditingController _chequeNumberController;

  bool _isSubmitting = false;
  bool _amountError = false;
  bool _sendEmailNotification = true;
  String? _selectedPaymentType;

  double? _amountUnpaid;

  final List<String> _paymentTypeOptions = <String>[
    'Cash',
    'Cheque',
    'Online',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.isRefund
          ? widget.transaction.amount.toStringAsFixed(2)
          : (widget.transaction.balance != null &&
                  widget.transaction.balance! < 0)
              ? widget.transaction.balance!.abs().toStringAsFixed(2)
              : widget.transaction.amount.toStringAsFixed(2),
    );
    _internalNoteController = TextEditingController();
    _staffNoteController = TextEditingController();
    _chequeNumberController = TextEditingController();

    _amountUnpaid = widget.transaction.balance;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _internalNoteController.dispose();
    _staffNoteController.dispose();
    _chequeNumberController.dispose();
    super.dispose();
  }

  List<String> _getFilteredPaymentOptions() {
    if (!widget.isRefund) {
      return _paymentTypeOptions.where((String t) => t != 'Online').toList();
    }
    return _paymentTypeOptions;
  }

  Future<void> _onSave() async {
    if (_amountController.text.trim().isEmpty) {
      setState(() {
        _amountError = true;
      });
      _showSnackBar('Please enter an amount');
      return;
    }

    if (_selectedPaymentType == null) {
      _showSnackBar('Please select a payment type');
      return;
    }

    if (_selectedPaymentType == 'Cheque' &&
        _chequeNumberController.text.trim().isEmpty) {
      _showSnackBar('Please enter cheque number');
      return;
    }

    setState(() {
      _amountError = false;
      _isSubmitting = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    _showSnackBar(
      widget.isRefund
          ? 'Refund saved (UI only).'
          : 'Payment saved (UI only).',
    );
    Navigator.of(context).maybePop(true);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ResponsiveHelper responsive = ResponsiveHelper(context);
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = responsive.isTablet;
    final bool isLargeTablet = responsive.isLargeTablet;
    final double containerWidth = isLargeTablet
        ? (screenSize.width * 0.8).clamp(800.0, 1200.0)
        : isTablet
            ? screenSize.width * 0.9
            : screenSize.width - 32.0;
    final double horizontalSpacing = isLargeTablet
        ? (screenSize.width * 0.1).clamp(32.0, 64.0)
        : isTablet
            ? 32.0
            : 16.0;
    final double verticalSpacing = isLargeTablet
        ? 32.0
        : isTablet
            ? 24.0
            : 16.0;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.buildScaffoldGradient(),
                ),
                child: Image.asset(
                  MediaRes.wowcareMobileBg,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    pinned: true,
                    floating: true,
                    snap: true,
                    stretch: true,
                    scrolledUnderElevation: 0,
                    backgroundColor: Colors.white,
                    leading: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xff573353),
                      ),
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(1.5),
                      child: Container(
                        decoration: BoxDecoration(
                          border: const Border(
                            bottom: BorderSide(
                              width: 1.5,
                              color: Colors.transparent,
                            ),
                          ),
                          gradient: AppColors.buildSecondaryGradient(),
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: Column(
                children: <Widget>[
                  const SizedBox(height: 16),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalSpacing),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.isRefund ? 'Issue Refund' : 'Receive Payment',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: responsive.titleFontSize,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff573353),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.isTablet ? 32.0 : 20.0),
                  Expanded(
                    child: Container(
                      width: containerWidth,
                      margin:
                          EdgeInsets.symmetric(horizontal: horizontalSpacing),
                      padding: EdgeInsets.all(responsive.isTablet ? 32.0 : 16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(
                          Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: <Widget>[
                                _buildUserInfoSection(),
                                SizedBox(height: verticalSpacing),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontSize:
                                                    responsive.labelFontSize,
                                                fontFamily: 'Manrope',
                                                fontWeight: FontWeight.w400,
                                                color:
                                                    const Color(0xff573353),
                                              ),
                                              children: const <InlineSpan>[
                                                TextSpan(text: 'Amount'),
                                                TextSpan(
                                                  text: ' *',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height: responsive.isTablet
                                                ? 8.0
                                                : 6.0,
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: const Color(0x66573353),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                responsive.isTablet
                                                    ? 12.0
                                                    : 8.0,
                                              ),
                                            ),
                                            child: Row(
                                              children: <Widget>[
                                                Container(
                                                  padding:
                                                      EdgeInsets.symmetric(
                                                    horizontal:
                                                        responsive.isTablet
                                                            ? 16.0
                                                            : 12.0,
                                                    vertical:
                                                        responsive.isTablet
                                                            ? 16.0
                                                            : 12.0,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0x1AB1AFE9,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(
                                                        responsive.isTablet
                                                            ? 12.0
                                                            : 8.0,
                                                      ),
                                                      bottomLeft:
                                                          Radius.circular(
                                                        responsive.isTablet
                                                            ? 12.0
                                                            : 8.0,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '\$',
                                                    style: TextStyle(
                                                      fontSize: responsive
                                                          .labelFontSize,
                                                      fontFamily: 'Manrope',
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: const Color(
                                                        0xff573353,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: TextField(
                                                    controller:
                                                        _amountController,
                                                    keyboardType:
                                                        const TextInputType
                                                            .numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                    onChanged: (_) {
                                                      if (_amountError) {
                                                        setState(() {
                                                          _amountError = false;
                                                        });
                                                      }
                                                    },
                                                    decoration:
                                                        InputDecoration(
                                                      hintText:
                                                          'Enter Amount',
                                                      hintStyle: TextStyle(
                                                        fontSize: responsive
                                                            .labelFontSize,
                                                        fontFamily: 'Manrope',
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: Colors.grey,
                                                      ),
                                                      border: InputBorder.none,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                        horizontal:
                                                            responsive.isTablet
                                                                ? 16.0
                                                                : 12.0,
                                                        vertical:
                                                            responsive.isTablet
                                                                ? 16.0
                                                                : 12.0,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (_amountError)
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                top: 4.0,
                                                left: 2.0,
                                              ),
                                              child: Text(
                                                '*This field is required.',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontSize:
                                                    responsive.labelFontSize,
                                                fontFamily: 'Manrope',
                                                fontWeight: FontWeight.w400,
                                                color:
                                                    const Color(0xff573353),
                                              ),
                                              children: const <InlineSpan>[
                                                TextSpan(
                                                    text: 'Payment Type'),
                                                TextSpan(
                                                  text: ' *',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height: responsive.isTablet
                                                ? 8.0
                                                : 6.0,
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: const Color(0x66573353),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                responsive.isTablet
                                                    ? 12.0
                                                    : 8.0,
                                              ),
                                            ),
                                            child: DropdownButtonFormField<
                                                String>(
                                              value: _getFilteredPaymentOptions()
                                                      .contains(
                                                          _selectedPaymentType)
                                                  ? _selectedPaymentType
                                                  : null,
                                              isExpanded: true,
                                              decoration:
                                                  const InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  horizontal: 16.0,
                                                  vertical: 12.0,
                                                ),
                                              ),
                                              hint: Text(
                                                'Select payment type',
                                                style: TextStyle(
                                                  fontSize: responsive
                                                      .labelFontSize,
                                                  fontFamily: 'Manrope',
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              items:
                                                  _getFilteredPaymentOptions()
                                                      .map(
                                                (String type) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: type,
                                                    child: Text(
                                                      type,
                                                      style: TextStyle(
                                                        fontSize: responsive
                                                            .labelFontSize,
                                                        fontFamily: 'Manrope',
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: const Color(
                                                          0xff573353,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ).toList(),
                                              onChanged: (String? value) {
                                                setState(() {
                                                  _selectedPaymentType = value;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (_selectedPaymentType == 'Cheque') ...<
                                    Widget>[
                                  SizedBox(height: verticalSpacing),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontSize:
                                                responsive.labelFontSize,
                                            fontFamily: 'Manrope',
                                            fontWeight: FontWeight.w400,
                                            color: const Color(0xff573353),
                                          ),
                                          children: const <InlineSpan>[
                                            TextSpan(text: 'Cheque Number'),
                                            TextSpan(
                                              text: ' *',
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height:
                                            responsive.isTablet ? 8.0 : 6.0,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                            color: const Color(0x66573353),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            responsive.isTablet
                                                ? 12.0
                                                : 8.0,
                                          ),
                                        ),
                                        child: TextField(
                                          controller:
                                              _chequeNumberController,
                                          decoration: InputDecoration(
                                            hintText: 'Enter cheque number',
                                            hintStyle: TextStyle(
                                              fontSize:
                                                  responsive.labelFontSize,
                                              fontFamily: 'Manrope',
                                              fontWeight: FontWeight.w400,
                                              color: Colors.grey,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal:
                                                  responsive.isTablet
                                                      ? 16.0
                                                      : 12.0,
                                              vertical: responsive.isTablet
                                                  ? 16.0
                                                  : 12.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                SizedBox(height: verticalSpacing),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Add Optional Internal Note',
                                      style: TextStyle(
                                        fontSize: responsive.labelFontSize,
                                        fontFamily: 'Manrope',
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xff573353),
                                      ),
                                    ),
                                    SizedBox(
                                      height:
                                          responsive.isTablet ? 8.0 : 6.0,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: const Color(0x66573353),
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          responsive.isTablet
                                              ? 12.0
                                              : 8.0,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _internalNoteController,
                                        maxLines: 4,
                                        minLines: 3,
                                        decoration: InputDecoration(
                                          hintText:
                                              'Add Optional Internal Note',
                                          hintStyle: TextStyle(
                                            fontSize:
                                                responsive.labelFontSize,
                                            fontFamily: 'Manrope',
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              EdgeInsets.symmetric(
                                            horizontal: responsive.isTablet
                                                ? 16.0
                                                : 12.0,
                                            vertical: responsive.isTablet
                                                ? 16.0
                                                : 12.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: verticalSpacing),
                                Row(
                                  children: <Widget>[
                                    Checkbox(
                                      value: _sendEmailNotification,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _sendEmailNotification =
                                              value ?? true;
                                        });
                                      },
                                      activeColor: const Color(0xFF6B73FF),
                                      checkColor: Colors.white,
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Send Email Notification To Parents On Payment',
                                        style: TextStyle(
                                          fontSize: responsive.labelFontSize,
                                          fontFamily: 'Manrope',
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xff573353),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: verticalSpacing),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Staff Only Note',
                                      style: TextStyle(
                                        fontSize: responsive.labelFontSize,
                                        fontFamily: 'Manrope',
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xff573353),
                                      ),
                                    ),
                                    SizedBox(
                                      height:
                                          responsive.isTablet ? 8.0 : 6.0,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: const Color(0x66573353),
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          responsive.isTablet
                                              ? 12.0
                                              : 8.0,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _staffNoteController,
                                        maxLines: 4,
                                        minLines: 3,
                                        decoration: InputDecoration(
                                          hintText: 'Staff Only Note',
                                          hintStyle: TextStyle(
                                            fontSize:
                                                responsive.labelFontSize,
                                            fontFamily: 'Manrope',
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              EdgeInsets.symmetric(
                                            horizontal: responsive.isTablet
                                                ? 16.0
                                                : 12.0,
                                            vertical: responsive.isTablet
                                                ? 16.0
                                                : 12.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(
            bottom: safeAreaBottom,
            left: 16,
            right: 16,
            top: 8,
          ),
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
              gradient:
                  _isSubmitting ? null : AppColors.buildPrimaryGradient(),
              color: _isSubmitting ? Colors.grey[300] : null,
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Processing...',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: responsive.buttonFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
                        color: Colors.white,
                      ),
                    ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.transaction.studentName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff573353),
                      fontFamily: 'Manrope',
                    ),
                  ),
                  Text(
                    widget.isRefund
                        ? 'Invoice Amount : \$${widget.transaction.amount.toStringAsFixed(2)}'
                        : 'Account Balance : \$${effectiveBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff573353),
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 1,
          color: AppColors.primaryColor.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  String _getUserInitials() {
    final String name = widget.transaction.studentName.trim();
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

