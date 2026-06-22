import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/billing/cubit/admin_statements_cubit.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

const _kStatementTypes = ['Monthly', 'Yearly', 'Custom Range'];

const _kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const _kApiStatementType = <String, String>{
  'Monthly': 'MONTHLY',
  'Yearly': 'YEARLY',
  'Custom Range': 'CUSTOM',
};

final _kAvatarColors = <Color>[
  AppColors.warningColor,
  AppColors.themeColor,
  AppColors.primaryColor,
  Colors.teal,
];

class GenerateStatementScreen extends StatefulWidget {
  const GenerateStatementScreen({
    super.key,
    required this.cubit,
    required this.subscriberCode,
    required this.ownerType,
    this.familyChildren = const [],
  });

  final AdminStatementsCubit cubit;
  final String subscriberCode;
  final String ownerType;
  final List<Map<String, dynamic>> familyChildren;

  @override
  State<GenerateStatementScreen> createState() =>
      _GenerateStatementScreenState();
}

class _GenerateStatementScreenState extends State<GenerateStatementScreen> {
  late final Set<String> _selectedCodes = {
    for (final c in widget.familyChildren)
      if ((c['code'] ?? '').toString().isNotEmpty) (c['code'] ?? '').toString(),
  };

  final TextEditingController _descriptionController = TextEditingController();

  String? _statementType;
  String? _selectedMonth;
  String? _selectedYear;
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _includeDescription = false;
  bool _isSubmitting = false;

  bool _statementTypeError = false;
  bool _monthError = false;
  bool _yearError = false;
  bool _dateRangeError = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  List<String> get _yearOptions {
    final now = DateTime.now().year;
    return List.generate(8, (i) => '${now - 5 + i}');
  }

  bool _validate() {
    final typeErr = _statementType == null;
    final monthErr = _statementType == 'Monthly' && _selectedMonth == null;
    final yearErr =
        (_statementType == 'Monthly' || _statementType == 'Yearly') &&
            _selectedYear == null;
    final rangeErr = _statementType == 'Custom Range' &&
        (_customStart == null || _customEnd == null);

    setState(() {
      _statementTypeError = typeErr;
      _monthError = monthErr;
      _yearError = yearErr;
      _dateRangeError = rangeErr;
    });

    return !typeErr && !monthErr && !yearErr && !rangeErr;
  }

  DateTime _computePeriodStart() {
    switch (_statementType) {
      case 'Monthly':
        final m = _kMonths.indexOf(_selectedMonth!) + 1;
        return DateTime(int.parse(_selectedYear!), m, 1);
      case 'Yearly':
        return DateTime(int.parse(_selectedYear!), 1, 1);
      case 'Custom Range':
        return _customStart!;
      default:
        return DateTime.now();
    }
  }

  DateTime _computePeriodEnd() {
    switch (_statementType) {
      case 'Monthly':
        final m = _kMonths.indexOf(_selectedMonth!) + 1;
        return DateTime(int.parse(_selectedYear!), m + 1, 0);
      case 'Yearly':
        return DateTime(int.parse(_selectedYear!), 12, 31);
      case 'Custom Range':
        return _customEnd!;
      default:
        return DateTime.now();
    }
  }

