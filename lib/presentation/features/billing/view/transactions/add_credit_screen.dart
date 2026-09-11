import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/presentation/features/billing/view_model/add_credit_cubit.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

/// Captures an account credit for a family/owner and posts it via
/// `POST /api/v1/invoices/credits`. Styled to match the Receive Payment screen.
class AddCreditScreen extends StatefulWidget {
  const AddCreditScreen({
    super.key,
    this.ownerType,
    this.ownerCode,
    this.studentCode,
    this.familyName,
  });

  static const String routeName = '/billing/add-credit';

  final String? ownerType;
  final String? ownerCode;
  final String? studentCode;
  final String? familyName;

  @override
  State<AddCreditScreen> createState() => _AddCreditScreenState();
}

class _AddCreditScreenState extends State<AddCreditScreen> {
  late final AddCreditCubit _cubit = serviceLocator<AddCreditCubit>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _internalNoteController = TextEditingController();

  static const int _maxChars = 500;

  final List<String> _reasonOptions = const <String>[
    'Extra Payment',
    'Additional Subsidy',
    // 'Overpayment',
    // 'Goodwill Adjustment',
    // 'Discount Adjustment',
    'Other',
  ];
  final ValueNotifier<String?> _selectedReason = ValueNotifier<String?>(null);

  bool get _isSubmitting => _cubit.state.isSubmitting;
  bool get _amountError => _cubit.state.amountError;

