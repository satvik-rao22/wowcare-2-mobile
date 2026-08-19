import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/domain/features/billing/entities/ledger_transaction_entity.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    required this.ledgerCode,
    required this.onSave,
    super.key,
  });

  final String ledgerCode;

  /// Called with the validated params. Return true on success, false on failure.
  final Future<bool> Function(AddTransactionParams) onSave;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountCtrl = TextEditingController();
  final _narrationCtrl = TextEditingController();

  DateTime? _date;
  bool _saving = false;
  bool _amountError = false;
  bool _dateError = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _narrationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountStr = _amountCtrl.text.trim();
    final amount = double.tryParse(amountStr);
    setState(() {
      _amountError = amountStr.isEmpty || amount == null;
      _dateError = _date == null;
    });
    if (_amountError || _dateError) return;

    setState(() => _saving = true);
    final ok = await widget.onSave(
      AddTransactionParams(
        ledgerCode: widget.ledgerCode,
        amount: amount!,
        date: DateFormat('yyyy-MM-dd').format(_date!),
        narration: _narrationCtrl.text.trim().isEmpty
            ? null
            : _narrationCtrl.text.trim(),
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final double verticalSpacing = responsive.isTablet ? 24.0 : 16.0;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    final TextStyle labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: 'Manrope',
      fontWeight: FontWeight.w400,
      color: const Color(0xFF0A1C5D),
    );

    return StaffFormLayout(
      title: 'Add Transaction',
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Amount ──────────────────────────────────────────────────
          _buildInputField(
            label: 'Amount',
            hint: 'E.g. 100.00',
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            error: _amountError ? '*Enter a valid amount.' : null,
            labelStyle: labelStyle,
            responsive: responsive,
          ),
          SizedBox(height: verticalSpacing),

          // ── Date ────────────────────────────────────────────────────
          CustomDateTimeField(
            label: 'Date',
            hasLabel: true,
            isRequired: true,
            fetchInitialTime: false,
            labelStyle: labelStyle,
            onDateSelected: (date) => setState(() {
              _date = date;
              _dateError = false;
            }),
          ),
          if (_dateError) ...[
            const SizedBox(height: 4),
            const Text(
              '*Date is required.',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ],
          SizedBox(height: verticalSpacing),

          // ── Description ─────────────────────────────────────────────
          _buildInputField(
            label: 'Description',
            hint: 'Add Description',
            controller: _narrationCtrl,
            maxLines: 4,
            required: false,
            labelStyle: labelStyle,
            responsive: responsive,
          ),
          SizedBox(height: verticalSpacing),
        ],
      ),
      bottomBar: Container(
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
            topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
            topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
          ),
        ),
        child: CustomButtonLayout(
          confirmButtonLabel: 'Save',
          onPressedConfirm: _submit,
          showCancelButton: false,
          isForm: false,
          isLoading: _saving,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required TextStyle labelStyle,
    required ResponsiveHelper responsive,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
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
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x660A1C5D)),
            borderRadius:
                BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.inputFontSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1C5D),
              height: 19 / 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: labelStyle.copyWith(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }
}