  Future<void> _onGenerate() async {
    if (!_validate()) return;
    setState(() => _isSubmitting = true);

    final storage = serviceLocator<StorageService>();
    final orgCode =
        (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final schoolCode =
        (await storage.getString(StorageKeys.schoolCode) ?? '').trim();

    final error = await widget.cubit.generateStatement(
      organizationCode: orgCode,
      schoolCode: schoolCode,
      ownerType: widget.ownerType,
      subscriberCode: widget.subscriberCode,
      statementType: _kApiStatementType[_statementType!] ?? _statementType!,
      periodStart: _computePeriodStart(),
      periodEnd: _computePeriodEnd(),
      includeDescription: _includeDescription,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Statement generated successfully!',
        isSuccess: true,
      );
      Navigator.of(context).pop(true);
    } else {
      CoreUtils.showTopSnackBar(
        context: context,
        message: error,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final double vs = responsive.isTablet ? 24.0 : 16.0;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    final TextStyle labelStyle = AppTextStyles.label.copyWith(
      fontSize: responsive.labelFontSize,
      color: AppColors.billingTextColor,
    );

    return StaffFormLayout(
      title: 'Generate Statement',
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Selected Students ─────────────────────────────────────────────
          if (widget.familyChildren.isNotEmpty) ...[
            _SelectedStudentsCard(
              children: widget.familyChildren,
              selectedCodes: _selectedCodes,
              labelStyle: labelStyle,
              onToggle: (code) => setState(() {
                if (_selectedCodes.contains(code)) {
                  _selectedCodes.remove(code);
                } else {
                  _selectedCodes.add(code);
                }
              }),
            ),
            SizedBox(height: vs),
          ],

          // ── Statement Type ────────────────────────────────────────────────
          CustomDropdown(
            label: 'Statement Type',
            hintText: 'Select Statement Type',
            items: _kStatementTypes,
            selectedItem: _statementType,
            isRequired: true,
            showAsterisk: true,
            prependHintAsSelectableItem: false,
            labelStyle: labelStyle,
            fieldHeight: responsive.inputFieldHeight,
            onSelect: (val) => setState(() {
              _statementType = val;
              _statementTypeError = false;
              _selectedMonth = null;
              _selectedYear = null;
              _customStart = null;
              _customEnd = null;
              _monthError = false;
              _yearError = false;
              _dateRangeError = false;
            }),
          ),
          if (_statementTypeError) _errorWidget(),
          SizedBox(height: vs),

          // ── Period inputs (conditional) ───────────────────────────────────
          if (_statementType == 'Monthly') ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomDropdown(
                        label: 'Select Month',
                        hintText: 'Month',
                        items: _kMonths,
                        selectedItem: _selectedMonth,
                        isRequired: true,
                        showAsterisk: true,
                        prependHintAsSelectableItem: false,
                        labelStyle: labelStyle,
                        fieldHeight: responsive.inputFieldHeight,
                        onSelect: (val) => setState(() {
                          _selectedMonth = val;
                          _monthError = false;
                        }),
                      ),
                      if (_monthError) _errorWidget(),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomDropdown(
                        label: 'Select Year',
                        hintText: 'Year',
                        items: _yearOptions,
                        selectedItem: _selectedYear,
                        isRequired: true,
                        showAsterisk: true,
                        prependHintAsSelectableItem: false,
                        labelStyle: labelStyle,
                        fieldHeight: responsive.inputFieldHeight,
                        onSelect: (val) => setState(() {
                          _selectedYear = val;
                          _yearError = false;
                        }),
                      ),
                      if (_yearError) _errorWidget(),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: vs),
          ] else if (_statementType == 'Yearly') ...[
            CustomDropdown(
              label: 'Select Year',
              hintText: 'Select Year',
              items: _yearOptions,
              selectedItem: _selectedYear,
              isRequired: true,
              showAsterisk: true,
              prependHintAsSelectableItem: false,
              labelStyle: labelStyle,
              fieldHeight: responsive.inputFieldHeight,
              onSelect: (val) => setState(() {
                _selectedYear = val;
                _yearError = false;
              }),
            ),
            if (_yearError) _errorWidget(),
            SizedBox(height: vs),
          ] else if (_statementType == 'Custom Range') ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: labelStyle,
                    children: [
                      const TextSpan(text: 'Select Date Range'),
                      TextSpan(
                        text: ' *',
                        style: AppTextStyles.small
                            .copyWith(color: AppColors.errorColor),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
                CustomDateTimeField(
                  hasLabel: false,
                  isRangePicker: true,
                  label: 'Select Date Range',
                  fetchInitialTime: false,
                  isRequired: true,
                  onRangeSelected: (start, end) => setState(() {
                    _customStart = start;
                    _customEnd = end;
                    _dateRangeError = false;
                  }),
                ),
                if (_dateRangeError) _errorWidget(),
              ],
            ),
            SizedBox(height: vs),
          ],

          // ── Include Description ───────────────────────────────────────────
          GestureDetector(
            onTap: () =>
                setState(() => _includeDescription = !_includeDescription),
            behavior: HitTestBehavior.translucent,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _includeDescription,
                    onChanged: (val) =>
                        setState(() => _includeDescription = val ?? false),
                    activeColor: AppColors.themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Text('Include Description', style: labelStyle),
              ],
            ),
          ),
          if (_includeDescription) ...[
            const SizedBox(height: 10),
            Container(
              constraints:
                  BoxConstraints(minHeight: responsive.inputFieldHeight * 2.4),
              decoration: BoxDecoration(
                color: AppColors.billingCardColor,
                border: Border.all(color: AppColors.billingBorderHeavy),
                borderRadius: BorderRadius.circular(
                    responsive.isTablet ? 12.0 : 8.0),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Enter description…',
                  hintStyle:
                      labelStyle.copyWith(color: AppColors.billingGrey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: responsive.isTablet ? 16.0 : 12.0,
                    vertical: responsive.isTablet ? 16.0 : 12.0,
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: vs),
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
          confirmButtonLabel: 'Generate',
          onPressedConfirm: _onGenerate,
          showCancelButton: false,
          isForm: false,
          isLoading: _isSubmitting,
        ),
      ),
    );
  }

  Widget _errorWidget() => Padding(
        padding: const EdgeInsets.only(top: 4, left: 2),
        child: Text(
          '*This field is required.',
          style: AppTextStyles.small.copyWith(color: AppColors.errorColor),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Selected Students card
// ─────────────────────────────────────────────────────────────────────────────

class _SelectedStudentsCard extends StatelessWidget {
  const _SelectedStudentsCard({
    required this.children,
    required this.selectedCodes,
    required this.labelStyle,
    required this.onToggle,
  });

  final List<Map<String, dynamic>> children;
  final Set<String> selectedCodes;
  final TextStyle labelStyle;
  final void Function(String code) onToggle;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first : '';
    final last = parts.length > 1 ? parts.last : '';
    return ((first.isNotEmpty ? first[0] : '') +
            (last.isNotEmpty ? last[0] : ''))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = children
        .where((c) => selectedCodes.contains((c['code'] ?? '').toString()))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Students ($selectedCount)',
          style: labelStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorderColor),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: children.asMap().entries.map((entry) {
                final idx = entry.key;
                final child = entry.value;
                final code = (child['code'] ?? '').toString();
                final name =
                    (child['fullName'] ?? child['name'] ?? '').toString();
                final isSelected = selectedCodes.contains(code);
                final color = _kAvatarColors[idx % _kAvatarColors.length];

                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => onToggle(code),
                    behavior: HitTestBehavior.translucent,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: color,
                          child: Text(
                            _initials(name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 110),
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.value.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (_) => onToggle(code),
                            activeColor: AppColors.themeColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
