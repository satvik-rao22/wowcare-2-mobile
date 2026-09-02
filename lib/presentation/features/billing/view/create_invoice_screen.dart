import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/billing/cubit/create_invoice_cubit.dart';
import 'package:wowcare/presentation/features/billing/model/student_models.dart';
import 'package:wowcare/presentation/features/billing/view/selected_students_receipt_screen.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

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
  late final CreateInvoiceCubit _cubit = serviceLocator<CreateInvoiceCubit>();
  final TextEditingController _internalNoteController = TextEditingController();

  /// Local, mutable copy so a student can be removed from this invoice.
  late List<Student> _students;

  final ValueNotifier<bool> _isSubmitting = ValueNotifier<bool>(false);

  // Read-only proxies onto the cubit state.
  List<InvoiceItemFormData> get _invoiceItems => _cubit.state.items;
  DateTime? get _invoiceDate => _cubit.state.invoiceDate;
  DateTime? get _dueDate => _cubit.state.dueDate;
  DateTime? get _serviceDate => _cubit.state.serviceDate;
  DateTime? get _serviceDateEnd => _cubit.state.serviceDateEnd;
  bool get _isFormLocked => _cubit.state.isFormLocked;
  double get _totalAmount => _cubit.state.totalAmount;

  @override
  void initState() {
    super.initState();
    _students = List<Student>.of(widget.selectedStudents);
    final editCode =
        widget.initialInvoiceData?['invoiceCode']?.toString().trim() ?? '';
    if (editCode.isNotEmpty) {
      // Edit: fetch the real invoice (by-code) and hydrate the form.
      _cubit.loadInvoiceForEdit(editCode);
    } else {
      _cubit.initialize(widget.initialInvoiceData);
    }
    final note = widget.initialInvoiceData?['internalNote'];
    if (note is String) _internalNoteController.text = note;
  }

  void _removeStudent(Student student) {
    // An invoice always needs at least one student — block removing the last one.
    if (_students.length <= 1) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'At least one student must be selected.',
        isWarning: true,
      );
      return;
    }
    setState(() => _students.remove(student));
  }

  @override
  void dispose() {
    _internalNoteController.dispose();
    _isSubmitting.dispose();
    _cubit.close();
    super.dispose();
  }

  void _addInvoiceItem() => _cubit.addItem();

  void _removeInvoiceItem(int index) => _cubit.removeItem(index);

  void _updateInvoiceItem(
    int index, {
    String? type,
    String? description,
    String? amount,
    String? value,
    String? valueType,
  }) {
    _cubit.updateItem(
      index,
      type: type,
      description: description,
      amount: amount,
      value: value,
      valueType: valueType,
    );
  }

  /// Catalog-backed Item Description options for [type] (empty for New Item,
  /// or while the catalog is still loading).
  List<String> _descriptionOptionsForType(String type) {
    if (!InvoiceItemTypes.catalogTypes.contains(type)) return const [];
    return _cubit.state.catalog[type]?.map((o) => o.label).toList() ??
        const [];
  }

  /// Step 2 → Step 3: validate the form, then open the invoice preview. The
  /// actual Save / Save & Send happens on the preview screen via [_submitInvoice].
  Future<void> _openPreview() async {
    if (_isSubmitting.value) return;
    if (!_validateRequiredFields()) return;
    if (_invoiceItems
        .every((item) => item.amountController.text.trim().isEmpty)) {
      _showValidationMessage('Please enter at least one invoice item amount');
      return;
    }

    final invoiceData = <String, dynamic>{
      'invoiceItems': _invoiceItems
          .map((it) => {
                'type': it.type,
                'description': it.descriptionController.text.trim().isEmpty
                    ? it.description
                    : it.descriptionController.text,
                'amount': it.amountController.text.trim().isEmpty
                    ? it.amount
                    : it.amountController.text,
              })
          .toList(),
      'internalNote': _internalNoteController.text.trim(),
      'invoiceDate': _invoiceDate,
      'dueDate': _dueDate,
      'serviceDate': _serviceDate,
      'serviceDateEnd': _serviceDateEnd,
    };

    _isSubmitting.value = true;
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectedStudentsReceiptScreen(
          selectedStudents: _students,
          invoiceData: invoiceData,
          onSubmit: _submitInvoice,
        ),
      ),
    );
    if (!mounted) return;
    _isSubmitting.value = false;
    // Preview reported a successful save — close this step too so the flow
    // returns to the billing list.
    if (submitted == true) {
      Navigator.of(context).pop(true);
    }
  }

  /// Performs the real save from the preview step. [students] is the list as
  /// trimmed on the preview (a student may have been removed there). Returns
  /// true on success.
  Future<bool> _submitInvoice(String mode, List<Student> students) async {
    final result = await _cubit.submitInvoices(
      students: students,
      mode: mode,
      notes: _internalNoteController.text.trim(),
    );
    if (!mounted) return false;
    if (!result.success) {
      _showValidationMessage(result.error ?? 'Could not create the invoice.');
      return false;
    }
    CoreUtils.showTopSnackBar(
      context: context,
      message: mode == 'send'
          ? 'Invoice created & sent for ${result.created} student(s).'
          : 'Invoice saved as draft for ${result.created} student(s).',
      isSuccess: true,
    );
    return true;
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
                _SelectedStudentsBanner(
                  students: _students,
                  onRemove: _isFormLocked ? null : _removeStudent,
                ),
                SizedBox(height: responsive.verticalSpacing),
                _buildDateField(
                  responsive: responsive,
                  label: 'Invoice Due Date',
                  value: _dueDate,
                  onSelected: _cubit.setDueDate,
                ),
                SizedBox(height: responsive.verticalSpacing),
                _buildServiceDateRange(responsive),
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
        builder: (context, isSubmitting, _) {
          final radius =
              BorderRadius.circular(responsive.isTablet ? 16.0 : 8.0);
          // Step 2 of 3 → continue to the invoice preview, where Save / Save &
          // Send finalize the invoice.
          return Container(
            height: responsive.buttonHeight,
            decoration: BoxDecoration(
              gradient:
                  isSubmitting ? null : AppColors.buildPrimaryGradient(),
              color: isSubmitting ? AppColors.billingButtonDisabled : null,
              borderRadius: radius,
            ),
            child: TextButton(
              onPressed: isSubmitting ? null : _openPreview,
              child: Text(
                'Preview Invoice',
                style: AppTextStyles.button(color: AppColors.billingCardColor)
                    .copyWith(fontSize: responsive.buttonFontSize),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Dates ────────────────────────────────────────────────────────────────

  /// Field label style matching the Add Staff form (Manrope, responsive size).
  TextStyle _formLabelStyle(ResponsiveHelper responsive) => TextStyle(
        fontSize: responsive.labelFontSize,
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w400,
        color: const Color(0xff573353),
      );

  Widget _buildDateField({
    required ResponsiveHelper responsive,
    String? label,
    required DateTime? value,
    required ValueChanged<DateTime?> onSelected,
    bool isRequired = true,
  }) {
    return CustomDateTimeField(
      label: label,
      isRequired: isRequired,
      labelStyle: _formLabelStyle(responsive),
      fetchInitialTime: false,
      initialDate: value,
      onDateSelected: (date) => onSelected(date),
    );
  }

  /// Optional "Date of Service" period (start → end), matching the web flow.
  Widget _buildServiceDateRange(ResponsiveHelper responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date of Service (Optional)', style: _formLabelStyle(responsive)),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _buildDateField(
                responsive: responsive,
                value: _serviceDate,
                onSelected: _cubit.setServiceDate,
                isRequired: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('to', style: _formLabelStyle(responsive)),
            ),
            Expanded(
              child: _buildDateField(
                responsive: responsive,
                value: _serviceDateEnd,
                onSelected: _cubit.setServiceDateEnd,
                isRequired: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Invoice items ────────────────────────────────────────────────────────────

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
                  fontWeight: FontWeight.w600,
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
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _invoiceItems.length - 1
                  ? 0
                  : responsive.verticalSpacing,
            ),
            child: _buildItemCard(index, item, responsive, isTablet),
          );
        }),
        const SizedBox(height: 12),
        // Total
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: responsive.isTablet ? 16.0 : 13.0,
            horizontal: responsive.isTablet ? 20.0 : 16.0,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(responsive.isTablet ? 12.0 : 10.0),
            color: const Color(0x1AB1AFE9),
            border: Border.all(color: AppColors.billingBorderMedium),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.billingTextColor,
                ),
              ),
              Text(
                '\$${_totalAmount.toStringAsFixed(2)}',
                style: AppTextStyles.title.copyWith(
                  color: AppColors.billingTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(int index, InvoiceItemFormData item,
      ResponsiveHelper responsive, bool isTablet) {
    final isCatalogType = InvoiceItemTypes.catalogTypes.contains(item.type);
    final labelStyle = _formLabelStyle(responsive);
    final labelBottomSpacing = responsive.isTablet ? 8.0 : 6.0;
    final typeOptions = index == 0
        ? InvoiceItemTypes.firstItemOptions
        : InvoiceItemTypes.additionalItemOptions;
    final descriptionOptions = _descriptionOptionsForType(item.type);
    final String? safeTypeValue = _safeDropdownValue(item.type, typeOptions);
    final String? safeDescriptionValue = _safeDropdownValue(
        item.description.isEmpty ? null : item.description, descriptionOptions);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.billingInputBorderDefault),
        boxShadow: [
          BoxShadow(
            color: AppColors.billingShadowColorLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(isTablet ? 18.0 : 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  index == 0 ? 'Item 1' : 'Item ${index + 1}',
                  style: labelStyle.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (index > 0)
                GestureDetector(
                  onTap: () => _removeInvoiceItem(index),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.billingStatusError.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        MediaRes.delete_icon,
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          AppColors.billingStatusError,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          CustomDropdown(
            label: 'Type',
            showAsterisk: false,
            hintText: 'Select type',
            items: typeOptions,
            selectedItem: safeTypeValue,
            isEnabled: !_isFormLocked,
            labelStyle: labelStyle,
            labelBottomSpacing: labelBottomSpacing,
            onSelect: (value) {
              if (value != null) _updateInvoiceItem(index, type: value);
            },
          ),
          const SizedBox(height: 12),
          if (isCatalogType)
            CustomDropdown(
              label: 'Item Description',
              showAsterisk: true,
              hintText: descriptionOptions.isEmpty
                  ? (_cubit.state.catalogLoaded
                      ? 'No ${item.type.toLowerCase()} available'
                      : 'Loading ${item.type.toLowerCase()}…')
                  : 'Select ${item.type.toLowerCase()}',
              items: descriptionOptions,
              selectedItem: safeDescriptionValue,
              isEnabled: !_isFormLocked && descriptionOptions.isNotEmpty,
              labelStyle: labelStyle,
              labelBottomSpacing: labelBottomSpacing,
              onSelect: (value) {
                if (value != null) _updateInvoiceItem(index, description: value);
              },
            )
          else
            _ItemTextField(
              responsive: responsive,
              label: 'Item Description',
              controller: item.descriptionController,
              enabled: !_isFormLocked,
              hintText: 'Enter item description',
              onChanged: (value) =>
                  _updateInvoiceItem(index, description: value),
            ),
          // Discount / subsidy: enter a value and choose % or flat — the amount
          // is computed (% of the fee total, or the flat value).
          if (InvoiceItemTypes.isDeduction(item.type)) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: _ItemTextField(
                    responsive: responsive,
                    label: 'Value',
                    controller: item.valueController,
                    enabled: !_isFormLocked,
                    hintText: '0',
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _updateInvoiceItem(index, value: value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: CustomDropdown(
                    label: 'Type',
                    showAsterisk: false,
                    hintText: '%',
                    items: const ['%', 'Flat'],
                    selectedItem: item.valueType == 'PERCENT' ? '%' : 'Flat',
                    isEnabled: !_isFormLocked,
                    labelStyle: labelStyle,
                    labelBottomSpacing: labelBottomSpacing,
                    onSelect: (value) {
                      if (value != null) {
                        _updateInvoiceItem(
                          index,
                          valueType: value == '%' ? 'PERCENT' : 'FLAT',
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Catalog types auto-fill the amount from the chosen entry. It's
          // read-only (not editable) but kept white — not greyed out.
          _ItemTextField(
            responsive: responsive,
            label: 'Amount',
            controller: item.amountController,
            enabled: !_isFormLocked,
            readOnly: isCatalogType,
            hintText: isCatalogType ? 'Auto-filled' : '\$0',
            keyboardType: TextInputType.number,
            onChanged: (value) => _updateInvoiceItem(index, amount: value),
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemButton(bool isTablet) {
    final borderRadius = BorderRadius.circular(isTablet ? 14.0 : 10.0);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: _isFormLocked ? null : AppColors.buildPrimaryGradient(),
        color: _isFormLocked ? AppColors.billingInputBackgroundDisabled : null,
      ),
      child: TextButton.icon(
        onPressed: _isFormLocked ? null : _addInvoiceItem,
        icon: Icon(Icons.add,
            color: AppColors.billingButtonTextColor, size: 18),
        label: Text(
          'Add Item',
          style: AppTextStyles.label.copyWith(
            fontSize: isTablet ? 15 : 13,
            fontWeight: FontWeight.w600,
            color: AppColors.billingCardColor,
          ),
        ),
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 18.0 : 14.0,
            vertical: 10.0,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildInternalNoteField(ResponsiveHelper responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Internal Note', style: _formLabelStyle(responsive)),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          decoration: BoxDecoration(
            color: AppColors.billingCardColor,
            border: Border.all(color: AppColors.billingBorderHeavy),
            borderRadius:
                BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
          ),
          child: TextField(
            controller: _internalNoteController,
            enabled: !_isFormLocked,
            maxLines: 4,
            minLines: 2,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Add internal note',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    if (_students.isEmpty) {
      _showValidationMessage('Please keep at least one student.');
      return false;
    }
    if (_dueDate == null) {
      _showValidationMessage('Please select the invoice due date.');
      return false;
    }

    for (var index = 0; index < _invoiceItems.length; index++) {
      final item = _invoiceItems[index];
      final description = _effectiveControllerValue(
          item.descriptionController,
          fallback: item.description);
      if (description.trim().isEmpty) {
        _showValidationMessage(
            'Please provide a description for invoice item ${index + 1}.');
        return false;
      }

      final amountText = _effectiveControllerValue(item.amountController,
          fallback: item.amount);
      if (amountText.trim().isEmpty) {
        _showValidationMessage(
            'Please enter the amount for invoice item ${index + 1}.');
        return false;
      }
    }

    return true;
  }

  String _effectiveControllerValue(TextEditingController controller,
      {required String fallback}) {
    final text = controller.text.trim();
    return text.isEmpty ? fallback : text;
  }

  void _showValidationMessage(String message) {
    CoreUtils.showTopSnackBar(
      context: context,
      message: message,
      isError: true,
    );
  }
}

String? _safeDropdownValue(String? value, List<String> options) {
  if (value == null) return null;
  return options.contains(value) ? value : null;
}

class _SelectedStudentsBanner extends StatelessWidget {
  const _SelectedStudentsBanner({required this.students, this.onRemove});

  final List<Student> students;
  final ValueChanged<Student>? onRemove;

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
                    padding: EdgeInsets.only(
                      left: 12,
                      right: onRemove != null ? 6 : 12,
                      top: 6,
                      bottom: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.billingCardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          student.fullName,
                          style: AppTextStyles.small.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.billingTextColor,
                          ),
                        ),
                        if (onRemove != null) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => onRemove!(student),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.billingTextColor
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
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

class _ItemTextField extends StatelessWidget {
  const _ItemTextField({
    required this.responsive,
    required this.label,
    required this.controller,
    this.enabled = true,
    this.readOnly = false,
    this.hintText,
    this.keyboardType,
    this.onChanged,
  });

  final ResponsiveHelper responsive;
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final bool readOnly;
  final String? hintText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    // Mirrors the Add Staff form's input field (label + red asterisk, white
    // background with the themed border, w600 input text).
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: 'Manrope',
      fontWeight: FontWeight.w400,
      color: const Color(0xff573353),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: [
              TextSpan(text: label),
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey.shade200,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius:
                BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            readOnly: readOnly,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.inputFontSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xff573353),
              height: 19 / 14,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: labelStyle.copyWith(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
