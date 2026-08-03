import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/billing/usecases/create_ledger_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/update_ledger_usecase.dart';
import 'package:wowcare/presentation/features/billing/cubit/ledger_form_cubit.dart';
import 'package:wowcare/presentation/features/billing/widgets/general_ledger/models/ledger_account_model.dart';
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

class EditLedgerScreen extends StatefulWidget {
  const EditLedgerScreen({required this.ledger, super.key});

  final LedgerAccountModel ledger;

  @override
  State<EditLedgerScreen> createState() => _EditLedgerScreenState();
}

class _EditLedgerScreenState extends State<EditLedgerScreen> {
  late final LedgerFormCubit _cubit;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? get _selectedCategory => _cubit.state.selectedCategory;
  bool get _isSubmitting => _cubit.state.isSubmitting;
  bool get _isLoading => _cubit.state.isLoading;
  bool get _titleError => _cubit.state.titleError;
  bool get _categoryError => _cubit.state.categoryError;

  @override
  void initState() {
    super.initState();
    // Pre-select category if it matches one of the known options
    final initialCategory = widget.ledger.category?.isNotEmpty == true &&
            _kCategories.contains(widget.ledger.category)
        ? widget.ledger.category
        : null;
    _cubit = LedgerFormCubit(
      initialCategory: initialCategory,
      createLedgerUseCase: GetIt.instance<CreateLedgerUseCase>(),
      updateLedgerUseCase: GetIt.instance<UpdateLedgerUseCase>(),
      storageService: GetIt.instance<StorageService>(),
    );
    _titleController.text = widget.ledger.name;
    _descriptionController.text = widget.ledger.description ?? '';
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final result = await _cubit.submit(
      original: widget.ledger,
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
          message: 'Ledger updated successfully!',
          isSuccess: true,
        );
        Navigator.of(context).pop(result.ledger);
      case LedgerFormStatus.error:
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'An unexpected error occurred. Please try again.',
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
          final double bottomPadding = MediaQuery.of(context).padding.bottom;
          final double safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
          final TextStyle labelStyle = AppTextStyles.label.copyWith(
            fontSize: responsive.labelFontSize,
            color: AppColors.billingTextColor,
          );

          return StaffFormLayout(
            title: 'Edit Ledger',
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildInputField(
                        label: 'Title',
                        hint: 'Ledger Account (e.g Operational Exp)',
                        controller: _titleController,
                        error: _titleError ? '*This field is required.' : null,
                        labelStyle: labelStyle,
                        responsive: responsive,
                      ),
                      SizedBox(height: verticalSpacing),

                      // ── Category dropdown ────────────────────────────
                      CustomDropdown(
                        label: 'Type',
                        hintText: 'Select Type',
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
                            '*This field is required.',
                            style: AppTextStyles.small
                                .copyWith(color: AppColors.errorColor),
                          ),
                        ),
                      ],
                      SizedBox(height: verticalSpacing),

                      _buildInputField(
                        label: 'Description',
                        hint: 'Description (e.g Books, Activities, Postage)',
                        controller: _descriptionController,
                        maxLines: 3,
                        required: false,
                        labelStyle: labelStyle,
                        responsive: responsive,
                      ),
                      SizedBox(height: verticalSpacing),
                    ],
                  ),
            bottomBar: _isLoading
                ? const SizedBox.shrink()
                : Container(
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
                          color: Colors.black.withValues(alpha: 0.05),
                          offset: const Offset(0, -4),
                          blurRadius: 16,
                        ),
                      ],
                      borderRadius: BorderRadius.only(
                        topLeft:
                            Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                        topRight:
                            Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                      ),
                    ),
                    child: CustomButtonLayout(
                      confirmButtonLabel: 'Update',
                      onPressedConfirm: _onSave,
                      showCancelButton: false,
                      isForm: false,
                      isLoading: _isSubmitting,
                    ),
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
                  style:
                      AppTextStyles.small.copyWith(color: AppColors.errorColor),
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
