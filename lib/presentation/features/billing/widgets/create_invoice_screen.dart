import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/billing/widgets/models/student_models.dart';
import 'package:wowcare/presentation/features/billing/widgets/selected_students_receipt_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

// NOTE: UI-only screen. All API/backend-related code has been removed or commented out.
// Future<void> _loadBillingItemSettings() async {
//   // API call removed for UI-only implementation.
// }

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({
    super.key,
    required this.selectedStudents,
    this.initialInvoiceData,
  });

  final List<Student> selectedStudents;
  final Map<String, dynamic>? initialInvoiceData;

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final TextEditingController _internalNoteController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  late List<_InvoiceItemFormData> _invoiceItems;

  DateTime? _dueDate;
  DateTime? _serviceStartDate;
  DateTime? _serviceEndDate;

  bool _isSubmitting = false;
  bool _isFormLocked = false;

  final List<String> _firstItemTypeOptions = ['New Item', 'Preset Item'];
  final List<String> _itemTypeOptions = [
    'New Item',
    'Preset Item',
    'Discount',
    'Subsidy',
  ];
  final List<String> _presetItemOptions = [
    'Tuition Fee',
    'Activity Fee',
    'Late Pick-up',
  ];
  final List<String> _discountOptions = [
    'Sibling Discount',
    'Loyalty Discount',
  ];

  @override
  void initState() {
    super.initState();
    _invoiceItems = [_InvoiceItemFormData.initial(isPrimary: true)];
    _hydrateFromInitialData();
  }

  @override
  void dispose() {
    _internalNoteController.dispose();
    for (final item in _invoiceItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _hydrateFromInitialData() {
    final data = widget.initialInvoiceData;
    if (data == null) return;

    if (data['invoiceItems'] is List) {
      final List<dynamic> items = data['invoiceItems'] as List<dynamic>;
      if (items.isNotEmpty) {
        for (final item in _invoiceItems) {
          item.dispose();
        }
        _invoiceItems = items.mapIndexed((index, raw) {
          final map = raw as Map<String, dynamic>;
          return _InvoiceItemFormData(
            type:
                map['type']?.toString() ??
                (index == 0 ? 'New Item' : 'Preset Item'),
            description: map['description']?.toString() ?? '',
            amount: map['amount']?.toString() ?? '',
            deductionAmount: map['deductionAmt']?.toString() ?? '',
            percentageAmount: map['percentageAmt']?.toString() ?? '',
            currencySign: map['currencySign']?.toString() ?? '%',
            isPrimary: index == 0,
          );
        }).toList();
        for (var i = 0; i < _invoiceItems.length; i++) {
          _recalculateDiscountAmount(i);
        }
      }
    }

    if (data['internalNote'] is String) {
      _internalNoteController.text = data['internalNote'] as String;
    }

    if (data['invoiceDate'] is DateTime) {
      _dueDate = data['invoiceDate'] as DateTime;
    }

    if (data['serviceDate'] is DateTime) {
      _serviceStartDate = data['serviceDate'] as DateTime;
    }

    if (data['serviceDateEnd'] is DateTime) {
      _serviceEndDate = data['serviceDateEnd'] as DateTime;
    }
  }

  double get _totalAmount {
    double total = 0;
    for (final item in _invoiceItems) {
      final amount =
          double.tryParse(
            item.amountController.text.isEmpty
                ? item.amount
                : item.amountController.text,
          ) ??
          0;
      if (item.type == 'Discount' || item.type == 'Subsidy') {
        total -= amount;
      } else {
        total += amount;
      }
    }
    return total;
  }

  Future<void> _pickDate({
    required DateTime? currentValue,
    required ValueChanged<DateTime?> onSelected,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentValue ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => onSelected(picked));
    }
  }

  void _addInvoiceItem() {
    if (_isFormLocked) return;
    setState(() {
      _invoiceItems.add(_InvoiceItemFormData.initial());
    });
  }

  void _removeInvoiceItem(int index) {
    if (_isFormLocked || index == 0 || index >= _invoiceItems.length) return;
    setState(() {
      final removed = _invoiceItems.removeAt(index);
      removed.dispose();
    });
  }

  void _updateInvoiceItem(
    int index, {
    String? type,
    String? description,
    String? amount,
    String? deduction,
    String? percentage,
    String? currencySign,
  }) {
    if (index < 0 || index >= _invoiceItems.length) return;
    final item = _invoiceItems[index];

    setState(() {
      if (type != null) {
        item.type = type;
        if (type == 'Discount' || type == 'Subsidy') {
          item.currencySign = currencySign ?? item.currencySign;
          item.amountController.text = item.amountController.text.isEmpty
              ? '0'
              : item.amountController.text;
        }
      }
      if (description != null) {
        item.description = description;
        if (item.descriptionController.text != description) {
          item.descriptionController.text = description;
        }
      }
      if (amount != null) {
        item.amount = amount;
        if (item.amountController.text != amount) {
          item.amountController.text = amount;
        }
      }
      if (deduction != null) {
        item.deductionAmount = deduction;
        if (item.deductionController.text != deduction) {
          item.deductionController.text = deduction;
        }
      }
      if (percentage != null) {
        item.percentageAmount = percentage;
        if (item.percentageController.text != percentage) {
          item.percentageController.text = percentage;
        }
      }
      if (currencySign != null) {
        item.currencySign = currencySign;
      }
      _recalculateDiscountAmount(index);
    });
  }

  void _recalculateDiscountAmount(int index) {
    if (index < 0 || index >= _invoiceItems.length) return;
    final item = _invoiceItems[index];
    if (item.type != 'Discount' && item.type != 'Subsidy') return;

    final deductionValue =
        double.tryParse(
          item.deductionController.text.isEmpty
              ? item.deductionAmount
              : item.deductionController.text,
        ) ??
        0;
    if (item.currencySign == '%') {
      final baseAmount =
          double.tryParse(
            item.percentageController.text.isEmpty
                ? item.percentageAmount
                : item.percentageController.text,
          ) ??
          0;
      final calculated = (baseAmount * deductionValue) / 100;
      item.amount = calculated.toStringAsFixed(2);
      item.amountController
        ..text = calculated.toStringAsFixed(2)
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: item.amountController.text.length),
        );
    } else {
      item.amount = deductionValue.toStringAsFixed(2);
      item.amountController
        ..text = deductionValue.toStringAsFixed(2)
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: item.amountController.text.length),
        );
    }
  }

  List<String> _descriptionOptionsForType(String type) {
    switch (type) {
      case 'Preset Item':
        return _presetItemOptions;
      case 'Discount':
        return _discountOptions;
      case 'Subsidy':
        return const [];
      default:
        return const [];
    }
  }

  void _handleSubmit() {
    if (_isSubmitting) return;
    if (!_validateRequiredFields()) {
      return;
    }
    if (_invoiceItems.every(
      (item) => item.amountController.text.trim().isEmpty,
    )) {
      _showValidationMessage('Please enter at least one invoice item amount');
      return;
    }

    // Build invoice data payload to show on the receipt screen (UI-only)
    final invoiceData = <String, dynamic>{
      'invoiceItems': _invoiceItems
          .map(
            (it) => {
              'type': it.type,
              'description': it.descriptionController.text.trim().isEmpty
                  ? it.description
                  : it.descriptionController.text,
              'currencySign': it.currencySign,
              'amount': it.amountController.text.trim().isEmpty
                  ? it.amount
                  : it.amountController.text,
              'deductionAmt': it.deductionController.text.trim().isEmpty
                  ? it.deductionAmount
                  : it.deductionController.text,
              'percentageAmt': it.percentageController.text.trim().isEmpty
                  ? it.percentageAmount
                  : it.percentageController.text,
            },
          )
          .toList(),
      'internalNote': _internalNoteController.text.trim(),
      'invoiceDate': _dueDate,
      'serviceDate': _serviceStartDate,
      'serviceDateEnd': _serviceEndDate,
    };

    setState(() => _isSubmitting = true);
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SelectedStudentsReceiptScreen(
            selectedStudents: widget.selectedStudents,
            invoiceData: invoiceData,
          ),
        ),
      );
    });
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
    final safeAreaBottom = MediaQuery.of(context).padding.bottom > 0
        ? MediaQuery.of(context).padding.bottom
        : 16.0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.billingCardColor,
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
            Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalSpacing),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Create Invoice',
                      style: AppTextStyles.title.copyWith(
                        fontSize: responsive.titleFontSize,
                        color: AppColors.billingTextColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 32.0 : 20.0),
                Expanded(
                  child: Container(
                    width: containerWidth,
                    margin: EdgeInsets.symmetric(horizontal: horizontalSpacing),
                    padding: EdgeInsets.all(isTablet ? 32.0 : 16.0),
                    decoration: BoxDecoration(
                      color: AppColors.billingCardColor,
                      borderRadius: BorderRadius.all(
                        Radius.circular(isTablet ? 40.0 : 24.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.billingShadowColorLight,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              _SelectedStudentsBanner(
                                students: widget.selectedStudents,
                              ),
                              SizedBox(height: responsive.verticalSpacing),
                              _buildDueDatePicker(responsive, isTablet),
                              SizedBox(height: responsive.verticalSpacing),
                              _buildServiceDateRange(responsive, isTablet),
                              SizedBox(height: responsive.verticalSpacing),
                              _buildInvoiceItemsSection(responsive, isTablet),
                              SizedBox(height: responsive.verticalSpacing),
                              _buildInternalNoteField(responsive),
                              SizedBox(height: responsive.verticalSpacing),
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
            color: AppColors.billingCardColor,
            boxShadow: [
              BoxShadow(
                color: AppColors.billingShadowColorLight,
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
              color: _isSubmitting ? AppColors.billingButtonDisabled : null,
              borderRadius: BorderRadius.circular(
                responsive.isTablet ? 16.0 : 8.0,
              ),
            ),
            child: TextButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              child: Text(
                'Save Invoice (UI Only)',
                style: AppTextStyles.button(
                  color: AppColors.billingCardColor,
                ).copyWith(fontSize: responsive.buttonFontSize),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDueDatePicker(ResponsiveHelper responsive, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _requiredLabel(
          'Invoice Due Date',
          AppTextStyles.label.copyWith(
            fontSize: responsive.labelFontSize,
            fontWeight: FontWeight.w500,
            color: AppColors.billingTextColor,
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => _pickDate(
              currentValue: _dueDate,
              onSelected: (value) => _dueDate = value,
            ),
            child: Container(
              width: 160,
              height: isTablet ? 56.0 : 44.0,
              decoration: BoxDecoration(
                color: AppColors.billingBorderLight,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 16.0 : 12.0),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _dueDate == null
                          ? 'Select date'
                          : _dateFormat.format(_dueDate!),
                      style: AppTextStyles.value.copyWith(
                        fontSize: isTablet ? 16.0 : 14.0,
                        color: AppColors.billingTextColor,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.billingTextColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceDateRange(ResponsiveHelper responsive, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Service (Optional)',
          style: AppTextStyles.label.copyWith(
            fontSize: responsive.labelFontSize,
            fontWeight: FontWeight.w500,
            color: AppColors.billingTextColor,
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Row(
          children: [
            Flexible(
              child: GestureDetector(
                onTap: () => _pickDate(
                  currentValue: _serviceStartDate,
                  onSelected: (value) => _serviceStartDate = value,
                ),
                child: _DateField(
                  label: _serviceStartDate == null
                      ? 'Select date'
                      : _dateFormat.format(_serviceStartDate!),
                  isTablet: isTablet,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'to',
              style: AppTextStyles.small.copyWith(
                color: AppColors.billingTextColor,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: GestureDetector(
                onTap: () => _pickDate(
                  currentValue: _serviceEndDate,
                  onSelected: (value) => _serviceEndDate = value,
                ),
                child: _DateField(
                  label: _serviceEndDate == null
                      ? 'Select date'
                      : _dateFormat.format(_serviceEndDate!),
                  isTablet: isTablet,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvoiceItemsSection(ResponsiveHelper responsive, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _requiredLabel(
                'Invoice Items',
                TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: responsive.labelFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppColors.billingTextColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildAddItemButton(isTablet),
          ],
        ),
        SizedBox(height: responsive.isTablet ? 12.0 : 10.0),
        ..._invoiceItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isDiscountType =
              item.type == 'Discount' || item.type == 'Subsidy';
          final descriptionOptions = _descriptionOptionsForType(item.type);
          final String? safeTypeValue = _safeDropdownValue(
            item.type,
            index == 0 ? _firstItemTypeOptions : _itemTypeOptions,
          );
          final String? safeDescriptionValue = _safeDropdownValue(
            item.description.isEmpty ? null : item.description,
            descriptionOptions,
          );
          final String? safeUnitValue =
              _safeDropdownValue(item.currencySign, const ['%', r'$']) ?? '%';
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _invoiceItems.length - 1
                  ? 0
                  : responsive.verticalSpacing,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: index == 0
                    ? AppColors.billingCardColor
                    : AppColors.billingGreyLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: index == 0
                      ? AppColors.billingInputBorderFocused
                      : AppColors.billingInputBorderDefault,
                ),
              ),
              padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    index == 0
                        ? 'Primary Item'
                        : 'Additional Item ${index + 1}',
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.billingTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ItemDropdown(
                    label: 'Type',
                    value: safeTypeValue,
                    options: index == 0
                        ? _firstItemTypeOptions
                        : _itemTypeOptions,
                    isEnabled: !_isFormLocked,
                    onChanged: (value) {
                      if (value != null) {
                        _updateInvoiceItem(index, type: value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (descriptionOptions.isNotEmpty)
                    _ItemDropdown(
                      label: 'Item Description',
                      value: safeDescriptionValue,
                      options: descriptionOptions,
                      isEnabled:
                          !_isFormLocked && descriptionOptions.isNotEmpty,
                      hint: descriptionOptions.isEmpty
                          ? 'No items available'
                          : 'Select ${item.type.toLowerCase()}',
                      onChanged: (value) {
                        if (value != null) {
                          _updateInvoiceItem(index, description: value);
                        }
                      },
                    )
                  else
                    _ItemTextField(
                      label: 'Item Description',
                      controller: item.descriptionController,
                      enabled: !_isFormLocked,
                      hintText: 'Enter item description',
                      onChanged: (value) =>
                          _updateInvoiceItem(index, description: value),
                    ),
                  const SizedBox(height: 12),
                  _ItemTextField(
                    label: 'Amount',
                    controller: item.amountController,
                    enabled: !_isFormLocked && !isDiscountType,
                    hintText: isDiscountType ? 'Calculated' : 'Enter amount',
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _updateInvoiceItem(index, amount: value),
                  ),
                  if (isDiscountType) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: item.currencySign == '%' ? 3 : 1,
                          child: _ItemTextField(
                            label: item.currencySign == '%'
                                ? 'Discount (%)'
                                : 'Discount Amount',
                            controller: item.deductionController,
                            enabled: !_isFormLocked,
                            keyboardType: TextInputType.number,
                            prefixText: item.currencySign == '%' ? null : '\$',
                            onChanged: (value) =>
                                _updateInvoiceItem(index, deduction: value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: _ItemDropdown(
                            label: 'Unit',
                            value: safeUnitValue,
                            options: const ['%', r'$'],
                            isEnabled: !_isFormLocked,
                            onChanged: (value) {
                              if (value != null) {
                                _updateInvoiceItem(index, currencySign: value);
                              }
                            },
                          ),
                        ),
                        if (item.currencySign == '%') ...[
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: _ItemTextField(
                              label: 'Of Amount',
                              controller: item.percentageController,
                              enabled: !_isFormLocked,
                              keyboardType: TextInputType.number,
                              onChanged: (value) =>
                                  _updateInvoiceItem(index, percentage: value),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (index > 0) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => _removeInvoiceItem(index),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.billingStatusError,
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              MediaRes.delete_icon,
                              width: 22,
                              height: 22,
                              color: AppColors.billingCardColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: responsive.isTablet ? 16.0 : 12.0,
            horizontal: responsive.isTablet ? 20.0 : 14.0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              responsive.isTablet ? 12.0 : 8.0,
            ),
            color: const Color(0x1AB1AFE9),
            border: Border.all(color: AppColors.billingBorderMedium),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: \$${_totalAmount.toStringAsFixed(2)}',
              style: AppTextStyles.title.copyWith(
                color: AppColors.billingTextColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddItemButton(bool isTablet) {
    final borderRadius = BorderRadius.circular(isTablet ? 14.0 : 10.0);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: isTablet ? 48.0 : 42.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: _isFormLocked ? null : AppColors.buildPrimaryGradient(),
          color: _isFormLocked
              ? AppColors.billingInputBackgroundDisabled
              : null,
          boxShadow: _isFormLocked
              ? null
              : [
                  BoxShadow(
                    color: AppColors.billingShadowColorMedium,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: TextButton.icon(
          onPressed: _isFormLocked ? null : _addInvoiceItem,
          icon: Icon(
            Icons.add,
            color: AppColors.billingButtonTextColor,
            size: 18,
          ),
          label: Text(
            'Add Item',
            style: AppTextStyles.label.copyWith(
              fontSize: isTablet ? 15 : 13,
              fontWeight: FontWeight.w600,
              color: AppColors.billingCardColor,
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor: AppColors.billingTransparentColor,
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 18.0 : 14.0,
              vertical: 10.0,
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }

  Widget _buildInternalNoteField(ResponsiveHelper responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Internal Note',
          style: AppTextStyles.small.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.billingTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.billingCardColor,
            border: Border.all(color: AppColors.billingBorderHeavy),
            borderRadius: BorderRadius.circular(
              responsive.isTablet ? 12.0 : 8.0,
            ),
          ),
          child: TextField(
            controller: _internalNoteController,
            enabled: !_isFormLocked,
            maxLines: 4,
            minLines: 2,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Add internal note',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _requiredLabel(String text, TextStyle style) {
    return RichText(
      text: TextSpan(
        text: text,
        style: style,
        children: [
          TextSpan(
            text: ' *',
            style: AppTextStyles.small.copyWith(
              color: AppColors.billingStatusError,
            ),
          ),
        ],
      ),
    );
  }

  bool _validateRequiredFields() {
    if (_dueDate == null) {
      _showValidationMessage('Please select an invoice due date.');
      return false;
    }

    for (var index = 0; index < _invoiceItems.length; index++) {
      final item = _invoiceItems[index];
      final description = _effectiveControllerValue(
        item.descriptionController,
        fallback: item.description,
      );
      if (description.trim().isEmpty) {
        _showValidationMessage(
          'Please provide a description for invoice item ${index + 1}.',
        );
        return false;
      }

      final amountText = _effectiveControllerValue(
        item.amountController,
        fallback: item.amount,
      );
      final isDiscountType = item.type == 'Discount' || item.type == 'Subsidy';
      if (amountText.trim().isEmpty) {
        final label = isDiscountType ? 'deduction' : 'amount';
        _showValidationMessage(
          'Please enter the $label for invoice item ${index + 1}.',
        );
        return false;
      }
    }

    return true;
  }

  String _effectiveControllerValue(
    TextEditingController controller, {
    required String fallback,
  }) {
    final text = controller.text.trim();
    return text.isEmpty ? fallback : text;
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

String? _safeDropdownValue(String? value, List<String> options) {
  if (value == null) return null;
  return options.contains(value) ? value : null;
}

class _SelectedStudentsBanner extends StatelessWidget {
  const _SelectedStudentsBanner({required this.students});

  final List<Student> students;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fieldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${students.length} student(s) selected',
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.billingTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: students
                .map(
                  (student) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.billingCardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorderColor),
                    ),
                    child: Text(
                      student.fullName,
                      style: AppTextStyles.small.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.billingTextColor,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.isTablet});

  final String label;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isTablet ? 56.0 : 44.0,
      decoration: BoxDecoration(
        color: const Color(0x1AB1AFE9),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 16.0 : 12.0),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.value.copyWith(
                color: AppColors.billingTextColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            Icons.calendar_today_outlined,
            color: AppColors.billingTextColor,
          ),
        ],
      ),
    );
  }
}

class _ItemDropdown extends StatelessWidget {
  const _ItemDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.isEnabled = true,
    this.hint,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool isEnabled;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.small.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.billingTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isEnabled
                ? AppColors.billingBorderLight
                : AppColors.billingInputBackgroundDisabled,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            onChanged: isEnabled ? onChanged : null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            hint: hint == null
                ? null
                : Text(
                    hint!,
                    style: AppTextStyles.value.copyWith(
                      color: AppColors.billingGreyMedium,
                    ),
                  ),
            items: options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      style: AppTextStyles.value.copyWith(
                        color: AppColors.billingTextColor,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ItemTextField extends StatelessWidget {
  const _ItemTextField({
    required this.label,
    required this.controller,
    this.enabled = true,
    this.hintText,
    this.keyboardType,
    this.onChanged,
    this.prefixText,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String? hintText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.small.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.billingTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? const Color(0x1AB1AFE9) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            onChanged: onChanged,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
              prefixText: prefixText,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InvoiceItemFormData {
  _InvoiceItemFormData({
    required this.type,
    required this.description,
    required this.amount,
    required this.deductionAmount,
    required this.percentageAmount,
    required this.currencySign,
    this.isPrimary = false,
  }) : descriptionController = TextEditingController(text: description),
       amountController = TextEditingController(text: amount),
       deductionController = TextEditingController(text: deductionAmount),
       percentageController = TextEditingController(text: percentageAmount);

  factory _InvoiceItemFormData.initial({bool isPrimary = false}) {
    return _InvoiceItemFormData(
      type: isPrimary ? 'New Item' : 'Preset Item',
      description: '',
      amount: '',
      deductionAmount: '',
      percentageAmount: '',
      currencySign: '%',
      isPrimary: isPrimary,
    );
  }

  String type;
  String description;
  String amount;
  String deductionAmount;
  String percentageAmount;
  String currencySign;
  final bool isPrimary;

  final TextEditingController descriptionController;
  final TextEditingController amountController;
  final TextEditingController deductionController;
  final TextEditingController percentageController;

  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    deductionController.dispose();
    percentageController.dispose();
  }
}

extension IterableMapIndexedExtension<T> on Iterable<T> {
  List<R> mapIndexed<R>(R Function(int index, T value) callback) {
    var index = 0;
    final result = <R>[];
    for (final value in this) {
      result.add(callback(index, value));
      index += 1;
    }
    return result;
  }
}
