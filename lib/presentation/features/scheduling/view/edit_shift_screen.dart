import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/presentation/features/scheduling/utils/school_hours_resolver.dart';
import 'package:wowcare/presentation/features/scheduling/view/view_shift_screen.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/gradient_time_picker_field.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

/// Whether the Edit screen affects a single occurrence or every occurrence in
/// a recurring series. Drives the screen title and whether the recurrence
/// controls (Repeat On / Until Date) are shown.
enum EditShiftMode { thisShift, entireSeries }

/// Edit form for an existing shift. Mirrors [AddShiftScreen]'s field layout
/// so the editing experience is visually consistent. In [EditShiftMode.entireSeries]
/// the recurrence controls become inline (no toggle) and the title changes.
class EditShiftScreen extends StatefulWidget {
  const EditShiftScreen({
    super.key,
    required this.mode,
    required this.initialDate,
    required this.staff,
    required this.classroom,
    required this.shiftStart,
    required this.shiftEnd,
    this.breakStart,
    this.breakEnd,
    this.note,
    this.status = ShiftStatus.published,
    this.isPublished = true,
    this.selectedDays = const <String>{},
    this.untilDate,
    this.classrooms = const <String>[],
    this.staffOptions = const <String>[],
    this.onSave,
  });

  static const String routeName = '/edit-shift-screen';

  final EditShiftMode mode;
  final DateTime initialDate;
  final String staff;
  final String classroom;
  final TimeOfDay shiftStart;
  final TimeOfDay shiftEnd;
  final TimeOfDay? breakStart;
  final TimeOfDay? breakEnd;
  final String? note;
  final ShiftStatus status;
  final bool isPublished;
  final Set<String> selectedDays;
  final DateTime? untilDate;
  final List<String> classrooms;
  final List<String> staffOptions;
  final VoidCallback? onSave;

  @override
  State<EditShiftScreen> createState() => _EditShiftScreenState();
}

