import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import '../../../../app/di/di.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../shared/common/widgets/app_text_styles.dart';
import '../../../../shared/common/widgets/custom_add_notes_field.dart';
import '../../../../shared/common/widgets/custom_button_layout.dart';
import '../../../../shared/common/widgets/custom_repeat_on_days_selector.dart';
import '../../../../shared/utils/responsive_helper.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../domain/features/staff_scheduling/entities/staff_shift.dart';
import '../../../../domain/features/staff_scheduling/repositories/staff_scheduling_repository.dart';
import '../cubit/Add-Shift/cubit/edit_and_publish_schedule_form_cubit.dart';
import '../cubit/Add-Shift/cubit/edit_and_publish_schedule_form_state.dart';

class EditShiftScreen extends StatefulWidget {
  const EditShiftScreen({super.key});

  static const String routeName = '/edit-shift';

  @override
  State<EditShiftScreen> createState() => _EditShiftScreenState();
}

class _EditShiftScreenState extends State<EditShiftScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => serviceLocator<ScheduleFormCubit>(),
      child: const EditShiftForm(),
    );
  }
}

class EditShiftForm extends StatefulWidget {
  const EditShiftForm({super.key});

  @override
  State<EditShiftForm> createState() => _EditShiftFormState();
}

class _EditShiftFormState extends State<EditShiftForm> {
  final StaffSchedulingRepository _repository =
      serviceLocator<StaffSchedulingRepository>();

  bool _isLoadingShift = false;
  StaffShiftEntity? _shift;
  String? _shiftCode;
  DateTime? _shiftDate;
  String? _classroomName;

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  TimeOfDay? _breakStartTime;
  String? selectedStaff;
  String? selectedRoom;
  String? shiftTime;
  TimeOfDay? _breakEndTime;
  bool _publish = false;

  bool _didInitArgs = false;

  int _toMinutes(TimeOfDay time) => (time.hour * 60) + time.minute;

