import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/billing/cubit/ledger_form_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

class CreateLedgerScreen extends StatefulWidget {
  const CreateLedgerScreen({super.key});

  @override
  State<CreateLedgerScreen> createState() => _CreateLedgerScreenState();
}

class _CreateLedgerScreenState extends State<CreateLedgerScreen> {
  late final LedgerFormCubit _cubit = LedgerFormCubit();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<String> _types = const [
    '(Legacy) Subsidy/Agency',
    'Expense Tracking',
    'General',
  ];

  // Read-only proxies onto the cubit's form state.
  String? get _selectedType => _cubit.state.selectedType;
  bool get _isSubmitting => _cubit.state.isSubmitting;
  bool get _titleError => _cubit.state.titleError;
  bool get _typeError => _cubit.state.typeError;

  @override
  void dispose() {
    _cubit.close();
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
          message: 'Ledger created successfully!',
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;
    final bool isLargeTablet = screenWidth > 900;
    final double containerWidth = isLargeTablet
        ? (screenWidth * 0.8).clamp(800.0, 1200.0)
        : isTablet
            ? screenWidth * 0.9
            : screenWidth - 32.0;
    final double horizontalSpacing = isLargeTablet
        ? (screenWidth * 0.1).clamp(32.0, 64.0)
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
        backgroundColor: AppColors.billingCardColor,
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.buildScaffoldGradient(),
                ),
              ),
            ),
            Positioned.fill(
              child: Image.asset(
                MediaRes.wowcareMobileBg,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                opacity: const AlwaysStoppedAnimation(0.08),
              ),
            ),
            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                const SliverToBoxAdapter(
                  child: CustomAppBar(hasBackButton: true),
                ),
              ],
              body: Column(
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalSpacing),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Create Ledger',
                        style: AppTextStyles.title.copyWith(
                          fontSize: responsive.titleFontSize,
                          color: AppColors.billingTextColor,
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
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildInputField(
                            label: 'Title',
                            hint: 'Ledger Account (e.g Operational Exp)',
                            controller: _titleController,
                            error: _titleError
                                ? '*This field is required.'
                                : null,
                          ),
                          SizedBox(height: verticalSpacing),
                          _buildDropdownField(
                            label: 'Type',
                            value: _selectedType,
                            items: _types,
                            onChanged: (val) => _cubit.setType(val),
                            error:
                                _typeError ? '*This field is required.' : null,
                          ),
                          SizedBox(height: verticalSpacing),
                          _buildInputField(
                            label: 'Description',
                            hint:
                                'Description (e.g Books, Activities, Postage)',
                            controller: _descriptionController,
                            maxLines: 3,
                            required: false,
                          ),
                          SizedBox(height: verticalSpacing),
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
            color: AppColors.billingCardColor,
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
              gradient: _isSubmitting
                  ? null
                  : AppColors.buildPrimaryGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              color: _isSubmitting ? AppColors.billingButtonDisabled : null,
              borderRadius:
                  BorderRadius.circular(responsive.isTablet ? 16.0 : 8.0),
            ),
            child: TextButton(
              onPressed: _isSubmitting ? null : _onSave,
              child: Text(
                _isSubmitting ? 'Saving...' : 'Save',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: responsive.buttonFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.billingCardColor,
                ),
              ),
            ),
          ),
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
    int maxLines = 1,
    String? error,
    bool required = true,
  }) {
    final ResponsiveHelper responsive = ResponsiveHelper(context);
    final TextStyle labelStyle = AppTextStyles.label.copyWith(
      fontSize: responsive.labelFontSize,
      color: AppColors.billingTextColor,
    );

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

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? error,
  }) {
    final ResponsiveHelper responsive = ResponsiveHelper(context);
    final TextStyle labelStyle = AppTextStyles.label.copyWith(
      fontSize: responsive.labelFontSize,
      color: AppColors.billingTextColor,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: [
              TextSpan(text: label),
              TextSpan(text: ' *', style: AppTextStyles.small.copyWith(color: AppColors.errorColor)),
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
          child: DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            hint: Text(
              'Select Type',
              style: labelStyle.copyWith(color: Colors.grey),
            ),
            items: items
                .map(
                  (type) => DropdownMenuItem<String>(
                    value: type,
                    child: Text(type, style: labelStyle),
                  ),
                )
                .toList(),
            onChanged: onChanged,
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


