import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/presentation/features/billing/view_model/auto_pay_new_method_cubit.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/core/utils/billing_school_time.dart';

class AutoPayNewMethodScreen extends StatefulWidget {
  const AutoPayNewMethodScreen({super.key});

  static const String routeName = '/auto-pay-new-method';

  @override
  State<AutoPayNewMethodScreen> createState() => _AutoPayNewMethodScreenState();
}

class _AutoPayNewMethodScreenState extends State<AutoPayNewMethodScreen> {
  static const Color _primary = AppColors.billingTextColor;
  static const Color _infoBg = AppColors.billingInfoBannerBackground;

  late final AutoPayNewMethodCubit _cubit = AutoPayNewMethodCubit();

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _routingNumberController = TextEditingController();

  // Read-only proxies onto the cubit's form state.
  String get _paymentMethod => _cubit.state.paymentMethod;
  String get _expMonth => _cubit.state.expMonth;
  String get _expYear => _cubit.state.expYear;
  String get _accountType => _cubit.state.accountType;
  bool get _isSaving => _cubit.state.isSaving;
  Map<String, String> get _fieldErrors => _cubit.state.fieldErrors;

  bool get _isCard => _cubit.state.isCard;
  bool get _showCardFields => _cubit.state.showCardFields;
  bool get _showEcheckFields => _cubit.state.showEcheckFields;
  bool get _showInfoBlock => _cubit.state.showInfoBlock;
  bool get _isSubmitEnabled {
    if (_paymentMethod.isEmpty) return false;
    if (_isCard) {
      return _cardNumberController.text.trim().isNotEmpty &&
          _expMonth.isNotEmpty &&
          _expYear.isNotEmpty &&
          _cvvController.text.trim().isNotEmpty;
    }
    return _accountNumberController.text.trim().isNotEmpty &&
        _routingNumberController.text.trim().isNotEmpty &&
        _accountType.isNotEmpty;
  }

