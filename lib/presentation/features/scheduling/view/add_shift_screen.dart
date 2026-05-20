import 'package:flutter/material.dart';

import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/gradient_time_picker_field.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class AddShiftScreen extends StatefulWidget {
  const AddShiftScreen({
    super.key,
    this.initialDate,
    this.initialClassroom,
    this.initialStaff,
    this.classrooms = const <String>[],
    this.staff = const <String>[],
  });

  static const String routeName = '/add-shift-screen';

  final DateTime? initialDate;
  final String? initialClassroom;
  final String? initialStaff;
  final List<String> classrooms;
  final List<String> staff;

  @override
  State<AddShiftScreen> createState() => _AddShiftScreenState();
}

class _AddShiftScreenState extends State<AddShiftScreen> {
  static const List<String> _weekDays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  static const List<String> _fallbackClassrooms = <String>[
    '1-Blue D',
    '2-Green A',
    '3-Yellow B',
    '4-Red C',
  ];
  static const List<String> _fallbackStaff = <String>[
    'Kimberly Dixon',
    'John Smith',
    'Sara Lee',
  ];

  DateTime? _date;
  DateTime? _untilDate;
  String? _selectedClassroom;
  String? _selectedStaff;

  TimeOfDay? _shiftStart;
  TimeOfDay? _shiftEnd;
  // PRD AC2 — break is optional. Stays null until the user picks a value.
  TimeOfDay? _breakStart;
  TimeOfDay? _breakEnd;

  bool _repeatOn = false;
  final Set<String> _selectedDays = <String>{};

  final TextEditingController _noteController = TextEditingController();

  String? _untilDateError;
  String? _shiftStartError;
  String? _shiftEndError;
  String? _breakStartError;
  String? _breakEndError;
  String? _daysError;

