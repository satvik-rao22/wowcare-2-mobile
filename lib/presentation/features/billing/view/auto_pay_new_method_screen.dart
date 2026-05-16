import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class AutoPayNewMethodScreen extends StatefulWidget {
  const AutoPayNewMethodScreen({super.key});

  static const String routeName = '/auto-pay-new-method';

  @override
  State<AutoPayNewMethodScreen> createState() => _AutoPayNewMethodScreenState();
}

class _AutoPayNewMethodScreenState extends State<AutoPayNewMethodScreen> {
  static const Color _primary = Color(0xFF573353);
  static const Color _infoBg = Color(0xFFFFF3E0);

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _routingNumberController =
      TextEditingController();

  String _paymentMethod = '';
  String _expMonth = '';
  String _expYear = '';
  String _accountType = '';

  bool _isSaving = false;
  final Map<String, String> _fieldErrors = <String, String>{};

  bool get _isCard =>
      _paymentMethod.isNotEmpty && _paymentMethod.toLowerCase() != 'echeck';

  bool get _showCardFields => _isCard;
  bool get _showEcheckFields =>
      _paymentMethod.isNotEmpty && _paymentMethod.toLowerCase() == 'echeck';
  bool get _showInfoBlock => _paymentMethod.isNotEmpty;
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
    _cardNumberController.dispose();
    _cvvController.dispose();
    _accountNumberController.dispose();
    _routingNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final months = List<String>.generate(12, (i) => '${i + 1}'.padLeft(2, '0'));
    final currentYear = DateTime.now().year;
    final years = List<String>.generate(20, (i) => '${currentYear + i}');

