import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/billing/usecases/create_discount_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/update_discount_usecase.dart';
import 'package:wowcare/presentation/features/billing/cubit/discount_form_cubit.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class AddDiscountScreen extends StatefulWidget {
  const AddDiscountScreen({super.key});

  @override
  State<AddDiscountScreen> createState() => _AddDiscountScreenState();
}

class _AddDiscountScreenState extends State<AddDiscountScreen> {
  late final DiscountFormCubit _cubit = DiscountFormCubit(
    createDiscountUseCase: GetIt.instance<CreateDiscountUseCase>(),
    updateDiscountUseCase: GetIt.instance<UpdateDiscountUseCase>(),
    storageService: GetIt.instance<StorageService>(),
  );

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _percentageController =
      TextEditingController(text: '0');

  @override
  void dispose() {
    unawaited(_cubit.close());
    _nameController.dispose();
    _percentageController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final result = await _cubit.submit(
      name: _nameController.text,
      percentageStr: _percentageController.text,
    );
    if (!mounted) return;
    switch (result.status) {
      case DiscountFormStatus.invalid:
        break;
      case DiscountFormStatus.success:
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Discount created successfully!',
          isSuccess: true,
        );
        Navigator.of(context).pop(result.discount);
      case DiscountFormStatus.error:
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'An unexpected error occurred. Please try again.',
          isError: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DiscountFormCubit>.value(
      value: _cubit,
      child: BlocBuilder<DiscountFormCubit, DiscountFormState>(
        builder: (context, state) {
          final responsive = ResponsiveHelper(context);
          final double spacing = responsive.isTablet ? 24.0 : 16.0;
          final double bottomPadding = MediaQuery.of(context).padding.bottom;
          final double safeBottom = bottomPadding > 0 ? bottomPadding : 16.0;
          final TextStyle labelStyle = AppTextStyles.label.copyWith(
            fontSize: responsive.labelFontSize,
            color: AppColors.billingTextColor,
          );

          return StaffFormLayout(
            title: 'Add Discount',
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildField(
                  label: 'Discount Name',
                  hint: 'e.g., Sibling discount',
                  controller: _nameController,
                  error: state.nameError ? '*This field is required.' : null,
                  labelStyle: labelStyle,
                  responsive: responsive,
                ),
                SizedBox(height: spacing),
                _buildField(
                  label: 'Percentage (%)',
                  hint: '0',
                  controller: _percentageController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d{0,3}(\.\d{0,2})?')),
                  ],
                  error: state.percentageError
                      ? '*Enter a value between 0 and 100.'
                      : null,
                  labelStyle: labelStyle,
                  responsive: responsive,
                ),
                SizedBox(height: spacing),
              ],
            ),
            bottomBar: Container(
              padding: EdgeInsets.only(
                bottom: safeBottom,
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
                confirmButtonLabel: 'Save',
                onPressedConfirm: _onSave,
                showCancelButton: false,
                isForm: false,
                isLoading: state.isSubmitting,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required TextStyle labelStyle,
    required ResponsiveHelper responsive,
    int maxLines = 1,
    String? error,
    bool required = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
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
                  style: AppTextStyles.small
                      .copyWith(color: AppColors.errorColor),
                ),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints:
              BoxConstraints(minHeight: responsive.inputFieldHeight),
          decoration: BoxDecoration(
            color: AppColors.billingCardColor,
            border: Border.all(color: AppColors.billingBorderHeavy),
            borderRadius: BorderRadius.circular(
                responsive.isTablet ? 12.0 : 8.0),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
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
              style: AppTextStyles.small
                  .copyWith(color: AppColors.errorColor),
            ),
          ),
      ],
    );
  }
}
