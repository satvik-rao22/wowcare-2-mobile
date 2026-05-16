import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/billing/view/auto_pay_new_method_screen.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';

class AutoPayPaymentMethodsScreen extends StatefulWidget {
  const AutoPayPaymentMethodsScreen({super.key});

  static const String routeName = '/auto-pay-payment-methods';

  @override
  State<AutoPayPaymentMethodsScreen> createState() =>
      _AutoPayPaymentMethodsScreenState();
}

class _AutoPayPaymentMethodsScreenState
    extends State<AutoPayPaymentMethodsScreen> {
  bool _isAutoPayEnabled = true;
  bool _isSaving = false;
  bool _isLoadingSavedPaymentMethods = false;
  bool _hasErrorLoadingPaymentMethods = false;
  String? _selectedMethod = 'echeck';
  String? _initialSelectedMethod = 'echeck';
  bool _initialAutoPayEnabled = true;
  SavedCardData? _savedCardData = const SavedCardData(
    nameOnCard: 'Emma Johnson',
    last4: '3456',
    expireMonth: 10,
    expireYear: 2028,
    cardType: 'visa',
  );
  SavedEcheckData? _savedEcheckData = const SavedEcheckData(
    accountHolder: 'Emma Johnson',
    routingNumber: '123456789',
    last4: '9876',
    accountType: 'checking',
  );

  @override
  Widget build(BuildContext context) {
    final hasSelection = !_isAutoPayEnabled || _selectedMethod != null;
    final hasChanges =
        (_isAutoPayEnabled != _initialAutoPayEnabled) ||
        (_selectedMethod != _initialSelectedMethod);
    final canSave = !_isSaving && hasSelection && hasChanges;

    return StaffFormLayout(
      title: 'Auto Payment',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAutoPayToggle(),
            const SizedBox(height: 16),
            const Divider(height: 32),
            const SizedBox(height: 16),
            _buildSavedPaymentMethods(),
          ],
        ),
      ),
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
          absorbing: !canSave,
          child: Opacity(
            opacity: canSave ? 1 : 0.6,
            child: CustomButtonLayout(
              confirmButtonLabel: _selectedMethod == 'new'
                  ? 'Continue'
                  : 'Save',
              onPressedConfirm: _handleSave,
              showCancelButton: false,
              isForm: false,
              isLoading: _isSaving,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoPayToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Auto Payment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          CustomToggle(
            label: '',
            isToggled: _isAutoPayEnabled,
            onToggle: (value) {
              setState(() {
                final wasEnabled = _isAutoPayEnabled;
                _isAutoPayEnabled = value;
                if (value && !_initialAutoPayEnabled) _selectedMethod = null;
                if (!value && wasEnabled) _selectedMethod = null;
              });
            },
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _isAutoPayEnabled
                  ? const Color(0xFFE8FFF1)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _isAutoPayEnabled ? 'Enabled' : 'Disabled',
              style: TextStyle(
                color: _isAutoPayEnabled ? AppColors.successColor : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Saved Payment Methods',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingSavedPaymentMethods)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                SizedBox(width: 12),
                Text('Loading saved payment methods...'),
              ],
            ),
          )
        else if (_savedCardData == null &&
            _savedEcheckData == null &&
            !_hasErrorLoadingPaymentMethods)
          _buildEmptyState()
        else ...[
          if (_hasErrorLoadingPaymentMethods &&
              _savedCardData == null &&
              _savedEcheckData == null)
            _buildCardTile(
              title: 'No payment method found',
              value: 'card',
              isSelected: false,
              isDisabled: true,
              onTap: () {},
              showEdit: false,
              child: _buildPlaceholderCard(),
            ),
          if (_savedCardData != null)
            _buildCardTile(
              title: _isAutoPayEnabled ? 'Select this card' : 'Saved Card',
              value: 'card',
              isSelected: _selectedMethod == 'card' && _isAutoPayEnabled,
              isDisabled: !_isAutoPayEnabled,
              onTap: () => setState(() => _selectedMethod = 'card'),
              child: _buildCreditCard(_savedCardData!),
            ),
          if (_savedEcheckData != null)
            _buildCardTile(
              title: _isAutoPayEnabled ? 'Select this account' : 'Saved eCheck',
              value: 'echeck',
              isSelected: _selectedMethod == 'echeck' && _isAutoPayEnabled,
              isDisabled: !_isAutoPayEnabled,
              onTap: () => setState(() => _selectedMethod = 'echeck'),
              child: _buildEcheckCard(_savedEcheckData!),
            ),
          _buildNewPaymentMethodTile(),
        ],
      ],
    );
  }

  Widget _buildCardTile({
    required String title,
    required String value,
    required Widget child,
    required bool isSelected,
    required bool isDisabled,
    required VoidCallback onTap,
    bool showEdit = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0FFF4) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.successColor : Colors.transparent,
          width: 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.successColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (!isDisabled)
                Radio<String>(
                  value: value,
                  groupValue: _selectedMethod,
                  onChanged: (_) => onTap(),
                  activeColor: AppColors.successColor,
                )
              else
                const SizedBox(width: 40),
              Expanded(
                child: GestureDetector(
                  onTap: isDisabled ? null : onTap,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDisabled ? Colors.grey : Colors.black87,
                    ),
                  ),
                ),
              ),
              if (showEdit)
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit, color: Color(0xFF667EEA)),
                  onPressed: () {},
                ),
            ],
          ),
          GestureDetector(
            onTap: isDisabled ? null : onTap,
            child: Opacity(opacity: isDisabled ? 0.7 : 1, child: child),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPaymentMethodTile() {
    final isSelected = _selectedMethod == 'new' && _isAutoPayEnabled;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0FFF4) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.successColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: _isAutoPayEnabled ? _openNewPaymentMethodScreen : null,
        child: Row(
          children: [
            Radio<String>(
              value: 'new',
              groupValue: _isAutoPayEnabled ? _selectedMethod : null,
              onChanged: _isAutoPayEnabled
                  ? (_) => _openNewPaymentMethodScreen()
                  : null,
              activeColor: AppColors.successColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Use new payment method',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isAutoPayEnabled ? Colors.black87 : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCard(SavedCardData card) {
    final gradient = _cardGradient(card.cardType);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320, minHeight: 170),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildChip(),
              Text(
                card.cardType.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text(
                '•••• •••• ••••',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 2,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                card.last4,
                style: const TextStyle(
                  color: Colors.white,
                  letterSpacing: 2,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _detailGroup('Card Holder', card.nameOnCard.toUpperCase()),
              _detailGroup('Expires', '${card.expireMonth}/${card.expireYear}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEcheckCard(SavedEcheckData echeck) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320, minHeight: 170),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB8DAEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'eCheck',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334455),
                ),
              ),
              Text(
                echeck.accountTypeLabel,
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _detailGroup(
                  'Account Holder Name',
                  echeck.accountHolder,
                  isDark: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _detailGroup(
                  'Routing Number',
                  echeck.routingNumber,
                  isDark: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _detailGroup('Last Four', echeck.last4, isDark: false),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: const Column(
        children: [
          Icon(Icons.credit_card, size: 36, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'No saved payment methods found',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320, minHeight: 170),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off, color: Colors.white54, size: 48),
          SizedBox(height: 12),
          Text(
            'Payment details not available',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _cardGradient(String cardType) {
    final type = cardType.toLowerCase();
    if (type.contains('visa')) {
      return const LinearGradient(
        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (type.contains('mast') || type.contains('master')) {
      return const LinearGradient(
        colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (type.contains('discover')) {
      return const LinearGradient(
        colors: [Color(0xFFFF9966), Color(0xFFFF5E62)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (type.contains('amex')) {
      return const LinearGradient(
        colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFF5B5B5B), Color(0xFF1A1A1A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Widget _buildChip() {
    return Container(
      width: 40,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          colors: [Color(0xFFD1D1D1), Color(0xFFFCFCFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _detailGroup(String label, String value, {bool isDark = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isSaving = false);
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Auto Pay settings saved',
      isSuccess: true,
    );
    Navigator.of(context).pop();
  }

  Future<void> _openNewPaymentMethodScreen() async {
    setState(() => _selectedMethod = 'new');
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AutoPayNewMethodScreen()));
  }
}

class SavedCardData {
  const SavedCardData({
    required this.nameOnCard,
    required this.last4,
    required this.expireMonth,
    required this.expireYear,
    required this.cardType,
  });

  final String nameOnCard;
  final String last4;
  final int expireMonth;
  final int expireYear;
  final String cardType;
}

class SavedEcheckData {
  const SavedEcheckData({
    required this.accountHolder,
    required this.routingNumber,
    required this.last4,
    required this.accountType,
  });

  final String accountHolder;
  final String routingNumber;
  final String last4;
  final String accountType;

  String get accountTypeLabel {
    final lower = accountType.toLowerCase();
    if (lower == 'c' || lower.contains('checking')) return 'Checking';
    if (lower == 's' || lower.contains('saving')) return 'Savings';
    return accountType;
  }
}
