import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/billing/cubit/create_invoice_cubit.dart';
import 'package:wowcare/presentation/features/billing/widgets/models/student_models.dart';
import 'package:wowcare/presentation/features/billing/widgets/selected_students_receipt_screen.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
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
  late final CreateInvoiceCubit _cubit = CreateInvoiceCubit();
  final TextEditingController _internalNoteController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  final ValueNotifier<bool> _isSubmitting = ValueNotifier<bool>(false);

  final List<String> _firstItemTypeOptions = ['New Item', 'Preset Item'];
  final List<String> _itemTypeOptions = ['New Item', 'Preset Item', 'Discount', 'Subsidy'];
  final List<String> _presetItemOptions = ['Tuition Fee', 'Activity Fee', 'Late Pick-up'];
  final List<String> _discountOptions = ['Sibling Discount', 'Loyalty Discount'];

  // Read-only proxies onto the cubit state.
  List<InvoiceItemFormData> get _invoiceItems => _cubit.state.items;
  DateTime? get _dueDate => _cubit.state.dueDate;
  DateTime? get _serviceStartDate => _cubit.state.serviceStartDate;
  DateTime? get _serviceEndDate => _cubit.state.serviceEndDate;
  bool get _isFormLocked => _cubit.state.isFormLocked;
  double get _totalAmount => _cubit.state.totalAmount;

  @override
  void initState() {
    super.initState();
    _cubit.initialize(widget.initialInvoiceData);
    final note = widget.initialInvoiceData?['internalNote'];
    if (note is String) _internalNoteController.text = note;
  }

  @override
  void dispose() {
    _internalNoteController.dispose();
    _isSubmitting.dispose();
    _cubit.close();
    super.dispose();
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
    if (picked != null) onSelected(picked);
  }

  void _addInvoiceItem() => _cubit.addItem();

  void _removeInvoiceItem(int index) => _cubit.removeItem(index);

  void _updateInvoiceItem(
    int index, {
    String? type,
    String? description,
    String? amount,
    String? deduction,
    String? percentage,
    String? currencySign,
  }) {
    _cubit.updateItem(
      index,
      type: type,
      description: description,
      amount: amount,
      deduction: deduction,
      percentage: percentage,
      currencySign: currencySign,
    );
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
    if (_isSubmitting.value) return;
    if (!_validateRequiredFields()) {
      return;
    }
    if (_invoiceItems.every((item) => item.amountController.text.trim().isEmpty)) {
      _showValidationMessage('Please enter at least one invoice item amount');
      return;
    }

    // Build invoice data payload to show on the receipt screen (UI-only)
    final invoiceData = <String, dynamic>{
      'invoiceItems': _invoiceItems
          .map((it) => {
                'type': it.type,
                'description': it.descriptionController.text.trim().isEmpty ? it.description : it.descriptionController.text,
                'currencySign': it.currencySign,
                'amount': it.amountController.text.trim().isEmpty ? it.amount : it.amountController.text,
                'deductionAmt': it.deductionController.text.trim().isEmpty ? it.deductionAmount : it.deductionController.text,
                'percentageAmt': it.percentageController.text.trim().isEmpty ? it.percentageAmount : it.percentageController.text,
              })
          .toList(),
      'internalNote': _internalNoteController.text.trim(),
      'invoiceDate': _dueDate,
      'serviceDate': _serviceStartDate,
      'serviceDateEnd': _serviceEndDate,
    };

    _isSubmitting.value = true;
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      _isSubmitting.value = false;
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
    return BlocProvider<CreateInvoiceCubit>.value(
      value: _cubit,
      child: BlocBuilder<CreateInvoiceCubit, CreateInvoiceState>(
        builder: (context, state) {
          final responsive = ResponsiveHelper(context);
          final isTablet = responsive.isTablet;

          return StaffFormLayout(
            title: 'Create Invoice',
            bottomBar: _buildBottomBar(responsive),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _SelectedStudentsBanner(students: widget.selectedStudents),
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
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(ResponsiveHelper responsive) {
    final safeAreaBottom = MediaQuery.of(context).padding.bottom > 0
        ? MediaQuery.of(context).padding.bottom
        : 16.0;
    return Container(
      padding:
          EdgeInsets.only(bottom: safeAreaBottom, left: 16, right: 16, top: 8),
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
      child: ValueListenableBuilder<bool>(
        valueListenable: _isSubmitting,
        builder: (context, isSubmitting, _) => Container(
          height: responsive.buttonHeight,
          decoration: BoxDecoration(
            gradient: isSubmitting ? null : AppColors.buildPrimaryGradient(),
            color: isSubmitting ? AppColors.billingButtonDisabled : null,
            borderRadius:
                BorderRadius.circular(responsive.isTablet ? 16.0 : 8.0),
          ),
          child: TextButton(
            onPressed: isSubmitting ? null : _handleSubmit,
            child: Text(
              'Save Invoice (UI Only)',
              style: AppTextStyles.button(color: AppColors.billingCardColor)
                  .copyWith(
                fontSize: responsive.buttonFontSize,
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
              onSelected: _cubit.setDueDate,
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
                      _dueDate == null ? 'Select date' : _dateFormat.format(_dueDate!),
                      style: AppTextStyles.value.copyWith(
                        fontSize: isTablet ? 16.0 : 14.0,
                        color: AppColors.billingTextColor,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.calendar_today_outlined, color: AppColors.billingTextColor),
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
                  onSelected: _cubit.setServiceStartDate,
                ),
                child: _DateField(
                  label: _serviceStartDate == null ? 'Select date' : _dateFormat.format(_serviceStartDate!),
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
                  onSelected: _cubit.setServiceEndDate,
                ),
                child: _DateField(
                  label: _serviceEndDate == null ? 'Select date' : _dateFormat.format(_serviceEndDate!),
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
          final isDiscountType = item.type == 'Discount' || item.type == 'Subsidy';
          final descriptionOptions = _descriptionOptionsForType(item.type);
          final String? safeTypeValue =
              _safeDropdownValue(item.type, index == 0 ? _firstItemTypeOptions : _itemTypeOptions);
          final String? safeDescriptionValue =
              _safeDropdownValue(item.description.isEmpty ? null : item.description, descriptionOptions);
          final String? safeUnitValue = _safeDropdownValue(item.currencySign, const ['%', r'$']) ?? '%';
          return Padding(
            padding: EdgeInsets.only(bottom: index == _invoiceItems.length - 1 ? 0 : responsive.verticalSpacing),
            child: Container(
              decoration: BoxDecoration(
                color: index == 0 ? AppColors.billingCardColor : AppColors.billingGreyLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: index == 0 ? AppColors.billingInputBorderFocused : AppColors.billingInputBorderDefault),
              ),
              padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    index == 0 ? 'Primary Item' : 'Additional Item ${index + 1}',
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.billingTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ItemDropdown(
                    label: 'Type',
                    value: safeTypeValue,
                    options: index == 0 ? _firstItemTypeOptions : _itemTypeOptions,
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
                      isEnabled: !_isFormLocked && descriptionOptions.isNotEmpty,
                      hint: descriptionOptions.isEmpty ? 'No items available' : 'Select ${item.type.toLowerCase()}',
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
                      onChanged: (value) => _updateInvoiceItem(index, description: value),
                    ),
                  const SizedBox(height: 12),
                  _ItemTextField(
                    label: 'Amount',
                    controller: item.amountController,
                    enabled: !_isFormLocked && !isDiscountType,
                    hintText: isDiscountType ? 'Calculated' : 'Enter amount',
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _updateInvoiceItem(index, amount: value),
                  ),
                  if (isDiscountType) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: item.currencySign == '%' ? 3 : 1,
                          child: _ItemTextField(
                            label: item.currencySign == '%' ? 'Discount (%)' : 'Discount Amount',
                            controller: item.deductionController,
                            enabled: !_isFormLocked,
                            keyboardType: TextInputType.number,
                            prefixText: item.currencySign == '%' ? null : '\$',
                            onChanged: (value) => _updateInvoiceItem(index, deduction: value),
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
                              onChanged: (value) => _updateInvoiceItem(index, percentage: value),
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
            borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
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
      constraints: BoxConstraints(
        minHeight: isTablet ? 48.0 : 42.0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: _isFormLocked ? null : AppColors.buildPrimaryGradient(),
          color: _isFormLocked ? AppColors.billingInputBackgroundDisabled : null,
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
          icon: Icon(Icons.add, color: AppColors.billingButtonTextColor, size: 18),
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
            borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
          ),
          child: TextField(
            controller: _internalNoteController,
            enabled: !_isFormLocked,
            maxLines: 4,
            minLines: 2,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Add internal note',
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      final description = _effectiveControllerValue(item.descriptionController, fallback: item.description);
      if (description.trim().isEmpty) {
        _showValidationMessage('Please provide a description for invoice item ${index + 1}.');
        return false;
      }

      final amountText = _effectiveControllerValue(item.amountController, fallback: item.amount);
      final isDiscountType = item.type == 'Discount' || item.type == 'Subsidy';
      if (amountText.trim().isEmpty) {
        final label = isDiscountType ? 'deduction' : 'amount';
        _showValidationMessage('Please enter the $label for invoice item ${index + 1}.');
        return false;
      }
    }

    return true;
  }

  String _effectiveControllerValue(TextEditingController controller, {required String fallback}) {
    final text = controller.text.trim();
    return text.isEmpty ? fallback : text;
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
  const _DateField({
    required this.label,
    required this.isTablet,
  });

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
          Icon(Icons.calendar_today_outlined, color: AppColors.billingTextColor),
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
            color: isEnabled ? AppColors.billingBorderLight : AppColors.billingInputBackgroundDisabled,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<String>(
            value: value,
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
