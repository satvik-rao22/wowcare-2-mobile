import 'package:flutter/material.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class StaffAttendancePerWeekReportScreen extends StatefulWidget {
  const StaffAttendancePerWeekReportScreen({
    super.key,
    required this.staff,
    required this.classrooms,
  });

  static const String routeName = '/reports/staff/attendance-per-week';

  final List<String> staff;
  final List<String> classrooms;

  @override
  State<StaffAttendancePerWeekReportScreen> createState() =>
      _StaffAttendancePerWeekReportScreenState();
}

class _StaffAttendancePerWeekReportScreenState
    extends State<StaffAttendancePerWeekReportScreen> {
  static const List<String> _frequencyOptions = <String>[
    'Daily',
    'Weekly',
    'Monthly',
  ];

  String _frequency = 'Monthly';
  late DateTime _periodMonth;
  String? _selectedStaff;
  List<String> _selectedClassrooms = <String>[];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _periodMonth = DateTime(now.year, now.month, 1);
  }

  void _onGenerate() {
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Generating Attendance Per Staff report…',
      isSuccess: true,
    );
    Navigator.pop(context);
  }

  TextStyle _labelStyle(ResponsiveHelper r) => TextStyle(
        fontSize: r.labelFontSize,
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w400,
        color: const Color(0xff573353),
      );

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return ReportFormLayout(
      title: 'Attendance Per Staff',
      onGenerate: _onGenerate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CustomDropdown(
                  label: 'Frequency',
                  hintText: 'Select',
                  items: _frequencyOptions,
                  selectedItem: _frequency,
                  labelStyle: _labelStyle(responsive),
                  showAsterisk: true,
                  labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                  prependHintAsSelectableItem: false,
                  onSelect: (val) {
                    if (val == null) return;
                    setState(() => _frequency = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ReportFieldLabel(label: 'Period'),
                    ReportMonthYearField(
                      initialMonth: _periodMonth,
                      onMonthSelected: (d) =>
                          setState(() => _periodMonth = d),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.verticalSpacing),
          CustomDropdown(
            label: 'Staff',
            hintText: 'Select Staff',
            items: widget.staff,
            selectedItem: _selectedStaff,
            labelStyle: _labelStyle(responsive),
            showAsterisk: false,
            labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
            onSelect: (val) => setState(() => _selectedStaff = val),
          ),
          SizedBox(height: responsive.verticalSpacing),
          CustomMultiSelectDropdown(
            label: 'Classroom',
            hintText: 'Select Classroom',
            items: widget.classrooms,
            selectedItems: _selectedClassrooms,
            onChanged: (s) => setState(() => _selectedClassrooms = s),
          ),
          const ReportDefaultNote(
            text: 'Note: All Classrooms will be selected by Default.',
          ),
        ],
      ),
    );
  }
}
