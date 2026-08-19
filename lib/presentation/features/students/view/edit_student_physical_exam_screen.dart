import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
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

  final String studentCode;
  final DateTime? initialDate;
  final String? initialStatus;

  @override
  State<EditStudentPhysicalExamScreen> createState() =>
      _EditStudentPhysicalExamScreenState();
}

class _EditStudentPhysicalExamScreenState
    extends State<EditStudentPhysicalExamScreen> {
  DateTime? _examDate;
  String? _status;
  bool _isSaving = false;

  static const List<String> _statusOptions = <String>[
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _examDate = widget.initialDate;
    final initial = widget.initialStatus;
    if (initial != null && initial.isNotEmpty) {
      final upper = initial.toUpperCase();
      if (upper == 'COMPLETED') {
        _status = 'Completed';
      } else if (upper == 'SCHEDULED') {
        _status = 'Scheduled';
      } else if (upper == 'DUE') {
        _status = 'Due';
      } else if (upper == 'OVERDUE') {
        _status = 'Overdue';
      } else {
        _status = initial;
      }
    }
  }

  Future<void> _pickDate() async {
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => const CalendarDialog(
          isRangePicker: false,
          isTimePicker: false,
        ),
      );

      if (result != null && result['date'] != null) {
        setState(() {
          _examDate = result['date'] as DateTime;
        });
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
    if (_isSaving) return;

    if (_examDate == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Physical Checkup Date is required',
        isError: true,
      );
      return;
    }
    if (_status == null || _status!.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Physical Checkup Status is required',
        isError: true,
      );
      return;
    }

    // Map display status text back to API enum values.
    String apiStatus;
    switch ((_status ?? '').toUpperCase()) {
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
    final picked = DateTime(_examDate!.year, _examDate!.month, _examDate!.day);
    if (apiStatus == 'COMPLETED' && picked.isAfter(today)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Completed date cannot be a future date. Please select today or a past date.',
        isWarning: true,
      );
      return;
    }
    if ((apiStatus == 'SCHEDULED' || apiStatus == 'DUE') &&
        picked.isBefore(today)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            '$_status date cannot be a past date. Please select today or a future date.',
        isWarning: true,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = serviceLocator<StudentRepository>();

      await repo.addStudentPhysicalExam(
        studentCode: widget.studentCode,
        examDate: _examDate!,
        status: apiStatus,
      );

      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Physical exam added successfully',
        isSuccess: true,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      CoreUtils.logApiError(e.toString());
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomSafe = media.padding.bottom == 0 ? 16.0 : media.padding.bottom;
    final selectedDateText = _examDate != null
        ? DateFormat('MMM dd, yyyy').format(_examDate!)
        : 'Select Date';

    return StaffFormLayout(
      title: 'Add Physical Examination',
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const Text.rich(
            TextSpan(
              text: 'Physical Checkup Date',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF0A1C5D),
              ),
              children: [
                TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0x660A1C5D)),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedDateText,
                    style: TextStyle(
                      color: _examDate == null ? Colors.grey : Colors.black,
                      fontSize: 14,
                      fontFamily: 'Manrope',
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
            label: 'Physical Checkup Status',
            hintText: 'Select an option',
            items: _statusOptions,
            selectedItem: _status,
            labelStyle: const TextStyle(
              fontSize: 15,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w400,
              color: Color(0xFF0A1C5D),
            ),
            labelBottomSpacing: 6,
            onSelect: (val) => setState(() => _status = val ?? _status),
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
          color: Colors.white,
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
          confirmButtonLabel: 'Save',
          onPressedConfirm: _isSaving ? null : _save,
          showCancelButton: false,
          isForm: false,
          isLoading: _isSaving,
        ),
      ),
    );
  }
}


