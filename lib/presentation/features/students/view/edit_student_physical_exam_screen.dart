import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/students/cubit/student_physical_exam_cubit.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';

class EditStudentPhysicalExamScreen extends StatefulWidget {
  const EditStudentPhysicalExamScreen({
    super.key,
    required this.studentCode,
    this.initialDate,
    this.initialStatus,
  });

  static const String routeName = '/edit-student-physical-exam';

  final String studentCode;
  final DateTime? initialDate;
  final String? initialStatus;

  @override
  State<EditStudentPhysicalExamScreen> createState() =>
      _EditStudentPhysicalExamScreenState();
}

class _EditStudentPhysicalExamScreenState
    extends State<EditStudentPhysicalExamScreen> {
  // Single cubit instance for this screen — the serviceLocator registers the
  // cubit as a factory, so holding one instance (rather than resolving per
  // call) is what keeps its single-flight guard effective. Closed in dispose.
  final StudentPhysicalExamCubit _examCubit =
      serviceLocator<StudentPhysicalExamCubit>();

  static const List<String> _statusOptions = <String>['Completed'];

  @override
  void initState() {
    super.initState();
    _examCubit.initializeForm(
      examDate: widget.initialDate,
      status: _displayStatus(widget.initialStatus),
    );
  }

  /// Map an incoming API status to the display label the dropdown shows.
  static String? _displayStatus(String? initial) {
    if (initial == null || initial.isEmpty) return null;
    switch (initial.toUpperCase()) {
      case 'COMPLETED':
        return 'Completed';
      case 'SCHEDULED':
        return 'Scheduled';
      case 'DUE':
        return 'Due';
      case 'OVERDUE':
        return 'Overdue';
      default:
        return initial;
    }
  }

  @override
  void dispose() {
    _examCubit.close();
    super.dispose();
  }

  Future<void> _pickDate() async {
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) =>
            const CalendarDialog(isRangePicker: false, isTimePicker: false),
      );

      if (result != null && result['date'] != null) {
        _examCubit.setFormExamDate(result['date'] as DateTime);
      }
    } catch (e) {
      CoreUtils.logApiError(e.toString());
    }
  }

  /// Date-only "today" in the school's timezone (falls back to the last-known
  /// zone, then UTC) — used so date validation matches the school's calendar day.
  Future<DateTime> _schoolTodayDateOnly() async {
    try {
      final tzName = await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: serviceLocator<StorageService>(),
        apiClient: serviceLocator<ApiClient>(),
      );
      return SchoolZoneDateTime.schoolCalendarTodayOnly(tzName);
    } catch (_) {
      return SchoolZoneDateTime.schoolCalendarTodayOnly(
        SchoolTimezoneResolver.lastKnownTimeZone,
      );
    }
  }

  Future<void> _save() async {
    // Re-entry guard reads the cubit's own in-flight flag (the cubit also
    // single-flights identical add calls) — no local submit bool.
    if (_examCubit.state.mutationInProgress) return;

    final examDate = _examCubit.state.formExamDate;
    final status = _examCubit.state.formStatus;

    if (examDate == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.physicalCheckupDateIsRequired,
        isError: true,
      );
      return;
    }
    if (status == null || status.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.physicalCheckupStatusIsRequired,
        isError: true,
      );
      return;
    }

    // Map display status text back to API enum values.
    String apiStatus;
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        apiStatus = 'COMPLETED';
        break;
      case 'SCHEDULED':
        apiStatus = 'SCHEDULED';
        break;
      case 'DUE':
        apiStatus = 'DUE';
        break;
      case 'OVERDUE':
        apiStatus = 'OVERDUE';
        break;
      default:
        apiStatus = 'DUE';
    }

    // Validate the date against the chosen status on the client so we can show a
    // friendly warning instead of the raw backend error. Today is always allowed.
    // "Today" must be the SCHOOL's calendar day (not the device's) so a valid
    // same-day entry isn't rejected when the device is in another timezone.
    final today = await _schoolTodayDateOnly();
    if (!mounted) return;
    final picked = DateTime(examDate.year, examDate.month, examDate.day);
    if (apiStatus == 'COMPLETED' && picked.isAfter(today)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            StudentStrings.completedDateCannotBeAFutureDatePleaseSelectTo,
        isWarning: true,
      );
      return;
    }
    if ((apiStatus == 'SCHEDULED' || apiStatus == 'DUE') &&
        picked.isBefore(today)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            '$status date cannot be a past date. Please select today or a future date.',
        isWarning: true,
      );
      return;
    }

    try {
      await _examCubit.add(
        studentCode: widget.studentCode,
        examDate: examDate,
        status: apiStatus,
      );

      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.physicalExamAddedSuccessfully,
        isSuccess: true,
      );
      context.pop(true);
    } catch (e) {
      CoreUtils.logApiError(e.toString());
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomSafe = media.padding.bottom == 0 ? 16.0 : media.padding.bottom;

    return BlocBuilder<StudentPhysicalExamCubit, StudentPhysicalExamState>(
      bloc: _examCubit,
      builder: (context, state) {
        final examDate = state.formExamDate;
        final selectedDateText = examDate != null
            ? DateFormat('MMM dd, yyyy').format(examDate)
            : StudentStrings.selectDate;

        return StaffFormLayout(
          title: StudentStrings.addPhysicalExamination,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const Text.rich(
                TextSpan(
                  text: StudentStrings.physicalCheckupDate,
                  style: TextStyle(
                    fontFamily: Fonts.manrope,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.primaryColor,
                  ),
                  children: [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.errorColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    border: Border.all(color: AppColors.inputBorderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDateText,
                        style: TextStyle(
                          color: examDate == null
                              ? AppColors.attendanceMutedTextColor
                              : AppColors.blackColor,
                          fontSize: 14,
                          fontFamily: Fonts.manrope,
                        ),
                      ),
                      SvgPicture.asset(
                        MediaRes.calender_icon,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          AppColors.primaryColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomDropdown(
                label: StudentStrings.physicalCheckupStatus,
                hintText: StudentStrings.selectAnOption,
                items: _statusOptions,
                selectedItem: state.formStatus,
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontFamily: Fonts.manrope,
                  fontWeight: FontWeight.w400,
                  color: AppColors.primaryColor,
                ),
                labelBottomSpacing: 6,
                onSelect: (val) =>
                    _examCubit.setFormStatus(val ?? state.formStatus),
              ),
            ],
          ),
          bottomBar: Container(
            padding: EdgeInsets.only(
              bottom: bottomSafe,
              left: 16,
              right: 16,
              top: 8,
            ),
            decoration: const BoxDecoration(
              color: AppColors.whiteColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, -4),
                  blurRadius: 16,
                ),
              ],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: CustomButtonLayout(
              confirmButtonLabel: StudentStrings.save,
              onPressedConfirm: state.mutationInProgress ? null : _save,
              showCancelButton: false,
              isForm: false,
              isLoading: state.mutationInProgress,
            ),
          ),
        );
      },
    );
  }
}
