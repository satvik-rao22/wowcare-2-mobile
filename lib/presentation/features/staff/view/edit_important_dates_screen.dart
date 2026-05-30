import 'package:wowcare/core/util/logger_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/presentation/features/staff/cubit/important_dates_cubit.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/data/features/staff/models/staff_important_dates_models.dart';

class EditImportantDatesScreen extends StatefulWidget {
  const EditImportantDatesScreen({
    super.key,
    required this.staffCode,
    this.initialHireDate,
    this.initialCdaExaminationDate,
    this.initialFirstAidCprExpirationDate,
    this.initialBackgroundRecordCheckExpirationDate,
    this.initialPhysicalCheckupDate,
    this.initialPhysicalCheckupStatus,
  });
  static const String routeName = '/dashboard/edit-important-dates-screen';

  final String staffCode;
  final DateTime? initialHireDate;
  final DateTime? initialCdaExaminationDate;
  final DateTime? initialFirstAidCprExpirationDate;
  final DateTime? initialBackgroundRecordCheckExpirationDate;
  final DateTime? initialPhysicalCheckupDate;
  final String? initialPhysicalCheckupStatus;

  @override
  _EditImportantDatesScreenState createState() => _EditImportantDatesScreenState();
}

class _EditImportantDatesScreenState extends State<EditImportantDatesScreen> {
  late final ImportantDatesCubit _importantDatesCubit;
  DateTime? _selectedHireDate;
  DateTime? _selectedCdaExaminationDate;
  DateTime? _selectedFirstAidCprExpirationDate;
  DateTime? _selectedBackgroundRecordCheckExpirationDate;
  DateTime? _selectedPhysicalCheckupDate;
  String? _selectedPhysicalCheckupStatus;
  // For Physical Checkup:
  // - If there's no existing physical date (first time), only "Completed" is allowed by default.
  // - If a physical date already exists, allow all three options in the dropdown.
  static const List<String> _initialPhysicalStatusOptions = ['Completed'];
  static const List<String> _editPhysicalStatusOptions = ['Due', 'Scheduled', 'Completed'];
  late List<String> _physicalCheckupStatusOptions;

  DateTime _todayDateOnly() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  void initState() {
    super.initState();
    _importantDatesCubit = serviceLocator<ImportantDatesCubit>();
    // Prefill when editing
    _selectedHireDate = widget.initialHireDate;
    _selectedCdaExaminationDate = widget.initialCdaExaminationDate;
    _selectedFirstAidCprExpirationDate = widget.initialFirstAidCprExpirationDate;
    _selectedBackgroundRecordCheckExpirationDate = widget.initialBackgroundRecordCheckExpirationDate;
    _selectedPhysicalCheckupDate = widget.initialPhysicalCheckupDate;

    // Decide which options to show in the dropdown based on whether
    // there is already a physical checkup date on record.
    final hasExistingPhysicalDate = widget.initialPhysicalCheckupDate != null;
    _physicalCheckupStatusOptions = hasExistingPhysicalDate
        ? _editPhysicalStatusOptions
        : _initialPhysicalStatusOptions;

    // Map initial physical status from API value to display value.
    final initialStatus = widget.initialPhysicalCheckupStatus;
    if (initialStatus != null && initialStatus.isNotEmpty) {
      final upper = initialStatus.toUpperCase();
      if (upper == 'COMPLETED') {
        _selectedPhysicalCheckupStatus = 'Completed';
      } else if (upper == 'SCHEDULED') {
        _selectedPhysicalCheckupStatus = 'Scheduled';
      } else if (upper == 'DUE') {
        _selectedPhysicalCheckupStatus = 'Due';
      } else {
        _selectedPhysicalCheckupStatus = initialStatus;
      }
    } else {
      _selectedPhysicalCheckupStatus = null;
    }
  }

  @override
  void dispose() {
    _importantDatesCubit.close();
    super.dispose();
  }