  @override
  void initState() {
    super.initState();
    // PRD AC1 — date defaults to today.
    _date = widget.initialDate ?? DateTime.now();
    _selectedClassroom = widget.initialClassroom;
    _selectedStaff = widget.initialStaff;

    // School default work time. When staff is wired, replace with staff's
    // default work hours per PRD AC1.
    _shiftStart = const TimeOfDay(hour: 8, minute: 0);
    _shiftEnd = const TimeOfDay(hour: 17, minute: 0);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  List<String> get _classrooms =>
      widget.classrooms.isNotEmpty ? widget.classrooms : _fallbackClassrooms;
  List<String> get _staff =>
      widget.staff.isNotEmpty ? widget.staff : _fallbackStaff;

  int _minutesOf(TimeOfDay t) => t.hour * 60 + t.minute;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // PRD: "Missing required input → disable confirm". Gates the bottom button.
  bool get _isFormValid {
    if (_date == null) return false;
    if (_selectedClassroom == null || _selectedClassroom!.isEmpty) return false;
    if (_selectedStaff == null || _selectedStaff!.isEmpty) return false;
    if (_shiftStart == null || _shiftEnd == null) return false;
    if (_repeatOn) {
      if (_selectedDays.isEmpty) return false;
      if (_untilDate == null) return false;
    }
    return true;
  }

  void _toggleRepeat(bool value) {
    setState(() {
      _repeatOn = value;
      if (!_repeatOn) {
        _selectedDays.clear();
        _untilDate = null;
        _daysError = null;
        _untilDateError = null;
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedDays.length == _weekDays.length) {
        _selectedDays.clear();
      } else {
        _selectedDays
          ..clear()
          ..addAll(_weekDays);
      }
      _daysError = null;
    });
  }

  /// Time-relationship and break validations (PRD Section 1 AC3/AC4, Section 2 AC1).
  /// Required-field presence is covered by the disabled Confirm button.
  bool _validate() {
    setState(() {
      _shiftStartError = null;
      _shiftEndError = null;
      _breakStartError = null;
      _breakEndError = null;
      _untilDateError = null;
    });

    final shiftStartMin = _minutesOf(_shiftStart!);
    final shiftEndMin = _minutesOf(_shiftEnd!);

    // AC4: shift end > shift start
    if (shiftEndMin <= shiftStartMin) {
      setState(() => _shiftEndError = 'Shift end must be after shift start');
      return false;
    }

    // AC3: break is optional. If only one side is filled, both are required.
    final hasBreakStart = _breakStart != null;
    final hasBreakEnd = _breakEnd != null;
    if (hasBreakStart != hasBreakEnd) {
      setState(() {
        if (!hasBreakStart) _breakStartError = 'Break start is required';
        if (!hasBreakEnd) _breakEndError = 'Break end is required';
      });
      return false;
    }

    if (hasBreakStart && hasBreakEnd) {
      final breakStartMin = _minutesOf(_breakStart!);
      final breakEndMin = _minutesOf(_breakEnd!);
      // AC3: break end > break start
      if (breakEndMin <= breakStartMin) {
        setState(
          () => _breakEndError = 'Break end must be after break start',
        );
        return false;
      }
      // AC3: break must fall within shift
      if (breakStartMin < shiftStartMin || breakEndMin > shiftEndMin) {
        setState(() {
          _breakStartError = 'Break must be within shift';
          _breakEndError = 'Break must be within shift';
        });
        return false;
      }
    }

    // Section 2 AC1: recurring shift "Until Date" must be ≥ start date.
    if (_repeatOn && _untilDate != null && _date != null) {
      if (_untilDate!.isBefore(_date!) && !_isSameDay(_untilDate!, _date!)) {
        setState(() => _untilDateError = 'Must be on or after the shift date');
        return false;
      }
    }

    return true;
  }

  /// PRD AC5 — Force-add prompt for a single shift that falls outside staff
  /// availability. Returns true when the user confirms "Yes".
  ///
  /// Not yet invoked automatically: gated by staff-availability data from the
  /// backend. When wired, call this before submit if (_repeatOn == false) and
  /// the shift extends past staff working/break hours.
  // ignore: unused_element
  Future<bool> _promptForceAdd() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Outside staff availability'),
        content: const Text(
          "You are adding a shift outside this staff's work & break times. "
          'Do you still want to add this shift?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// PRD AC6 / Section 3 — Overlap or duplicate prompt. Returns true on
  /// "Yes, override" so existing draft/published shifts get replaced.
  // ignore: unused_element
  Future<bool> _promptOverride(String dateRangeLabel) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Shifts already exist'),
        content: Text(
          'Shifts already exist for this staff for $dateRangeLabel. '
          'Do you want to override?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, override'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// PRD AC7 — Absence hard block. Shows the standard message and aborts.
  // ignore: unused_element
  Future<void> _showAbsenceBlocked(String selectedDaysLabel) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Staff is absent'),
        content: Text(
          'This staff is marked absent for $selectedDaysLabel, '
          'so no shift can be added for them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _onConfirm() async {
    if (!_validate()) return;

    // Backend hooks per PRD — uncomment / wire when the data is available:
    //
    //   if (isStaffAbsent(_selectedStaff!, _date!)) {
    //     await _showAbsenceBlocked(DateFormat('MMM d').format(_date!));
    //     return;
    //   }
    //   final outsideAvailability = !shiftWithinAvailability(...);
    //   if (outsideAvailability) {
    //     if (_repeatOn) {
    //       // Section 2 AC2 — recurring: hard error, no force-add.
    //       CoreUtils.showTopSnackBar(
    //         context: context,
    //         message: "You are adding shift outside of this staff's work & "
    //                  "break times.",
    //         isError: true,
    //       );
    //       return;
    //     }
    //     final confirmed = await _promptForceAdd();
    //     if (!confirmed) return;
    //   }
    //   final conflictRange = findOverlappingShifts(...);
    //   if (conflictRange != null) {
    //     final override = await _promptOverride(conflictRange);
    //     if (!override) return;
    //   }

    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Shift saved successfully',
      isSuccess: true,
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottomPadding = safeBottom > 0 ? safeBottom : 16.0;

    return StaffFormLayout(
      title: 'Add Shift',
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
        child: CustomButtonLayout(
          confirmButtonLabel: 'Confirm',
          // PRD: disable confirm until all required inputs are present.
          onPressedConfirm: _isFormValid ? _onConfirm : null,
          showCancelButton: false,
          isForm: false,
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDateField(
                  responsive,
                  label: 'Date',
                  date: _date,
                  onDateSelected: (d) => setState(() => _date = d),
                ),
              ),
              SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
              Expanded(
                child: CustomDropdown(
                  label: 'Classroom',
                  hintText: 'Select',
                  items: _classrooms,
                  selectedItem: _selectedClassroom,
                  labelStyle: TextStyle(
                    fontSize: responsive.labelFontSize,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w400,
                    color: const Color(0xff573353),
                  ),
                  showAsterisk: true,
                  labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                  onSelect: (val) => setState(() => _selectedClassroom = val),
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.verticalSpacing),
          CustomDropdown(
            label: 'Staff',
            hintText: 'Select',
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GradientTimePickerField(
                  label: 'Shift Start',
                  isRequired: true,
                  time: _shiftStart,
                  errorText: _shiftStartError,
                  onTimeSelected: (t) => setState(() {
                    _shiftStart = t;
                    _shiftStartError = null;
                  }),
                ),
              ),
              SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
              Expanded(
                child: GradientTimePickerField(
                  label: 'Shift End',
                  isRequired: true,
                  time: _shiftEnd,
                  errorText: _shiftEndError,
                  onTimeSelected: (t) => setState(() {
                    _shiftEnd = t;
                    _shiftEndError = null;
                  }),
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.verticalSpacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GradientTimePickerField(
                  label: 'Break Start',
                  // PRD AC2 — break is optional.
                  time: _breakStart,
                  errorText: _breakStartError,
                  onTimeSelected: (t) => setState(() {
                    _breakStart = t;
                    _breakStartError = null;
                  }),
                ),
              ),
              SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
              Expanded(
                child: GradientTimePickerField(
                  label: 'Break End',
                  time: _breakEnd,
                  errorText: _breakEndError,
                  onTimeSelected: (t) => setState(() {
                    _breakEnd = t;
                    _breakEndError = null;
                  }),
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.verticalSpacing),
          _buildRepeatHeader(responsive),
          SizedBox(height: responsive.isTablet ? 16.0 : 12.0),
          if (_repeatOn) ...[
            _buildDaysGrid(responsive),
            if (_daysError != null) ...[
              const SizedBox(height: 6),
              Text(
                _daysError!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
            SizedBox(height: responsive.verticalSpacing),
            _buildDateField(
              responsive,
              label: 'Until Date',
              date: _untilDate,
              errorText: _untilDateError,
              firstDate: _date,
              onDateSelected: (d) => setState(() {
                _untilDate = d;
                _untilDateError = null;
              }),
            ),
            SizedBox(height: responsive.verticalSpacing),
          ],
          _buildNoteField(responsive),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDateField(
    ResponsiveHelper responsive, {
    required String label,
    required DateTime? date,
    required ValueChanged<DateTime> onDateSelected,
    String? errorText,
    DateTime? firstDate,
  }) {
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
            children: [
              TextSpan(text: label),
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        CustomDateTimeField(
          key: ValueKey('$label-${date?.toIso8601String() ?? 'empty'}'),
          hasLabel: false,
          fetchInitialTime: false,
          initialDate: date,
          firstDate: firstDate,
          onDateSelected: onDateSelected,
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRepeatHeader(ResponsiveHelper responsive) {
    return Row(
      children: [
        CustomToggle(
          label: 'Repeat On',
          isToggled: _repeatOn,
          onToggle: _toggleRepeat,
          labelOnLeftSide: true,
          labelStyle: TextStyle(
            fontSize: responsive.labelFontSize,
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w500,
            color: const Color(0xff573353),
          ),
        ),
        const Spacer(),
        if (_repeatOn)
          GestureDetector(
            onTap: _toggleSelectAll,
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: AppColors.primaryGradientColors,
              ).createShader(bounds),
              child: Text(
                _selectedDays.length == _weekDays.length
                    ? 'Clear All'
                    : 'Select All',
                style: TextStyle(
                  fontSize: responsive.labelFontSize,
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDaysGrid(ResponsiveHelper responsive) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _weekDays.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: responsive.isTablet ? 16.0 : 8.0,
        mainAxisSpacing: responsive.isTablet ? 16.0 : 10.0,
        childAspectRatio: responsive.isTablet ? 4.0 : 3.2,
      ),
      itemBuilder: (context, index) {
        final day = _weekDays[index];
        final isSelected = _selectedDays.contains(day);
        return Container(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.themeColor.withOpacity(0.12)
                : AppColors.fieldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CustomCheckbox(
            value: isSelected,
            label: day,
            scale: 1.0,
            labelStyle: TextStyle(
              fontSize: responsive.isTablet ? 14.0 : 12.5,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
            onChanged: (val) {
              setState(() {
                if (val ?? false) {
                  _selectedDays.add(day);
                } else {
                  _selectedDays.remove(day);
                }
                _daysError = null;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildNoteField(ResponsiveHelper responsive) {
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: 'Manrope',
      fontWeight: FontWeight.w400,
      color: const Color(0xff573353),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add Note', style: labelStyle),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(
            minHeight: responsive.inputFieldHeight,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius: BorderRadius.circular(
              responsive.isTablet ? 12.0 : 8.0,
            ),
          ),
          child: TextField(
            controller: _noteController,
            maxLines: 3,
            minLines: 1,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.inputFontSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xff573353),
              height: 19 / 14,
            ),
            decoration: InputDecoration(
              hintText: 'Write a note',
              hintStyle: labelStyle.copyWith(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