  @override
  void dispose() {
    _cubit.close();
    _amountController.dispose();
    _descriptionController.dispose();
    _internalNoteController.dispose();
    _selectedReason.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_selectedReason.value == null) {
      _showMessage(BillingStrings.pleaseSelectReason, isError: true);
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showMessage(BillingStrings.pleaseEnterDescription, isError: true);
      return;
    }
    final result = await _cubit.submit(
      amount: _amountController.text,
      reason: _selectedReason.value,
      description: _descriptionController.text.trim(),
      ownerType: widget.ownerType,
      ownerCode: widget.ownerCode,
      studentCode: widget.studentCode,
    );
    if (!mounted) return;
    switch (result) {
      case AddCreditResult.missingAmount:
        _showMessage(BillingStrings.pleaseEnterAnAmount, isError: true);
      case AddCreditResult.failure:
        _showMessage(
          _cubit.state.errorMessage ?? BillingStrings.couldNotAddCredit,
          isError: true,
        );
      case AddCreditResult.success:
        _showMessage(BillingStrings.creditAddedSuccessfully, isSuccess: true);
        Navigator.of(context).maybePop(true);
    }
  }

  void _showMessage(String message,
      {bool isError = false, bool isSuccess = false}) {
    CoreUtils.showTopSnackBar(
      context: context,
      message: message,
      isError: isError,
      isSuccess: isSuccess,
    );
  }

  // ── Shared field styling (matches Receive Payment) ─────────────────────────

  TextStyle _labelStyle(ResponsiveHelper responsive) => TextStyle(
        fontSize: responsive.labelFontSize,
        fontFamily: Fonts.manrope,
        fontWeight: FontWeight.w400,
        color: AppColors.billingTextColor,
      );

  Widget _fieldLabel(ResponsiveHelper responsive, String text,
      {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: _labelStyle(responsive),
        children: <InlineSpan>[
          TextSpan(text: text),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.errorColor),
            ),
        ],
      ),
    );
  }

  BoxDecoration _fieldBox(ResponsiveHelper responsive) => BoxDecoration(
        color: AppColors.billingCardColor,
        border: Border.all(color: AppColors.billingBorderDefault),
        borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
      );

  EdgeInsets _fieldPadding(ResponsiveHelper responsive) => EdgeInsets.symmetric(
        horizontal: responsive.isTablet ? 16.0 : 12.0,
        vertical: responsive.isTablet ? 16.0 : 12.0,
      );

  TextStyle _valueStyle(ResponsiveHelper responsive) => TextStyle(
        fontFamily: Fonts.manrope,
        fontSize: responsive.inputFontSize,
        fontWeight: FontWeight.w600,
        color: AppColors.billingTextColor,
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddCreditCubit>.value(
      value: _cubit,
      child: BlocBuilder<AddCreditCubit, AddCreditState>(
        builder: (context, state) {
          final responsive = ResponsiveHelper(context);
          final double verticalSpacing = responsive.verticalSpacing;
          final double labelGap = responsive.isTablet ? 8.0 : 6.0;

          return StaffFormLayout(
            title: BillingStrings.addCredit,
            bottomBar: _buildBottomBar(responsive),
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                _buildHeader(),
                SizedBox(height: verticalSpacing),
                _fieldLabel(responsive, BillingStrings.amount, required: true),
                SizedBox(height: labelGap),
                _buildAmountBox(responsive),
                if (_amountError)
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0, left: 2.0),
                    child: Text(
                      BillingStrings.pleaseEnterValidAmount,
                      style: TextStyle(color: AppColors.errorColor, fontSize: 12),
                    ),
                  ),
                SizedBox(height: verticalSpacing),
                _fieldLabel(responsive, BillingStrings.reason, required: true),
                SizedBox(height: labelGap),
                _buildReasonDropdown(responsive),
                SizedBox(height: verticalSpacing),
                _fieldLabel(responsive, BillingStrings.description,
                    required: true),
                SizedBox(height: labelGap),
                _buildCounterField(
                  responsive,
                  controller: _descriptionController,
                  hint: BillingStrings.enterDescription,
                ),
                SizedBox(height: verticalSpacing),
                _fieldLabel(responsive, BillingStrings.addOptionalInternalNote),
                SizedBox(height: labelGap),
                _buildCounterField(
                  responsive,
                  controller: _internalNoteController,
                  hint: BillingStrings.addInternalNoteOptional,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Header (avatar + name + gradient divider) ──────────────────────────────

  Widget _buildHeader() {
    final name = (widget.familyName ?? '').trim().isNotEmpty
        ? widget.familyName!.trim()
        : 'Family';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: AppColors.billingFamilyAvatarBackground,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(name),
                style: const TextStyle(
                  color: AppColors.billingCardOnColorText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: Fonts.manrope,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.billingTextColor,
                  fontFamily: Fonts.manrope,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 1.5,
          decoration: BoxDecoration(
            gradient: AppColors.buildSecondaryGradient(),
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'NA';
    final first = parts.first[0];
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  // ── Amount ($ prefix box) ──────────────────────────────────────────────────

  Widget _buildAmountBox(ResponsiveHelper responsive) {
    final double radius = responsive.isTablet ? 12.0 : 8.0;
    return Container(
      constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
      decoration: BoxDecoration(
        color: AppColors.billingCardColor,
        border: Border.all(color: AppColors.billingBorderDefault),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: <Widget>[
          Container(
            alignment: Alignment.center,
            padding: _fieldPadding(responsive),
            decoration: BoxDecoration(
              color: AppColors.billingBorderLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(radius),
                bottomLeft: Radius.circular(radius),
              ),
            ),
            child: Text(r'$', style: _valueStyle(responsive)),
          ),
          Expanded(
            child: TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (_) => _cubit.clearAmountError(),
              style: _valueStyle(responsive),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle:
                    _labelStyle(responsive).copyWith(color: AppColors.billingGrey),
                border: InputBorder.none,
                contentPadding: _fieldPadding(responsive),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reason dropdown ────────────────────────────────────────────────────────

  Widget _buildReasonDropdown(ResponsiveHelper responsive) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
          decoration: _fieldBox(responsive),
          child: ValueListenableBuilder<String?>(
            valueListenable: _selectedReason,
            builder: (context, selectedReason, _) => PopupMenuButton<String>(
            enabled: !_isSubmitting,
            padding: EdgeInsets.zero,
            position: PopupMenuPosition.under,
            color: AppColors.billingCardColor,
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              maxWidth: constraints.maxWidth,
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
            ),
            onSelected: (value) => _selectedReason.value = value,
            itemBuilder: (context) => _reasonOptions
                .map(
                  (r) => PopupMenuItem<String>(
                    value: r,
                    child: Text(
                      r,
                      style: _valueStyle(responsive)
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                )
                .toList(),
            child: Padding(
              padding: _fieldPadding(responsive),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      selectedReason ?? BillingStrings.selectReason,
                      style: selectedReason != null
                          ? _valueStyle(responsive)
                          : _labelStyle(responsive).copyWith(color: AppColors.billingGrey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }

  // ── Multiline field with "x / 500 characters" counter ─────────────────────

  Widget _buildCounterField(
    ResponsiveHelper responsive, {
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          decoration: _fieldBox(responsive),
          child: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 4,
            inputFormatters: [LengthLimitingTextInputFormatter(_maxChars)],
            style: _valueStyle(responsive),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: _labelStyle(responsive).copyWith(color: AppColors.billingGrey),
              border: InputBorder.none,
              contentPadding: _fieldPadding(responsive),
            ),
          ),
        ),
        const SizedBox(height: 6),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => Text(
            '${value.text.characters.length} / $_maxChars characters',
            style: _labelStyle(responsive).copyWith(
              color: AppColors.billingTextColor.withValues(alpha: 0.6),
              fontSize: responsive.labelFontSize - 1,
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom bar (Save) ──────────────────────────────────────────────────────

  Widget _buildBottomBar(ResponsiveHelper responsive) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    return Container(
      padding:
          EdgeInsets.only(bottom: safeAreaBottom, left: 16, right: 16, top: 8),
      decoration: BoxDecoration(
        color: AppColors.billingCardColor,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.blackColor.withValues(alpha: 0.05),
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
          color: _isSubmitting ? AppColors.billingGreyLight : null,
          borderRadius: BorderRadius.circular(responsive.isTablet ? 16.0 : 8.0),
        ),
        child: TextButton(
          onPressed: _isSubmitting ? null : _onSave,
          child: _isSubmitting
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.billingButtonTextColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      BillingStrings.processing,
                      style: TextStyle(
                        fontFamily: Fonts.manrope,
                        fontSize: responsive.buttonFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.billingCardColor,
                      ),
                    ),
                  ],
                )
              : Text(
                  BillingStrings.save,
                  style: TextStyle(
                    fontFamily: Fonts.manrope,
                    fontSize: responsive.buttonFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.billingCardColor,
                  ),
                ),
        ),
      ),
    );
  }
}
