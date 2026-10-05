import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/billing/view_model/ledger_form_cubit.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

const _kCategories = [
  'Income',
  'Expense',
  'Asset',
  'Liability',
  'Equity',
];

class CreateLedgerScreen extends StatefulWidget {
  const CreateLedgerScreen({super.key});

  static const String routeName = '/billing/create-ledger';

  @override
  State<CreateLedgerScreen> createState() => _CreateLedgerScreenState();
}

class _CreateLedgerScreenState extends State<CreateLedgerScreen> {
  final LedgerFormCubit _cubit = serviceLocator<LedgerFormCubit>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? get _selectedCategory => _cubit.state.selectedCategory;
  bool get _isSubmitting => _cubit.state.isSubmitting;
  bool get _titleError => _cubit.state.titleError;
  bool get _categoryError => _cubit.state.categoryError;

  @override
  void dispose() {
    unawaited(_cubit.close());
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final result = await _cubit.submit(
      title: _titleController.text,
      description: _descriptionController.text,
    );
    if (!mounted) return;
    switch (result.status) {
      case LedgerFormStatus.invalid:
        break;
      case LedgerFormStatus.success:
        CoreUtils.showTopSnackBar(
          context: context,
          message: BillingStrings.ledgerCreatedSuccessfully,
          isSuccess: true,
        );
        Navigator.of(context).pop(result.ledger);
      case LedgerFormStatus.error:
        CoreUtils.showTopSnackBar(
          context: context,
          message: BillingStrings.anUnexpectedErrorOccurred,
          isError: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LedgerFormCubit>.value(
      value: _cubit,
      child: BlocBuilder<LedgerFormCubit, LedgerFormState>(
        builder: (context, state) {
          final ResponsiveHelper responsive = ResponsiveHelper(context);
          final double verticalSpacing = responsive.isTablet ? 24.0 : 16.0;
          final TextStyle labelStyle = AppTextStyles.label.copyWith(
            fontSize: responsive.labelFontSize,
            color: AppColors.billingTextColor,
          );

          return StaffFormLayout(
            title: BillingStrings.createLedger,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildInputField(
                  label: BillingStrings.title,
                  hint: BillingStrings.ledgerAccountOperationalExp,
                  controller: _titleController,
                  error: _titleError ? BillingStrings.thisFieldIsRequired : null,
                  labelStyle: labelStyle,
                  responsive: responsive,
                ),
                SizedBox(height: verticalSpacing),

                // ── Category dropdown ──────────────────────────────────
                CustomDropdown(
                  label: BillingStrings.type,
                  hintText: BillingStrings.selectType,
                  items: _kCategories,
                  selectedItem: _selectedCategory,
                  isRequired: true,
                  showAsterisk: true,
                  labelStyle: labelStyle,
                  fieldHeight: responsive.inputFieldHeight,
                  onSelect: (val) => _cubit.setCategory(val),
                ),
                if (_categoryError) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      BillingStrings.thisFieldIsRequired,
                      style: AppTextStyles.small
                          .copyWith(color: AppColors.errorColor),
                    ),
                  ),
                ],
                SizedBox(height: verticalSpacing),

                _buildInputField(
                  label: BillingStrings.description,
                  hint: BillingStrings.descriptionBooksActivitiesPostage,
                  controller: _descriptionController,
                  maxLines: 3,
                  required: false,
                  labelStyle: labelStyle,
                  responsive: responsive,
                ),
                SizedBox(height: verticalSpacing),
              ],
            ),
            bottomBar: CustomButtonLayout(
              confirmButtonLabel: BillingStrings.save,
              onPressedConfirm: _onSave,
              showCancelButton: false,
              isForm: false,
              isLoading: _isSubmitting,
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required TextStyle labelStyle,
    required ResponsiveHelper responsive,
    int maxLines = 1,
    String? error,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: [
              TextSpan(text: label),
              if (required)
                TextSpan(
                  text: ' *',
                  style: AppTextStyles.small.copyWith(color: AppColors.errorColor),
                ),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
          decoration: BoxDecoration(
            color: AppColors.billingCardColor,
            border: Border.all(color: AppColors.billingBorderHeavy),
            borderRadius:
                BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: labelStyle.copyWith(color: AppColors.billingGrey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 2.0),
            child: Text(
              error,
              style: AppTextStyles.small.copyWith(color: AppColors.errorColor),
            ),
          ),
      ],
    );
  }
}