  @override
  void dispose() {
    _cubit.close();
    _cardNumberController.dispose();
    _cvvController.dispose();
    _accountNumberController.dispose();
    _routingNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AutoPayNewMethodCubit>.value(
      value: _cubit,
      child: BlocBuilder<AutoPayNewMethodCubit, AutoPayNewMethodState>(
        builder: (context, state) {
    final responsive = ResponsiveHelper(context);
    final months = List<String>.generate(12, (i) => '${i + 1}'.padLeft(2, '0'));
    final currentYear = billingSchoolCurrentYear();
    final years = List<String>.generate(20, (i) => '${currentYear + i}');

    return StaffFormLayout(
      title: BillingStrings.setAutoPayment,
      bottomBar: Container(
        padding: EdgeInsets.only(
          bottom: (MediaQuery.of(context).padding.bottom > 0)
              ? MediaQuery.of(context).padding.bottom
              : 16,
          left: 16,
          right: 16,
          top: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.billingCardColor,
          boxShadow: [
            BoxShadow(
              color: AppColors.blackColor.withValues(alpha: 0.05),
              offset: const Offset(0, -4),
              blurRadius: 16,
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: ListenableBuilder(
          // Re-evaluate the Save button as the user types (the enabled state is
          // derived from the controllers); the cubit drives error/loading state.
          listenable: Listenable.merge(<Listenable>[
            _cardNumberController,
            _cvvController,
            _accountNumberController,
            _routingNumberController,
          ]),
          builder: (context, _) => AbsorbPointer(
            absorbing: !_isSubmitEnabled,
            child: Opacity(
              opacity: _isSubmitEnabled ? 1 : 0.6,
              child: CustomButtonLayout(
                confirmButtonLabel: BillingStrings.saveDetails,
                onPressedConfirm: _onSaveDetails,
                showCancelButton: false,
                isForm: false,
                isLoading: _isSaving,
              ),
            ),
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            0,
            4,
            0,
            responsive.isTablet ? 24 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                        CustomDropdown(
                          label: BillingStrings.paymentMethod,
                          hintText: BillingStrings.selectPaymentMethod,
                          items: const [BillingStrings.visa, BillingStrings.masterCard, BillingStrings.discover, BillingStrings.ach],
                          selectedItem: _selectedPaymentMethodLabel(),
                          labelStyle: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: responsive.labelFontSize,
                            fontWeight: FontWeight.w400,
                            color: _primary,
                          ),
                          labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                          fieldHeight: responsive.isTablet ? 64.0 : 56.0,
                          selectedTextStyle: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: responsive.inputFontSize,
                            fontWeight: FontWeight.w600,
                            color: _primary,
                            height: 19 / 14,
                          ),
                          popupItemTextStyle: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: responsive.inputFontSize,
                            fontWeight: FontWeight.w400,
                            color: _primary,
                          ),
                          onSelect: (value) => _cubit.setPaymentMethod(value),
                        ),
                        _buildFieldError('paymentMethod'),
                        const SizedBox(height: 8),
                        if (_paymentMethod.isNotEmpty) _buildFeeMessage(),
                        if (_showCardFields) ...[
                          const SizedBox(height: 16),
                          _buildLabel(BillingStrings.cardNumber, required: true),
                          _buildInput(
                            controller: _cardNumberController,
                            hint: BillingStrings.enterCardNumber,
                            keyboardType: TextInputType.number,
                            maxLength: 19,
                          ),
                          _buildFieldError('cardNumber'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomDropdown(
                                      label: BillingStrings.expirationMonth,
                                      hintText: BillingStrings.month,
                                      items: months,
                                      selectedItem:
                                          _expMonth.isEmpty ? null : _expMonth,
                                      labelStyle: TextStyle(
                                        fontFamily: AppFonts.body,
                                        fontSize: responsive.labelFontSize,
                                        fontWeight: FontWeight.w400,
                                        color: _primary,
                                      ),
                                      labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                                      fieldHeight: responsive.isTablet ? 64.0 : 56.0,
                                      selectedTextStyle: TextStyle(
                                        fontFamily: AppFonts.body,
                                        fontSize: responsive.inputFontSize,
                                        fontWeight: FontWeight.w600,
                                        color: _primary,
                                        height: 19 / 14,
                                      ),
                                      onSelect: (value) =>
                                          _cubit.setExpMonth(value),
                                    ),
                                    _buildFieldError('expMonth'),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomDropdown(
                                      label: BillingStrings.expirationYear,
                                      hintText: BillingStrings.year,
                                      items: years,
                                      selectedItem:
                                          _expYear.isEmpty ? null : _expYear,
                                      labelStyle: TextStyle(
                                        fontFamily: AppFonts.body,
                                        fontSize: responsive.labelFontSize,
                                        fontWeight: FontWeight.w400,
                                        color: _primary,
                                      ),
                                      labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                                      fieldHeight: responsive.isTablet ? 64.0 : 56.0,
                                      selectedTextStyle: TextStyle(
                                        fontFamily: AppFonts.body,
                                        fontSize: responsive.inputFontSize,
                                        fontWeight: FontWeight.w600,
                                        color: _primary,
                                        height: 19 / 14,
                                      ),
                                      onSelect: (value) =>
                                          _cubit.setExpYear(value),
                                    ),
                                    _buildFieldError('expYear'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildLabel(BillingStrings.cvv, required: true),
                          _buildInput(
                            controller: _cvvController,
                            hint: BillingStrings.enterCvv,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                          ),
                          _buildFieldError('cvv'),
                        ],
                        if (_showEcheckFields) ...[
                          const SizedBox(height: 16),
                          _buildLabel(BillingStrings.accountNumber, required: true),
                          _buildInput(
                            controller: _accountNumberController,
                            hint: BillingStrings.enterAccountNumber,
                            keyboardType: TextInputType.number,
                            maxLength: 17,
                          ),
                          _buildFieldError('accountNumber'),
                          const SizedBox(height: 12),
                          _buildLabel(BillingStrings.routingNumber, required: true),
                          _buildInput(
                            controller: _routingNumberController,
                            hint: BillingStrings.enterRoutingNumber,
                            keyboardType: TextInputType.number,
                            maxLength: 9,
                          ),
                          _buildFieldError('routingNumber'),
                          const SizedBox(height: 12),
                          CustomDropdown(
                            label: BillingStrings.accountType,
                            hintText: BillingStrings.selectAccountType,
                            items: const [BillingStrings.checking, BillingStrings.savings],
                            selectedItem: _selectedAccountTypeLabel(),
                            labelStyle: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: responsive.labelFontSize,
                              fontWeight: FontWeight.w400,
                              color: _primary,
                            ),
                            labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                            fieldHeight: responsive.isTablet ? 64.0 : 56.0,
                            selectedTextStyle: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: responsive.inputFontSize,
                              fontWeight: FontWeight.w600,
                              color: _primary,
                              height: 19 / 14,
                            ),
                            onSelect: (value) => _cubit.setAccountType(value),
                          ),
                          _buildFieldError('accountType'),
                        ],
                        if (_showInfoBlock) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _infoBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.billingInfoBannerBorder,
                              ),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: AppColors.billingWarningIconColor,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    BillingStrings.yourCurrentOutstandingBalance,
                                    style: TextStyle(
                                      fontFamily: AppFonts.body,
                                      color: AppColors.billingInfoBannerTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_isSaving)
                          const Center(
                            child: Text(
                              BillingStrings.pleaseWaitProcessingYour,
                              style: TextStyle(
                                color: AppColors.billingMutedSlateText,
                                fontSize: 12,
                              ),
                            ),
                          ),
            ],
          ),
        ),
      ),
    );
        },
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    final responsive = ResponsiveHelper(context);
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.isTablet ? 8.0 : 6.0),
      child: RichText(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: responsive.labelFontSize,
            fontWeight: FontWeight.w400,
            color: _primary,
          ),
          children: required
              ? const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: AppColors.errorColor),
                  ),
                ]
              : const [],
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
    required int maxLength,
  }) {
    final responsive = ResponsiveHelper(context);
    return Container(
      constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
      decoration: BoxDecoration(
        color: AppColors.billingCardColor,
        border: Border.all(color: AppColors.billingBorderDefault),
        borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
      inputFormatters: _inputFormattersFor(keyboardType),
      onChanged: (_) {
        // The Save button rebuilds reactively via ListenableBuilder on the
        // controllers; here we just clear the relevant cubit field error.
        if (controller == _cardNumberController) {
          _cubit.clearFieldError('cardNumber');
        } else if (controller == _cvvController) {
          _cubit.clearFieldError('cvv');
        } else if (controller == _accountNumberController) {
          _cubit.clearFieldError('accountNumber');
        } else if (controller == _routingNumberController) {
          _cubit.clearFieldError('routingNumber');
        }
      },
        style: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: responsive.inputFontSize,
          fontWeight: FontWeight.w600,
          color: _primary,
          height: 19 / 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: responsive.labelFontSize,
            fontWeight: FontWeight.w400,
            color: AppColors.billingGrey,
          ),
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: responsive.isTablet ? 16.0 : 12.0,
            vertical: responsive.isTablet ? 16.0 : 12.0,
          ),
        ),
      ),
    );
  }

  List<TextInputFormatter>? _inputFormattersFor(TextInputType keyboardType) {
    if (keyboardType == TextInputType.number) {
      return <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ];
    }
    return null;
  }

  Widget _buildFieldError(String key) {
    final message = _fieldErrors[key];
    return CoreUtils.buildInlineFieldError(message);
  }

  String? _selectedPaymentMethodLabel() {
    const map = <String, String>{
      'visa': BillingStrings.visa,
      'mast': BillingStrings.masterCard,
      'disc': BillingStrings.discover,
      'echeck': BillingStrings.ach,
    };
    return map[_paymentMethod];
  }

  String? _selectedAccountTypeLabel() {
    switch (_accountType.toLowerCase()) {
      case 'checking':
        return BillingStrings.checking;
      case 'savings':
        return BillingStrings.savings;
      default:
        return null;
    }
  }

  Widget _buildFeeMessage() {
    final map = <String, String>{
      'visa': BillingStrings.visa,
      'mast': BillingStrings.masterCard,
      'disc': BillingStrings.discover,
      'echeck': BillingStrings.achBankTransfer,
    };
    final methodLabel = map[_paymentMethod] ?? BillingStrings.card;
    final feeText = _paymentMethod == 'echeck'
        ? '$methodLabel - \$1.00 convenience fee will be applied'
        : '$methodLabel - 3% convenience fee will be applied';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.billingFeeBannerBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.billingFeeBannerBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.billingWarningIconColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feeText,
              style: const TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 12,
                color: AppColors.billingFeeBannerTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSaveDetails() async {
    if (_isSaving) return;
    final isValid = _cubit.validate(
      cardNumber: _cardNumberController.text,
      cvv: _cvvController.text,
      accountNumber: _accountNumberController.text,
      routingNumber: _routingNumberController.text,
    );
    if (!isValid) {
      final firstError = _fieldErrors.values.isNotEmpty
          ? _fieldErrors.values.first
          : BillingStrings.pleaseCheckTheForm;
      CoreUtils.showTopSnackBar(
        context: context,
        message: firstError,
        isWarning: true,
      );
      return;
    }

    await _cubit.save();

    if (!mounted) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: BillingStrings.secureTokenCreatedSuccessfully,
      isSuccess: true,
    );
  }
}
