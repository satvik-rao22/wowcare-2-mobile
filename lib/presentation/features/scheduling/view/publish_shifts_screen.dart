import 'package:flutter/material.dart';

import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

enum PublishMode { untilDate, all }

class PublishShiftsResult {
  const PublishShiftsResult({
    required this.mode,
    this.staff,
    this.untilDate,
  });

  final PublishMode mode;
  final String? staff;
  final DateTime? untilDate;
}

/// PRD §7 — Publish Shifts. Full-page form (same layout as Add/View Shift):
/// pick an optional staff filter, then choose "Publish Until Date" or
/// "Publish All". Pops the route with a [PublishShiftsResult].
class PublishShiftsScreen extends StatefulWidget {
  const PublishShiftsScreen({
    super.key,
    this.staff = const <String>[],
    this.initialUntilDate,
    this.initialStaff,
  });

  static const String routeName = '/publish-shifts-screen';

  final List<String> staff;
  final DateTime? initialUntilDate;
  final String? initialStaff;

  @override
  State<PublishShiftsScreen> createState() => _PublishShiftsScreenState();
}

class _PublishShiftsScreenState extends State<PublishShiftsScreen> {
  static const List<String> _fallbackStaff = <String>[
    'Kimberly Dixon',
    'John Smith',
    'Sara Lee',
  ];

  String? _selectedStaff;
  PublishMode? _mode;
  DateTime? _untilDate;

  @override
  void initState() {
    super.initState();
    _selectedStaff = widget.initialStaff;
    _untilDate = widget.initialUntilDate;
  }

  List<String> get _staff =>
      widget.staff.isNotEmpty ? widget.staff : _fallbackStaff;

  // Publish is disabled until staff is picked, a mode is chosen, and (if
  // "Until Date") a date is set.
  bool get _isFormValid {
    if (_selectedStaff == null || _selectedStaff!.isEmpty) return false;
    if (_mode == null) return false;
    if (_mode == PublishMode.untilDate && _untilDate == null) return false;
    return true;
  }

  void _onPublish() {
    if (!_isFormValid) return;
    Navigator.of(context).pop(
      PublishShiftsResult(
        mode: _mode!,
        staff: _selectedStaff,
        untilDate: _mode == PublishMode.untilDate ? _untilDate : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottomPadding = safeBottom > 0 ? safeBottom : 16.0;

    return StaffFormLayout(
      title: 'Publish Shifts',
      bottomBar: Container(
        padding: EdgeInsets.only(
          bottom: bottomPadding,
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
          confirmButtonLabel: 'Publish',
          onPressedConfirm: _isFormValid ? _onPublish : null,
          onPressedCancel: () => Navigator.of(context).pop(),
          cancelButtonLabel: 'Cancel',
          showCancelButton: true,
          isForm: false,
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          CustomDropdown(
            label: 'Staff',
            hintText: 'Select Staff',
            items: _staff,
            selectedItem: _selectedStaff,
            labelStyle: TextStyle(
              fontSize: responsive.labelFontSize,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w400,
              color: const Color(0xff573353),
            ),
            showAsterisk: true,
            labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
            onSelect: (val) => setState(() => _selectedStaff = val),
          ),
          SizedBox(height: responsive.verticalSpacing),
          _PublishOptionRow(
            label: 'Publish Until Date',
            selected: _mode == PublishMode.untilDate,
            onTap: () => setState(() => _mode = PublishMode.untilDate),
          ),
          if (_mode == PublishMode.untilDate) ...[
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.only(
                left: responsive.isTablet ? 36 : 32,
              ),
              child: _buildUntilDateField(responsive),
            ),
          ],
          SizedBox(height: responsive.verticalSpacing),
          _PublishOptionRow(
            label: 'Publish All',
            selected: _mode == PublishMode.all,
            onTap: () => setState(() => _mode = PublishMode.all),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildUntilDateField(ResponsiveHelper responsive) {
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: 'Manrope',
      fontWeight: FontWeight.w400,
      color: const Color(0xff573353),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: const [
              TextSpan(text: 'Until Date'),
              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        CustomDateTimeField(
          key: ValueKey(
            'publish-until-${_untilDate?.toIso8601String() ?? 'empty'}',
          ),
          hasLabel: false,
          fetchInitialTime: false,
          initialDate: _untilDate,
          onDateSelected: (d) => setState(() => _untilDate = d),
        ),
      ],
    );
  }
}

class _PublishOptionRow extends StatelessWidget {
  const _PublishOptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          _RadioDot(selected: selected),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Same visual language as the radio dot in [view_shift_screen.dart], with a
/// selected state added so we can toggle between the two publish options.
class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? AppColors.themeColor
              : AppColors.primaryColor.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.themeColor,
              ),
            )
          : null,
    );
  }
}