  bool _isWithinShift(TimeOfDay t, TimeOfDay start, TimeOfDay end) {
    final value = _toMinutes(t);
    return value >= _toMinutes(start) && value <= _toMinutes(end);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitArgs) return;
    _didInitArgs = true;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      selectedStaff = args['staffName'];
      selectedRoom = args['classroom']?.toString();
      _classroomName = args['classroomName']?.toString() ?? selectedRoom;
      shiftTime = args['shift'];
      _shiftCode = args['shiftCode']?.toString();
    }

    final code = _shiftCode;
    if (code != null && code.trim().isNotEmpty) {
      _loadShift(code);
    }
  }

  Future<void> _loadShift(String code) async {
    setState(() {
      _isLoadingShift = true;
    });

    try {
      final shift = await _repository.getShiftByCode(code);
      if (!mounted) return;

      if (shift == null) {
        setState(() {
          _shift = null;
          _isLoadingShift = false;
        });
        return;
      }

      TimeOfDay? parseTime(String? hhmmss) {
        if (hhmmss == null) return null;
        final parts = hhmmss.split(':');
        if (parts.length < 2) return null;
        return TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }

      final shiftDate = DateTime.tryParse(shift.shiftDate);

      setState(() {
        _shift = shift;
        _shiftDate = shiftDate;
        _startTime = parseTime(shift.startTime);
        _endTime = parseTime(shift.endTime);
        _breakStartTime = parseTime(shift.breakStartTime);
        _breakEndTime = parseTime(shift.breakEndTime);
        _publish = shift.shiftStatus.toUpperCase() == 'PUBLISHED';
        selectedStaff = selectedStaff ?? shift.staffFullName;
        selectedRoom = selectedRoom ?? shift.classroomCode;
        _classroomName = _classroomName ?? shift.classroomCode;
        _isLoadingShift = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingShift = false);
      CoreUtils.logApiError(e.toString());
    }
  }

  bool _validateTimes() {
    if (_startTime == null || _endTime == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select shift start and end time',
        isWarning: true,
      );
      return false;
    }

    if (_toMinutes(_startTime!) >= _toMinutes(_endTime!)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Shift end time must be after shift start time',
        isWarning: true,
      );
      return false;
    }

    if ((_breakStartTime == null) != (_breakEndTime == null)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select both break start and break end time',
        isWarning: true,
      );
      return false;
    }

    if (_breakStartTime != null && _breakEndTime != null) {
      if (!_isWithinShift(_breakStartTime!, _startTime!, _endTime!) ||
          !_isWithinShift(_breakEndTime!, _startTime!, _endTime!)) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Break time must be within the selected shift range',
          isWarning: true,
        );
        return false;
      }
      if (_toMinutes(_breakStartTime!) >= _toMinutes(_breakEndTime!)) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Break end time must be after break start time',
          isWarning: true,
        );
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return BlocListener<ScheduleFormCubit, ScheduleFormState>(
      listener: (context, state) {
        if (state is ScheduleFormSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shift updated successfully')),
          );
          Navigator.pushNamed(context, EditShiftScreen.routeName);
        } else if (state is ScheduleFormError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
        }
      },
      child: BlocBuilder<ScheduleFormCubit, ScheduleFormState>(
        builder: (context, state) {
          return GlobalScaffold(
            hasBackButton: true,
            customButtonLayout: _buildBottomButton(context, state, responsive),
            showCustomNavigationBar: false,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppText.body(
                        'Edit Shift',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 24,
                        ),
                      ),
                      Spacer(),
                      Container(
                        height: 40,
                        width: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.errorColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            MediaRes.delete_icon,
                            height: 20,
                            width: 20,
                            colorFilter: const ColorFilter.mode(
                              AppColors.cardColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Card(
                    elevation: 0,
                    color: AppColors.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        responsive.isTablet ? 24.0 : 16.0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isLoadingShift)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: CustomDateTimeField(
                                  label: 'Date',
                                  isRequired: true,
                                  initialDate: _shiftDate,
                                  fetchInitialTime: false,
                                  onDateSelected: (_) {},
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomDropdown(
                                  hintText: 'Classroom',
                                  label: 'Classroom',
                                  isRequired: true,
                                  selectedItem:
                                      (_classroomName ?? selectedRoom ?? '-'),
                                  items: [
                                    (_classroomName ?? selectedRoom ?? '-'),
                                  ],
                                  onSelect: (_) {},
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          CustomDropdown(
                            hintText: 'Staff',
                            label: 'Staff',
                            isRequired: true,
                            selectedItem: selectedStaff,
                            items: selectedStaff == null
                                ? const []
                                : [selectedStaff!],
                            onSelect: (_) {},
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: CustomDateTimeField(
                                  label: 'Shift Start',
                                  isTime: true,
                                  isRequired: true,
                                  fetchInitialTime: false,
                                  initialTime: _startTime,
                                  onTimeSelected: (time) {
                                    setState(() {
                                      _startTime = time;
                                      if (_endTime != null &&
                                          _toMinutes(_startTime!) >=
                                              _toMinutes(_endTime!)) {
                                        _endTime = null;
                                      }
                                      if (_breakStartTime != null &&
                                          _endTime != null &&
                                          !_isWithinShift(
                                            _breakStartTime!,
                                            _startTime!,
                                            _endTime!,
                                          )) {
                                        _breakStartTime = null;
                                      }
                                      if (_breakEndTime != null &&
                                          _endTime != null &&
                                          !_isWithinShift(
                                            _breakEndTime!,
                                            _startTime!,
                                            _endTime!,
                                          )) {
                                        _breakEndTime = null;
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomDateTimeField(
                                  label: 'Shift End',
                                  isTime: true,
                                  isRequired: true,
                                  fetchInitialTime: false,
                                  initialTime: _endTime,
                                  onTimeSelected: (time) {
                                    if (_startTime != null &&
                                        _toMinutes(time) <=
                                            _toMinutes(_startTime!)) {
                                      CoreUtils.showTopSnackBar(
                                        context: context,
                                        message:
                                            'Shift end time must be after shift start time',
                                        isWarning: true,
                                      );
                                      return;
                                    }
                                    setState(() {
                                      _endTime = time;
                                      if (_breakStartTime != null &&
                                          !_isWithinShift(
                                            _breakStartTime!,
                                            _startTime!,
                                            _endTime!,
                                          )) {
                                        _breakStartTime = null;
                                      }
                                      if (_breakEndTime != null &&
                                          !_isWithinShift(
                                            _breakEndTime!,
                                            _startTime!,
                                            _endTime!,
                                          )) {
                                        _breakEndTime = null;
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: CustomDateTimeField(
                                  label: 'Break Start',
                                  isTime: true,
                                  isRequired: true,
                                  fetchInitialTime: false,
                                  initialTime: _breakStartTime,
                                  onTimeSelected: (time) {
                                    if (_startTime == null ||
                                        _endTime == null) {
                                      CoreUtils.showTopSnackBar(
                                        context: context,
                                        message:
                                            'Please select shift start and end time first',
                                        isWarning: true,
                                      );
                                      return;
                                    }
                                    if (!_isWithinShift(
                                      time,
                                      _startTime!,
                                      _endTime!,
                                    )) {
                                      CoreUtils.showTopSnackBar(
                                        context: context,
                                        message:
                                            'Break start must be within shift start and end time',
                                        isWarning: true,
                                      );
                                      return;
                                    }
                                    setState(() {
                                      _breakStartTime = time;
                                      if (_breakEndTime != null &&
                                          _toMinutes(_breakEndTime!) <=
                                              _toMinutes(_breakStartTime!)) {
                                        _breakEndTime = null;
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomDateTimeField(
                                  label: 'Break End',
                                  isTime: true,
                                  isRequired: true,
                                  fetchInitialTime: false,
                                  initialTime: _breakEndTime,
                                  onTimeSelected: (time) {
                                    if (_startTime == null ||
                                        _endTime == null ||
                                        _breakStartTime == null) {
                                      CoreUtils.showTopSnackBar(
                                        context: context,
                                        message:
                                            'Please select shift times and break start first',
                                        isWarning: true,
                                      );
                                      return;
                                    }
                                    if (!_isWithinShift(
                                      time,
                                      _startTime!,
                                      _endTime!,
                                    )) {
                                      CoreUtils.showTopSnackBar(
                                        context: context,
                                        message:
                                            'Break end must be within shift start and end time',
                                        isWarning: true,
                                      );
                                      return;
                                    }
                                    if (_toMinutes(time) <=
                                        _toMinutes(_breakStartTime!)) {
                                      CoreUtils.showTopSnackBar(
                                        context: context,
                                        message:
                                            'Break end time must be after break start time',
                                        isWarning: true,
                                      );
                                      return;
                                    }
                                    setState(() {
                                      _breakEndTime = time;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Checkbox(
                                value: _publish,
                                activeColor: AppColors.themeColor,
                                onChanged: (v) =>
                                    setState(() => _publish = v ?? false),
                              ),
                              const Text(
                                'Publish shift',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          CustomRepeatOnDaysSelector(
                            selectedDays: const [],
                            onSelectionChanged: (days) {},
                          ),
                          const SizedBox(height: 16),
                          CustomAddNoteButton(onSubmitted: (value) {}),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomButton(
    BuildContext context,
    ScheduleFormState state,
    ResponsiveHelper responsive,
  ) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return Container(
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
        onPressedConfirm: () {
          if (!_validateTimes()) {
            return;
          }
          final code = _shiftCode;
          final shift = _shift;
          if (code == null || code.trim().isEmpty || shift == null) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: 'Missing shift code. Please go back and try again.',
              isWarning: true,
            );
            return;
          }

          String fmt(TimeOfDay t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

          final payload = <String, dynamic>{
            'staffCode': shift.staffCode,
            'classroomCode': shift.classroomCode,
            'schoolCode': shift.schoolCode,
            'organizationCode': shift.organizationCode,
            'shiftDate': shift.shiftDate,
            'startTime': fmt(_startTime!),
            'endTime': fmt(_endTime!),
            'publish': _publish,
            'repeat': false,
            'overrideConflicts': true,
            'forceAdd': false,
          };

          if (_breakStartTime != null) {
            payload['breakStartTime'] = fmt(_breakStartTime!);
          }
          if (_breakEndTime != null) {
            payload['breakEndTime'] = fmt(_breakEndTime!);
          }

          context.read<ScheduleFormCubit>().saveSchedule(
            id: code,
            data: payload,
          );
        },
        showCancelButton: false,
        isForm: false,
        isLoading: state is ScheduleFormSubmitting,
      ),
    );
  }
}
