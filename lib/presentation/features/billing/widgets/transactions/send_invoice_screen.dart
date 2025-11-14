import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/core/util/date_utils.dart';
import 'package:wowcare/shared/common/widgets/gradient_background.dart';

class SendInvoiceScreen extends StatefulWidget {
  const SendInvoiceScreen({
    super.key,
    required this.transaction,
  });

  final TransactionItem transaction;

  @override
  State<SendInvoiceScreen> createState() => _SendInvoiceScreenState();
}

class _SendInvoiceScreenState extends State<SendInvoiceScreen> {
  // Dummy data for UI
  Map<String, dynamic>? _addressEntity;
  bool _isAddressLoading = false;
  bool _isInvoiceLoading = false;
  bool _isSendingInvoice = false;
  Map<String, dynamic>? _invoiceDetails;

  // Form controllers
  final TextEditingController _invoiceNumberController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // Form data
  String _invoiceNumber = '';
  DateTime? _dueDate;
  String _description = '';
  double _amount = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeDummyData();
    _initializeFormData();
  }

  Future<void> _initializeDummyData() async {
    // Simulate loading
    setState(() {
      _isAddressLoading = true;
      _isInvoiceLoading = true;
    });

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Load dummy data
    Map<String, dynamic>? invoiceData;
    if (widget.transaction.refTable == 'Invoice' && widget.transaction.refTableId != null) {
      invoiceData = {
        'invoiceNumber': 'INV-2025-${widget.transaction.refTableId}',
        'startDate': widget.transaction.date.subtract(const Duration(days: 30)).toIso8601String(),
        'endDate': widget.transaction.date.toIso8601String(),
        'dueDate': widget.transaction.endDate != null
            ? DateTime.parse(widget.transaction.endDate!).toIso8601String()
            : widget.transaction.date.add(const Duration(days: 7)).toIso8601String(),
        'invoiceAmount': widget.transaction.amount,
        'description': widget.transaction.description,
      };
    }

    setState(() {
      _addressEntity = {
        'line': '123 Main Street',
        'city': 'New York',
        'state': 'NY',
        'country': 'USA',
        'zipcode': '10001',
      };
      _invoiceDetails = invoiceData;
      _isAddressLoading = false;
      _isInvoiceLoading = false;
    });

    // Update form with invoice data if available
    if (invoiceData != null) {
      _updateFormWithInvoiceData(invoiceData);
    }
  }

  void _initializeFormData() {
    // Generate invoice number based on current date
    final now = DateTime.now();
    _invoiceNumber = 'INV${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _invoiceNumberController.text = _invoiceNumber;

    // Pre-fill with transaction data
    _descriptionController.text = widget.transaction.displayDescription;
    _amountController.text = widget.transaction.amount.toStringAsFixed(2);

    // Set form data
    _description = widget.transaction.displayDescription;
    _amount = widget.transaction.amount;
  }

  void _updateFormWithInvoiceData(Map<String, dynamic> invoiceData) {
    // Update invoice number
    if (invoiceData['invoiceNumber'] != null) {
      _invoiceNumberController.text = invoiceData['invoiceNumber'].toString();
      _invoiceNumber = _invoiceNumberController.text;
    }

    // Update due date
    if (invoiceData['dueDate'] != null) {
      try {
        final dueDateParsed = DateTime.parse(invoiceData['dueDate'].toString());
        _dueDateController.text = DateUtilsNew.formatToReadableDate(dueDateParsed);
        _dueDate = dueDateParsed;
      } catch (e) {
        // Date parsing failed, keep current value
      }
    }

    // Update amount
    if (invoiceData['invoiceAmount'] != null) {
      final invoiceAmount = double.tryParse(invoiceData['invoiceAmount'].toString()) ?? 0.0;
      _amountController.text = invoiceAmount.toStringAsFixed(2);
      _amount = invoiceAmount;
    }

    // Update description if available
    if (invoiceData['description'] != null && invoiceData['description'].toString().isNotEmpty) {
      _descriptionController.text = invoiceData['description'].toString();
      _description = _descriptionController.text;
    }
  }

  String _getInvoicePeriodText() {
    // Only show data from dummy invoice details, no hardcoded fallbacks
    if (_invoiceDetails == null) {
      // Check if this is because the transaction doesn't reference an invoice
      if (widget.transaction.refTable != 'Invoice') {
        return 'Not applicable - Transaction references ${widget.transaction.refTable}';
      }
      return 'N/A';
    }

    final startDate = _invoiceDetails!['startDate'];
    final endDate = _invoiceDetails!['endDate'];

    if (startDate == null && endDate == null) {
      return 'Not specified in invoice';
    }

    try {
      String startText = 'Not specified';
      String endText = 'Not specified';

      if (startDate != null) {
        final startParsed = DateTime.parse(startDate.toString());
        startText = DateUtilsNew.formatToReadableDate(startParsed);
      }

      if (endDate != null) {
        final endParsed = DateTime.parse(endDate.toString());
        endText = DateUtilsNew.formatToReadableDate(endParsed);
      }

      return '$startText - $endText';
    } catch (e) {
      return 'Date format error';
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _dueDateController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _sendInvoice() async {
    if (_isSendingInvoice) return;

    setState(() {
      _isSendingInvoice = true;
    });

    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isSendingInvoice = false;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invoice sent successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate back
    Navigator.pop(context, true);
  }

  Widget _buildCurrentSchoolDetail() {
    // Dummy school data
    const schoolName = 'WowCare School';
    const schoolDescription = 'Excellence in Education';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DocumentImageWidget(
          fileUuid: '',
          size: 60,
          name: schoolName,
          fontSize: 18,
        ),
        const SizedBox(height: 8),
        Text(
          schoolName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        Text(
          schoolDescription,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.primaryColor,
          ),
        ),
        if (_addressEntity != null)
          Text(
            '${_addressEntity!['line']}, ${_addressEntity!['city']}, ${_addressEntity!['state']}, ${_addressEntity!['country']}, ${_addressEntity!['zipcode']}',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ),
      ],
    );
  }

  Widget _buildBilledForRow() {
    return Row(
      children: [
        const Text(
          'Billed for : ',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        DocumentImageWidget(
          fileUuid: widget.transaction.studentPhotoUuid ?? '',
          name: widget.transaction.studentName,
          size: 32,
          fontSize: 14,
        ),
        const SizedBox(width: 5),
        Text(
          widget.transaction.studentName,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (widget.transaction.classroom.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            widget.transaction.classroom,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInvoiceDetailsSection() {
    return Column(
      children: [
        if (_isInvoiceLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Loading invoice details...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Text(
              'Invoice Number : ',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _invoiceNumberController.text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Invoice Period : ',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 4),
              Text(
                _getInvoicePeriodText(),
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.start,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Due Date : ',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _dueDateController.text.isEmpty ? 'Not set' : _dueDateController.text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvoiceTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Table Headers
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          Divider(
            thickness: 0.5,
            color: Colors.grey.withOpacity(0.3),
          ),
          // Table Row
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  _descriptionController.text.isEmpty ? '-' : _descriptionController.text,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '\$${_amountController.text}',
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          Divider(
            thickness: 0.5,
            color: Colors.grey.withOpacity(0.3),
          ),
          // Total Row with highlighted background
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'Total Amount',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '\$${_amountController.text}',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = responsive.isTablet;
    final isLargeTablet = responsive.isLargeTablet;
    final containerWidth = isLargeTablet
        ? (screenWidth * 0.8).clamp(800.0, 1200.0)
        : isTablet
            ? screenWidth * 0.9
            : screenWidth - 32.0;
    final horizontalSpacing = isLargeTablet
        ? (screenWidth * 0.1).clamp(32.0, 64.0)
        : isTablet
            ? 32.0
            : 16.0;
    final verticalSpacing = isLargeTablet
        ? 32.0
        : isTablet
            ? 24.0
            : 16.0;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const CustomAppBar(hasBackButton: true),
        body: Stack(
          children: [
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
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalSpacing),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Send Invoice',
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
                  Container(
                    width: containerWidth,
                    margin: EdgeInsets.symmetric(horizontal: horizontalSpacing),
                    padding: EdgeInsets.all(isTablet ? 32.0 : 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(
                        Radius.circular(isTablet ? 40.0 : 24.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // School Details
                        _buildCurrentSchoolDetail(),
                        SizedBox(height: verticalSpacing),
                        // Billed For Row
                        _buildBilledForRow(),
                        SizedBox(height: verticalSpacing),
                        // Invoice Details Section
                        _buildInvoiceDetailsSection(),
                        SizedBox(height: verticalSpacing),
                        // Invoice Table
                        _buildInvoiceTable(),
                      ],
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
            boxShadow: [
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
              gradient: AppColors.buildPrimaryGradient(),
              borderRadius: BorderRadius.circular(responsive.isTablet ? 16.0 : 8.0),
            ),
            child: TextButton(
              onPressed: _isSendingInvoice ? null : _sendInvoice,
              child: _isSendingInvoice
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sending...',
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
                      'Send Invoice',
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
}