    return StaffFormLayout(
      title: 'Set Auto Payment',
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
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -4),
              blurRadius: 16,
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: AbsorbPointer(
          absorbing: !_isSubmitEnabled,
          child: Opacity(
            opacity: _isSubmitEnabled ? 1 : 0.6,
            child: CustomButtonLayout(
              confirmButtonLabel: 'Save details',
              onPressedConfirm: _onSaveDetails,
              showCancelButton: false,
              isForm: false,
              isLoading: _isSaving,
            ),
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 4, 0, responsive.isTablet ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomDropdown(
                label: 'Payment Method',
                hintText: 'Select Payment Method',
                items: const ['Visa', 'MasterCard', 'Discover', 'ACH'],
                selectedItem: _selectedPaymentMethodLabel(),
                labelStyle: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: responsive.labelFontSize,
                  fontWeight: FontWeight.w400,
                  color: _primary,
                ),
                labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                fieldHeight: responsive.isTablet ? 64.0 : 56.0,
                selectedTextStyle: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: responsive.inputFontSize,
                  fontWeight: FontWeight.w600,
                  color: _primary,
                  height: 19 / 14,
                ),
                popupItemTextStyle: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: responsive.inputFontSize,
                  fontWeight: FontWeight.w400,
                  color: _primary,
                ),
                onSelect: (value) {
                  setState(() {
                    _paymentMethod = _mapMethodLabelToCode(value);
                    _fieldErrors.remove('paymentMethod');
                  });
                },
              ),
              _buildFieldError('paymentMethod'),
              const SizedBox(height: 8),
              if (_paymentMethod.isNotEmpty) _buildFeeMessage(),
              if (_showCardFields) ...[
                const SizedBox(height: 16),
                _buildLabel('Card Number', required: true),
                _buildInput(
                  controller: _cardNumberController,
                  hint: 'Enter card number',
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
                            label: 'Expiration Month',
                            hintText: 'Month',
                            items: months,
                            selectedItem: _expMonth.isEmpty ? null : _expMonth,
                            labelStyle: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: responsive.labelFontSize,
                              fontWeight: FontWeight.w400,
                              color: _primary,
                            ),
                            labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                            fieldHeight: responsive.isTablet ? 64.0 : 56.0,
                            selectedTextStyle: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: responsive.inputFontSize,
                              fontWeight: FontWeight.w600,
                              color: _primary,
                              height: 19 / 14,
                            ),
                            onSelect: (value) => setState(() {
                              _expMonth = value ?? '';
                              _fieldErrors.remove('expMonth');
                            }),
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
                            label: 'Expiration Year',
                            hintText: 'Year',
                            items: years,
                            selectedItem: _expYear.isEmpty ? null : _expYear,
                            labelStyle: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: responsive.labelFontSize,
                              fontWeight: FontWeight.w400,
                              color: _primary,
                            ),
                            labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                            fieldHeight: responsive.isTablet ? 64.0 : 56.0,
                            selectedTextStyle: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: responsive.inputFontSize,
                              fontWeight: FontWeight.w600,
                              color: _primary,
                              height: 19 / 14,
                            ),
                            onSelect: (value) => setState(() {
                              _expYear = value ?? '';
                              _fieldErrors.remove('expYear');
                            }),
                          ),
                          _buildFieldError('expYear'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildLabel('CVV', required: true),
                _buildInput(
                  controller: _cvvController,
                  hint: 'Enter CVV',
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                ),
                _buildFieldError('cvv'),
              ],
              if (_showEcheckFields) ...[
                const SizedBox(height: 16),
                _buildLabel('Account Number', required: true),
                _buildInput(
                  controller: _accountNumberController,
                  hint: 'Enter account number',
                  keyboardType: TextInputType.number,
                  maxLength: 17,
                ),
                _buildFieldError('accountNumber'),
                const SizedBox(height: 12),
                _buildLabel('Routing Number', required: true),
                _buildInput(
                  controller: _routingNumberController,
                  hint: 'Enter routing number',
                  keyboardType: TextInputType.number,
                  maxLength: 9,
                ),
                _buildFieldError('routingNumber'),
                const SizedBox(height: 12),
                CustomDropdown(
                  label: 'Account Type',
                  hintText: 'Select Account Type',
                  items: const ['Checking', 'Savings'],
                  selectedItem: _selectedAccountTypeLabel(),
                  labelStyle: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: responsive.labelFontSize,
                    fontWeight: FontWeight.w400,
                    color: _primary,
                  ),
                  labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                  fieldHeight: responsive.isTablet ? 64.0 : 56.0,
                  selectedTextStyle: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: responsive.inputFontSize,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                    height: 19 / 14,
                  ),
                  onSelect: (value) {
                    setState(() {
                      _accountType = _mapAccountTypeLabelToCode(value);
                      _fieldErrors.remove('accountType');
                    });
                  },
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
                    border: Border.all(color: const Color(0x4DFDB813)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Color(0xFFDD6B20),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your current outstanding balance will be deducted automatically.',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            color: Color(0xFFD97706),
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
                    'Please wait... Processing your payment information.',
                    style: TextStyle(color: Color(0xFF718096), fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
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
            fontFamily: 'Manrope',
            fontSize: responsive.labelFontSize,
            fontWeight: FontWeight.w400,
            color: _primary,
          ),
          children: required
              ? const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red),
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
        color: Colors.white,
        border: Border.all(color: const Color(0x66573353)),
        borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters: _inputFormattersFor(keyboardType),
        onChanged: (_) {
          setState(() {
            if (controller == _cardNumberController) {
              _fieldErrors.remove('cardNumber');
            } else if (controller == _cvvController) {
              _fieldErrors.remove('cvv');
            } else if (controller == _accountNumberController) {
              _fieldErrors.remove('accountNumber');
            } else if (controller == _routingNumberController) {
              _fieldErrors.remove('routingNumber');
            }
          });
        },
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: responsive.inputFontSize,
          fontWeight: FontWeight.w600,
          color: _primary,
          height: 19 / 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Manrope',
            fontSize: responsive.labelFontSize,
            fontWeight: FontWeight.w400,
            color: Colors.grey,
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
      return <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly];
    }
    return null;
  }

  Widget _buildFieldError(String key) {
    final message = _fieldErrors[key];
    return CoreUtils.buildInlineFieldError(message);
  }

  String? _selectedPaymentMethodLabel() {
    const map = <String, String>{
      'visa': 'Visa',
      'mast': 'MasterCard',
      'disc': 'Discover',
      'echeck': 'ACH',
    };
    return map[_paymentMethod];
  }

  String _mapMethodLabelToCode(String? label) {
    switch ((label ?? '').toLowerCase()) {
      case 'visa':
        return 'visa';
      case 'mastercard':
        return 'mast';
      case 'discover':
        return 'disc';
      case 'ach':
        return 'echeck';
      default:
        return '';
    }
  }

  String? _selectedAccountTypeLabel() {
    switch (_accountType.toLowerCase()) {
      case 'checking':
        return 'Checking';
      case 'savings':
        return 'Savings';
      default:
        return null;
    }
  }

  String _mapAccountTypeLabelToCode(String? label) {
    switch ((label ?? '').toLowerCase()) {
      case 'checking':
        return 'checking';
      case 'savings':
        return 'savings';
      default:
        return '';
    }
  }

  Widget _buildFeeMessage() {
    final map = <String, String>{
      'visa': 'Visa',
      'mast': 'MasterCard',
      'disc': 'Discover',
      'echeck': 'ACH (Bank Transfer)',
    };
    final methodLabel = map[_paymentMethod] ?? 'Card';
    final feeText = _paymentMethod == 'echeck'
        ? '$methodLabel - \$1.00 convenience fee will be applied'
        : '$methodLabel - 3% convenience fee will be applied';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x40FF9F40)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFFDD6B20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feeText,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                color: Color(0xFFC05621),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSaveDetails() async {
    if (_isSaving) return;
    final isValid = _validateFields();
    if (!isValid) {
      final firstError = _fieldErrors.values.isNotEmpty
          ? _fieldErrors.values.first
          : 'Please check the form fields.';
      CoreUtils.showTopSnackBar(
        context: context,
        message: firstError,
        isWarning: true,
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Secure token created successfully.',
      isSuccess: true,
    );
  }

  bool _validateFields() {
    final errors = <String, String>{};

    if (_paymentMethod.isEmpty) {
      errors['paymentMethod'] = 'Please select a payment method';
    }

    if (_isCard) {
      final cardNumber = _cardNumberController.text.trim();
      final cvv = _cvvController.text.trim();

      if (cardNumber.isEmpty) {
        errors['cardNumber'] = 'Card number is required';
      } else if (cardNumber.length < 13 || cardNumber.length > 19) {
        errors['cardNumber'] = 'Card number must be 13-19 digits';
      }

      if (_expMonth.isEmpty) {
        errors['expMonth'] = 'Expiration month is required';
      }
      if (_expYear.isEmpty) {
        errors['expYear'] = 'Expiration year is required';
      }

      if (cvv.isEmpty) {
        errors['cvv'] = 'CVV is required';
      } else if (cvv.length < 3 || cvv.length > 4) {
        errors['cvv'] = 'CVV must be 3-4 digits';
      }
    } else if (_paymentMethod == 'echeck') {
      final accountNumber = _accountNumberController.text.trim();
      final routingNumber = _routingNumberController.text.trim();

      if (accountNumber.isEmpty) {
        errors['accountNumber'] = 'Account number is required';
      } else if (accountNumber.length < 4 || accountNumber.length > 17) {
        errors['accountNumber'] = 'Account number must be 4-17 digits';
      }

      if (routingNumber.isEmpty) {
        errors['routingNumber'] = 'Routing number is required';
      } else if (routingNumber.length != 9) {
        errors['routingNumber'] = 'Routing number must be 9 digits';
      }

      if (_accountType.isEmpty) {
        errors['accountType'] = 'Account type is required';
      }
    }

    setState(() {
      _fieldErrors
        ..clear()
        ..addAll(errors);
    });
    return errors.isEmpty;
  }
}