  void _saveImportantDates() {
    final today = _todayDateOnly();

    // Hire Date: only today or past (optional field).
    if (_selectedHireDate != null && _selectedHireDate!.isAfter(today)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Hire Date cannot be in the future',
        isError: true,
      );
      return;
    }

    // CDA + BRC: must be today or future (alert if selected date is past).
    if (_selectedCdaExaminationDate != null &&
        _selectedCdaExaminationDate!.isBefore(today)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'CDA Examination Date cannot be in the past',
        isError: true,
      );
      return;
    }
    if (_selectedBackgroundRecordCheckExpirationDate != null &&
        _selectedBackgroundRecordCheckExpirationDate!.isBefore(today)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Background Record Check Expiration Date cannot be in the past',
        isError: true,
      );
      return;
    }

    // Physical Checkup rules depend on Status:
    // - Due/Scheduled: date must be today or future
    // - Completed: date must be today or past
    final physicalStatus = (_selectedPhysicalCheckupStatus ?? '').trim();
    final hasPhysicalStatus = physicalStatus.isNotEmpty;
    final hasPhysicalDate = _selectedPhysicalCheckupDate != null;
    if (hasPhysicalStatus || hasPhysicalDate) {
      if (!hasPhysicalStatus) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Physical Checkup Status is required',
          isError: true,
        );
        return;
      }
      if (!hasPhysicalDate) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Physical Checkup Date is required',
          isError: true,
        );
        return;
      }

      final picked = _selectedPhysicalCheckupDate!;
      final pickedOnly = _dateOnly(picked);
      final physicalStatusUpper = physicalStatus.toUpperCase();
      if (physicalStatusUpper == 'COMPLETED') {
        if (pickedOnly.isAfter(today)) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'For Completed status, Physical Checkup Date must be today or past',
            isError: true,
          );
          return;
        }
      } else if (physicalStatusUpper == 'DUE' ||
          physicalStatusUpper == 'SCHEDULED' ||
          physicalStatusUpper == 'OVERDUE') {
        if (pickedOnly.isBefore(today)) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'For Due/Scheduled status, Physical Checkup Date must be today or future',
            isError: true,
          );
          return;
        }
      }
    }

    final dates = <Map<String, String>>[];

    // Hire Date (optional)
    if (_selectedHireDate != null) {
      dates.add({
        'importantDateType': ImportantDateType.hireDate.value,
        'dueDate': DateFormat('yyyy-MM-dd').format(_selectedHireDate!),
        'completedDate': DateFormat('yyyy-MM-dd').format(_selectedHireDate!),
      });
    }

    // CDA Examination Date
    if (_selectedCdaExaminationDate != null) {
      dates.add({
        'importantDateType': ImportantDateType.cda.value,
        'dueDate': DateFormat('yyyy-MM-dd').format(_selectedCdaExaminationDate!),
        'completedDate': DateFormat('yyyy-MM-dd').format(_selectedCdaExaminationDate!),
      });
    }

    // First Aid/CPR Expiration Date (maps to FIRST_AID_CPR)
    if (_selectedFirstAidCprExpirationDate != null) {
      dates.add({
        'importantDateType': ImportantDateType.firstAidCpr.value,
        'dueDate': DateFormat('yyyy-MM-dd').format(_selectedFirstAidCprExpirationDate!),
        'completedDate': DateFormat('yyyy-MM-dd').format(_selectedFirstAidCprExpirationDate!),
      });
    }

    // Background Record Check Expiration Date
    if (_selectedBackgroundRecordCheckExpirationDate != null) {
      dates.add({
        'importantDateType': ImportantDateType.brc.value,
        'dueDate': DateFormat('yyyy-MM-dd').format(_selectedBackgroundRecordCheckExpirationDate!),
        'completedDate': DateFormat('yyyy-MM-dd').format(_selectedBackgroundRecordCheckExpirationDate!),
      });
    }

    // Physical Checkup Date (API supports status: Scheduled | Completed)
    if (_selectedPhysicalCheckupDate != null) {
      final dueDate = DateFormat('yyyy-MM-dd').format(_selectedPhysicalCheckupDate!);
      final map = <String, String>{
        'importantDateType': ImportantDateType.physicalCheckup.value,
        'dueDate': dueDate,
      };
      if (_selectedPhysicalCheckupStatus == 'Completed') {
        map['completedDate'] = dueDate;
        map['status'] = 'COMPLETED';
      } else if (_selectedPhysicalCheckupStatus == 'Scheduled') {
        map['status'] = 'SCHEDULED';
      } else if (_selectedPhysicalCheckupStatus == 'Due') {
        map['status'] = 'DUE';
      }
      dates.add(map);
    }

    _importantDatesCubit.updateImportantDates(
      staffCode: widget.staffCode,
      dates: dates,
    );
  }

  Future<void> _selectDate(String fieldName) async {
    try {
      DateTime? currentDate;
      DateTime? firstDate;
      DateTime? lastDate;
      final today = _todayDateOnly();
      switch (fieldName) {
        case 'hire':
          currentDate = _selectedHireDate;
          lastDate = today;
          break;
        case 'cda':
          currentDate = _selectedCdaExaminationDate;
          // CDA expiry: past date not allowed.
          firstDate = today;
          break;
        case 'firstAid':
          currentDate = _selectedFirstAidCprExpirationDate;
          break;
        case 'background':
          currentDate = _selectedBackgroundRecordCheckExpirationDate;
          // BRC expiry: past date not allowed.
          firstDate = today;
          break;
        case 'physical':
          currentDate = _selectedPhysicalCheckupDate;
          final statusUpper =
              (_selectedPhysicalCheckupStatus ?? '').trim().toUpperCase();
          if (statusUpper == 'COMPLETED') {
            lastDate = today;
          } else {
            // Due/Scheduled (and default): today or future.
            firstDate = today;
          }
          break;
      }

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => CalendarDialog(
          isRangePicker: false,
          isTimePicker: false,
          initialDate: currentDate,
          firstDate: firstDate,
          lastDate: lastDate,
        ),
      );
      
      if (result != null && result['date'] != null) {
        final selected = result['date'] as DateTime;
        final selectedOnly = _dateOnly(selected);
        if (fieldName == 'physical') {
          final statusUpper =
              (_selectedPhysicalCheckupStatus ?? '').trim().toUpperCase();
          if ((statusUpper == 'DUE' ||
                  statusUpper == 'SCHEDULED' ||
                  statusUpper == 'OVERDUE') &&
              selectedOnly.isBefore(today)) {
            CoreUtils.showTopSnackBar(
              context: context,
              message:
                  'For Due/Scheduled status, Physical Checkup Date must be today or future',
              isError: true,
            );
            return;
          }
          if (statusUpper == 'COMPLETED' && selectedOnly.isAfter(today)) {
            CoreUtils.showTopSnackBar(
              context: context,
              message:
                  'For Completed status, Physical Checkup Date must be today or past',
              isError: true,
            );
            return;
          }
        }

        setState(() {
          switch (fieldName) {
            case 'hire':
              _selectedHireDate = selected;
              break;
            case 'cda':
              _selectedCdaExaminationDate = selected;
              break;
            case 'firstAid':
              _selectedFirstAidCprExpirationDate = selected;
              break;
            case 'background':
              _selectedBackgroundRecordCheckExpirationDate = selected;
              break;
            case 'physical':
              _selectedPhysicalCheckupDate = selected;
              break;
          }
        });
      }
    } catch (e) {
      AppLogger.d('Error opening calendar dialog: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return BlocProvider<ImportantDatesCubit>.value(
      value: _importantDatesCubit,
      child: BlocListener<ImportantDatesCubit, ImportantDatesState>(
        listener: (context, state) {
          if (state.isSuccess && state.message != null) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: state.message!,
              isSuccess: true,
            );
            Navigator.pop(context, true);
          } else if (state.isError && state.message != null) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: state.message!,
              isError: true,
            );
          }
        },
        child: BlocBuilder<ImportantDatesCubit, ImportantDatesState>(
          builder: (context, state) {
            final isSubmitting = state.isLoading;

            return StaffFormLayout(
      title: "Edit Important Dates",
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDateField(
            "Hire Date",
            _selectedHireDate,
            'hire',
          ),
          SizedBox(height: responsive.verticalSpacing),
          _buildDateField(
            "CDA Examination Date",
            _selectedCdaExaminationDate,
            'cda',
          ),
          SizedBox(height: responsive.verticalSpacing),
          _buildDateField(
            "First Aid/CPR Expiration Date",
            _selectedFirstAidCprExpirationDate,
            'firstAid',
          ),
          SizedBox(height: responsive.verticalSpacing),
          _buildDateField(
            "Background Record Check Expiration date",
            _selectedBackgroundRecordCheckExpirationDate,
            'background',
          ),
          SizedBox(height: responsive.verticalSpacing),
          _buildDateField(
            "Physical Checkup Date",
            _selectedPhysicalCheckupDate,
            'physical',
          ),
          SizedBox(height: responsive.verticalSpacing),
          CustomDropdown(
            label: "Physical Checkup Status",
            hintText: 'Select an option',
            items: _physicalCheckupStatusOptions,
            selectedItem: _selectedPhysicalCheckupStatus,
            labelStyle: TextStyle(
              fontSize: responsive.labelFontSize,
              fontFamily: "Manrope",
              fontWeight: FontWeight.w400,
              color: const Color(0xff573353),
            ),
            labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
            onSelect: (val) {
              setState(() {
                _selectedPhysicalCheckupStatus =
                    val ?? _selectedPhysicalCheckupStatus;
              });

              if (_selectedPhysicalCheckupDate == null) return;
              final today = _todayDateOnly();
              final pickedOnly = _dateOnly(_selectedPhysicalCheckupDate!);
              final statusUpper =
                  (_selectedPhysicalCheckupStatus ?? '').trim().toUpperCase();
              final isDueScheduled = statusUpper == 'DUE' ||
                  statusUpper == 'SCHEDULED' ||
                  statusUpper == 'OVERDUE';

              if (isDueScheduled && pickedOnly.isBefore(today)) {
                setState(() => _selectedPhysicalCheckupDate = null);
                CoreUtils.showTopSnackBar(
                  context: context,
                  message:
                      'For Due/Scheduled status, Physical Checkup Date must be today or future',
                  isError: true,
                );
                return;
              }

              if (statusUpper == 'COMPLETED' && pickedOnly.isAfter(today)) {
                setState(() => _selectedPhysicalCheckupDate = null);
                CoreUtils.showTopSnackBar(
                  context: context,
                  message:
                      'For Completed status, Physical Checkup Date must be today or past',
                  isError: true,
                );
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
      bottomBar: Container(
        padding: EdgeInsets.only(
          bottom: safeAreaBottom, left: 16, right: 16, top: 8,
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
          confirmButtonLabel: 'Save',
          onPressedConfirm: isSubmitting ? null : _saveImportantDates,
          showCancelButton: false,
          isForm: false,
          isLoading: isSubmitting,
        ),
      ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateField(
    String label, 
    DateTime? selectedDate,
    String fieldName,
  ) {
    final responsive = ResponsiveHelper(context);
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: "Manrope",
      fontWeight: FontWeight.w400,
      color: const Color(0xff573353),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Simple label (no required asterisk; all fields are optional)
        Text(label, style: labelStyle),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        // Date field container with CustomDropdown styling
        GestureDetector(
          onTap: () => _selectDate(fieldName),
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      selectedDate != null 
                          ? DateFormat('MMM dd, yyyy').format(selectedDate)
                          : 'Select Date',
                      style: TextStyle(
                        color: selectedDate == null 
                            ? AppColors.primaryColor.withOpacity(0.6)
                            : AppColors.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SvgPicture.asset(
                    MediaRes.calender_icon,
                    height: 20.0,
                    colorFilter: const ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