class _EditShiftScreenState extends State<EditShiftScreen> {
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
    'Green-D',
  ];

  late DateTime? _date = widget.initialDate;
  late DateTime? _untilDate = widget.untilDate ?? widget.initialDate;
  late String? _selectedClassroom = widget.classroom;
  late String? _selectedStaff = widget.staff;

  late TimeOfDay? _shiftStart = widget.shiftStart;
  late TimeOfDay? _shiftEnd = widget.shiftEnd;
  late TimeOfDay? _breakStart = widget.breakStart;
  late TimeOfDay? _breakEnd = widget.breakEnd;

  late final Set<String> _selectedDays = Set<String>.of(widget.selectedDays);
  late bool _publish = widget.isPublished;

  late final TextEditingController _noteController =
      TextEditingController(text: widget.note ?? '');

  String? _shiftStartError;
  String? _shiftEndError;
  String? _breakStartError;
  String? _breakEndError;
  String? _untilDateError;
  String? _daysError;
  String? _schoolHoursError;

  /// School open/close hours per weekday. Drives the hard-rule check that
  /// shift / break times must fall inside school hours.
  SchoolHoursResolver? _schoolHoursResolver;

  static const Map<int, String> _weekDayIndex = <int, String>{
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  static final Map<String, int> _weekDayNameToIndex = <String, int>{
    for (final entry in _weekDayIndex.entries) entry.value: entry.key,
  };

  bool get _isSeriesMode => widget.mode == EditShiftMode.entireSeries;

  List<String> get _classroomOptions =>
      widget.classrooms.isNotEmpty ? widget.classrooms : _fallbackClassrooms;

  List<String> get _staffOptions => widget.staffOptions.isNotEmpty
      ? widget.staffOptions
      : <String>[widget.staff];

  @override
  void initState() {
    super.initState();
    _loadSchoolHours();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadSchoolHours() async {
    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode =
          (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
      if (schoolCode.isEmpty) return;
      final repo = serviceLocator<StaffRepository>();
      final days =
          await repo.getSchoolRegularSchedules(schoolCode: schoolCode);
      if (!mounted) return;
      setState(() {
        _schoolHoursResolver = SchoolHoursResolver.fromDays(days);
      });
    } catch (_) {
      // Best-effort: without school hours the hard-rule check no-ops.
    }
  }

  int _minutesOf(TimeOfDay t) => t.hour * 60 + t.minute;

  TimeOfDay? _parse24hTime(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  (TimeOfDay, TimeOfDay)? _schoolHoursForDate(DateTime date) {
    final day = _schoolHoursResolver?.dayFor(date);
    if (day == null) return null;
    final start = _parse24hTime(day.startTime);
    final end = _parse24hTime(day.endTime);
    if (start == null || end == null) return null;
    return (start, end);
  }

  (TimeOfDay, TimeOfDay)? _schoolHoursForWeekday(int weekday) {
    final anchor = _date ?? DateTime.now();
    for (var i = 0; i < 7; i++) {
      final probe = anchor.add(Duration(days: i));
      if (probe.weekday == weekday) {
        return _schoolHoursForDate(probe);
      }
    }
    return null;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _isFormValid {
    if (_date == null) return false;
    if (_selectedStaff == null || _selectedStaff!.isEmpty) return false;
    if (_selectedClassroom == null || _selectedClassroom!.isEmpty) return false;
    if (_shiftStart == null || _shiftEnd == null) return false;
    if (_isSeriesMode) {
      if (_selectedDays.isEmpty) return false;
      if (_untilDate == null) return false;
    }
    return true;
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

  bool _validate() {
    setState(() {
      _shiftStartError = null;
      _shiftEndError = null;
      _breakStartError = null;
      _breakEndError = null;
      _untilDateError = null;
      _daysError = null;
      _schoolHoursError = null;
    });

    final shiftStartMin = _minutesOf(_shiftStart!);
    final shiftEndMin = _minutesOf(_shiftEnd!);

    if (shiftEndMin <= shiftStartMin) {
      setState(() => _shiftEndError = 'Shift end must be after shift start');
      return false;
    }

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
      if (breakEndMin <= breakStartMin) {
        setState(() => _breakEndError = 'Break end must be after break start');
        return false;
      }
      if (breakStartMin < shiftStartMin || breakEndMin > shiftEndMin) {
        setState(() {
          _breakStartError = 'Break must be within shift';
          _breakEndError = 'Break must be within shift';
        });
        return false;
      }
    }

    if (_isSeriesMode && _untilDate != null && _date != null) {
      if (_untilDate!.isBefore(_date!) && !_isSameDay(_untilDate!, _date!)) {
        setState(() => _untilDateError = 'Must be on or after the shift date');
        return false;
      }
    }

    // Hard rule: shift + break times must fall within the school's open/close
    // hours for the targeted day(s).
    final windows = <(TimeOfDay, TimeOfDay)>[];
    if (_isSeriesMode && _selectedDays.isNotEmpty) {
      for (final day in _selectedDays) {
        final weekday = _weekDayNameToIndex[day];
        if (weekday == null) continue;
        final w = _schoolHoursForWeekday(weekday);
        if (w != null) windows.add(w);
      }
    } else if (_date != null) {
      final w = _schoolHoursForDate(_date!);
      if (w != null) windows.add(w);
    }
    for (final window in windows) {
      final schoolStartMin = _minutesOf(window.$1);
      final schoolEndMin = _minutesOf(window.$2);
      final windowLabel =
          '${window.$1.format(context)} – ${window.$2.format(context)}';
      if (shiftStartMin < schoolStartMin || shiftEndMin > schoolEndMin) {
        final msg = 'Shift must be within school hours ($windowLabel).';
        setState(() => _schoolHoursError = msg);
        CoreUtils.showTopSnackBar(
          context: context,
          message: msg,
          isError: true,
        );
        return false;
      }
      if (hasBreakStart && hasBreakEnd) {
        final breakStartMin = _minutesOf(_breakStart!);
        final breakEndMin = _minutesOf(_breakEnd!);
        if (breakStartMin < schoolStartMin || breakEndMin > schoolEndMin) {
          final msg = 'Break must be within school hours ($windowLabel).';
          setState(() => _schoolHoursError = msg);
          CoreUtils.showTopSnackBar(
            context: context,
            message: msg,
            isError: true,
          );
          return false;
        }
      }
    }

    return true;
  }

  void _onSave() {
    if (!_validate()) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Shift updated successfully',
      isSuccess: true,
    );
    widget.onSave?.call();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottomPadding = safeBottom > 0 ? safeBottom : 16.0;
    final title = _isSeriesMode ? 'Edit entire series' : 'Edit this shift';

    return StaffFormLayout(
      title: title,
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
          confirmButtonLabel: 'Save',
          onPressedConfirm: _isFormValid ? _onSave : null,
          showCancelButton: false,
          isForm: false,
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildStatusHeader(responsive),
          SizedBox(height: responsive.verticalSpacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDateField(
                  responsive,
                  label: 'Date',
                  date: _date,
                  onDateSelected: (d) => setState(() {
                    _date = d;
                    _schoolHoursError = null;
                  }),
                ),
              ),
              SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
              Expanded(
                child: CustomDropdown(
                  label: 'Staff',
                  hintText: 'Select',
                  items: _staffOptions,
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
              ),
            ],
          ),
          SizedBox(height: responsive.verticalSpacing),
          CustomDropdown(
            label: 'Classroom',
            hintText: 'Select',
            items: _classroomOptions,
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
                    _schoolHoursError = null;
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
                    _schoolHoursError = null;
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
                  time: _breakStart,
                  errorText: _breakStartError,
                  onTimeSelected: (t) => setState(() {
                    _breakStart = t;
                    _breakStartError = null;
                    _schoolHoursError = null;
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
                    _schoolHoursError = null;
                  }),
                ),
              ),
            ],
          ),
          if (_schoolHoursError != null)
            CoreUtils.buildInlineFieldError(_schoolHoursError),
          SizedBox(height: responsive.verticalSpacing),
          if (_isSeriesMode) ...[
            _buildRepeatHeader(responsive),
            SizedBox(height: responsive.isTablet ? 16.0 : 12.0),
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
            Align(
              alignment: Alignment.centerLeft,
              child: _buildPublishCheckbox(responsive),
            ),
            SizedBox(height: responsive.verticalSpacing),
            _buildDateField(
              responsive,
              label: 'Until Date',
              date: _untilDate,
              firstDate: _date,
              errorText: _untilDateError,
              onDateSelected: (d) => setState(() {
                _untilDate = d;
                _untilDateError = null;
              }),
            ),
            SizedBox(height: responsive.verticalSpacing),
            _buildNoteField(responsive),
          ] else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: _buildPublishCheckbox(responsive),
            ),
            SizedBox(height: responsive.verticalSpacing),
            _buildNoteField(responsive),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(ResponsiveHelper responsive) {
    final formatted = DateFormat('MMM d, yyyy').format(widget.initialDate);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.isTablet ? 8.0 : 4.0,
      ),
      child: Text(
        'Shift on $formatted (${widget.status.label})',
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: responsive.titleFontSize * 0.85,
          fontWeight: FontWeight.w600,
          color: const Color(0xff573353),
        ),
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
        Text(
          'Repeat On',
          style: TextStyle(
            fontSize: responsive.labelFontSize,
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w500,
            color: const Color(0xff573353),
          ),
        ),
        const Spacer(),
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
                ? AppColors.themeColor.withValues(alpha: 0.12)
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

  Widget _buildPublishCheckbox(ResponsiveHelper responsive) {
    return CustomCheckbox(
      value: _publish,
      label: 'Publish shift',
      scale: 1.0,
      labelStyle: TextStyle(
        fontSize: responsive.labelFontSize,
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w500,
        color: const Color(0xff573353),
      ),
      onChanged: (val) => setState(() => _publish = val ?? false),
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
              hintText: 'Eg. Please note the change in classroom location',
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
