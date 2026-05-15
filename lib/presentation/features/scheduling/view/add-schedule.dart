import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import '../../../../app/di/di.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../domain/features/staff/entities/staff_profile.dart';
import '../../../../shared/common/widgets/app_text_styles.dart';
import '../../../../shared/common/widgets/custom_add_notes_field.dart';
import '../../../../shared/common/widgets/custom_button_layout.dart';
import '../../../../shared/common/widgets/custom_repeat_on_days_selector.dart';
import '../../../../shared/utils/responsive_helper.dart';
import '../../classroom/cubit/classroom_cubit.dart';
import '../../staff/cubit/staff_cubit.dart';
import '../cubit/Add-Shift/cubit/add_shift_cubit.dart';
import '../cubit/schedule_form_cubit.dart';
import '../cubit/schedule_form_state.dart';
import 'publish-shift-schedule.dart';
import 'package:intl/intl.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';

class AddShiftScreen extends StatefulWidget {
  const AddShiftScreen({super.key});

  static const String routeName = '/add-shift';

  @override
  State<AddShiftScreen> createState() => _AddShiftScreenState();
}

class _AddShiftScreenState extends State<AddShiftScreen> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => serviceLocator<ScheduleFormCubit>()),
        BlocProvider(
          create: (context) {
            final cubit = serviceLocator<StaffCubit>();
            serviceLocator<StorageService>()
                .getString(StorageKeys.schoolCode)
                .then((code) {
                  if (code != null && code.isNotEmpty) {
                    cubit.loadStaffBySchool(code);
                  } else {
                    cubit.loadInitial();
                  }
                });
            return cubit;
          },
        ),
        BlocProvider(
          create: (context) =>
              serviceLocator<ClassroomCubit>()..loadActiveClassrooms(),
        ),
      ],
      child: BlocProvider(
        create: (_) => AddShiftCubit(
          repository: serviceLocator<StaffRepository>(),

          storageService: serviceLocator<StorageService>(),
        ),

        child: const AddShiftForm(),
      ),
    );
  }
}

class AddShiftForm extends StatefulWidget {
  const AddShiftForm({super.key});

  @override
  State<AddShiftForm> createState() => _AddShiftFormState();
}

class _AddShiftFormState extends State<AddShiftForm> {
  DateTime? _shiftDate;
  String? _selectedClassroomCode;
  String? _selectedStaffCode;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  TimeOfDay? _breakStartTime;
  TimeOfDay? _breakEndTime;
  List<String> _selectedDays = [];
  String _notes = '';
  List<String> _allowedClassroomCodes = [];
  List<AllowedClassroom> _allowedClassrooms = [];
  bool _isLoadingProfile = false;

  static const Map<String, int> _weekdayCodeByName = {
    'Monday': DateTime.monday,
    'Tuesday': DateTime.tuesday,
    'Wednesday': DateTime.wednesday,
    'Thursday': DateTime.thursday,
    'Friday': DateTime.friday,
    'Saturday': DateTime.saturday,
    'Sunday': DateTime.sunday,
  };

  List<int> get _selectedRepeatDayCodes => _selectedDays
      .map((day) => _weekdayCodeByName[day])
      .whereType<int>()
      .toList(growable: false);

  int _toMinutes(TimeOfDay time) => (time.hour * 60) + time.minute;

  String _formatTime(TimeOfDay? t) {
    if (t == null) return '00:00:00';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
  }

  bool _isWithinShift(TimeOfDay t, TimeOfDay start, TimeOfDay end) {
    final value = _toMinutes(t);
    return value >= _toMinutes(start) && value <= _toMinutes(end);
  }

  bool _validateShiftAndBreakTimes() {
    if (_startTime == null || _endTime == null) return true;

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

  void _onConfirm() async {
    if (_shiftDate == null ||
        _selectedClassroomCode == null ||
        _selectedStaffCode == null ||
        _startTime == null ||
        _endTime == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please fill all required fields',
        isWarning: true,
      );
      return;
    }

    if (!_validateShiftAndBreakTimes()) {
      return;
    }

    final storage = serviceLocator<StorageService>();
    final schoolCode = await storage.getString(StorageKeys.schoolCode);
    final organizationCode = await storage.getString(
      StorageKeys.organizationCode,
    );

    final repeatDayCodes = _selectedRepeatDayCodes;

    final cubitState = context.read<AddShiftCubit>().state;

    if (repeatDayCodes.isNotEmpty && cubitState.repeatUntilDate == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select until date for repeating schedule',
        isWarning: true,
      );
      return;
    }

    final isRecurringShift = repeatDayCodes.isNotEmpty;

    final data = {
      "staffCode": _selectedStaffCode,
      "classroomCode": _selectedClassroomCode,
      "schoolCode": schoolCode,
      "organizationCode": organizationCode,
      "shiftDate": DateFormat('yyyy-MM-dd').format(_shiftDate!),

      "startTime": _formatTime(_startTime),
      "endTime": _formatTime(_endTime),

      if (_breakStartTime != null)
        "breakStartTime": _formatTime(_breakStartTime),

      if (_breakEndTime != null) "breakEndTime": _formatTime(_breakEndTime),

      "publish": true,

      /// SINGLE SHIFT => repeat false
      /// RECURRING SHIFT => repeat true
      "repeat": isRecurringShift,

      /// ONLY FOR RECURRING SHIFT
      if (isRecurringShift) ...{
        "repeatDays": repeatDayCodes.map((e) => e - 1).toList(),
        "repeatUntilDate": DateFormat(
          'yyyy-MM-dd',
        ).format(cubitState.repeatUntilDate!),
      },

      "overrideConflicts": true,
      "forceAdd": true,

      if (_notes.isNotEmpty) "notes": _notes,
    };

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      PublishShiftScheduleScreen.routeName,
      arguments: data,
    );
  }

  Future<void> _loadStaffProfile(String staffCode) async {
    setState(() => _isLoadingProfile = true);
    try {
      final profile = await serviceLocator<StaffRepository>().getStaffProfile(
        staffCode: staffCode,
        forEditStaff: true,
      );
      if (mounted) {
        setState(() {
          _allowedClassroomCodes = profile.allowedClassroomCodes;
          _allowedClassrooms = profile.allowedClassrooms;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
        CoreUtils.logApiError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return BlocListener<ScheduleFormCubit, ScheduleFormState>(
      listener: (context, state) {
        if (state is ScheduleFormSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shift added successfully')),
          );
          Navigator.pop(context);
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
            customButtonLayout: Container(
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
                confirmButtonLabel: 'Confirm',
                onPressedConfirm: state is ScheduleFormSubmitting
                    ? null
                    : _onConfirm,
                showCancelButton: false,
                isForm: false,
                isLoading: state is ScheduleFormSubmitting,
              ),
            ),
            showCustomNavigationBar: false,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.body(
                    'Add Shift',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                      child: BlocBuilder<ClassroomCubit, ClassroomState>(
                        builder: (context, classroomState) {
                          return BlocBuilder<StaffCubit, StaffState>(
                            builder: (context, staffState) {
                              final staffList = staffState.items
                                  .map(
                                    (s) => {
                                      'code': s.code,
                                      'name': '${s.name}',
                                    },
                                  )
                                  .toList();
                              final classroomList =
                                  _allowedClassrooms.isNotEmpty
                                  ? _allowedClassrooms
                                        .map(
                                          (c) => {
                                            'code': c.code,
                                            'name': c.name,
                                          },
                                        )
                                        .toList()
                                  : classroomState.classrooms
                                        .where(
                                          (c) => _allowedClassroomCodes
                                              .contains(c.code),
                                        )
                                        .map(
                                          (c) => {
                                            'code': c.code,
                                            'name': c.name,
                                          },
                                        )
                                        .toList();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomDateTimeField(
                                          label: 'Date',
                                          isRequired: true,
                                          fetchInitialTime: false,
                                          onDateSelected: (date) {
                                            setState(() {
                                              _shiftDate = date;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: CustomDropdown(
                                          hintText: staffState.isLoading
                                              ? 'Loading staff...'
                                              : 'Staff',
                                          label: 'Staff',
                                          isRequired: true,
                                          items: staffList
                                              .map<String>(
                                                (e) => e['name'] as String,
                                              )
                                              .toList(),
                                          onSelect: (val) {
                                            final found = staffList.firstWhere(
                                              (e) => e['name'] == val,
                                              orElse: () => {},
                                            );
                                            if (found.isNotEmpty) {
                                              setState(() {
                                                _selectedStaffCode =
                                                    found['code'];
                                                _selectedClassroomCode = null;
                                                _allowedClassroomCodes = [];
                                                _allowedClassrooms = [];
                                              });
                                              _loadStaffProfile(found['code']!);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: () {
                                      if (_selectedStaffCode == null) {
                                        CoreUtils.showTopSnackBar(
                                          context: context,
                                          message:
                                              'Please select the staff first',
                                          isWarning: true,
                                        );
                                      }
                                    },
                                    child: AbsorbPointer(
                                      absorbing: _selectedStaffCode == null,
                                      child: CustomDropdown(
                                        hintText: _isLoadingProfile
                                            ? 'Loading classrooms...'
                                            : 'Classroom',
                                        label: 'Classroom',
                                        isRequired: true,
                                        items: classroomList
                                            .map((e) => e['name'] as String)
                                            .toList(),
                                        onSelect: (val) {
                                          final found = classroomList
                                              .firstWhere(
                                                (e) => e['name'] == val,
                                                orElse: () => {},
                                              );
                                          setState(() {
                                            _selectedClassroomCode =
                                                found['code'];
                                          });
                                        },
                                      ),
                                    ),
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
                                                      _toMinutes(
                                                        _breakStartTime!,
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
                                          label: 'Break End',
                                          isTime: true,
                                          isRequired: true,
                                          fetchInitialTime: false,
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
                                  CustomRepeatOnDaysSelector(
                                    selectedDays: _selectedDays,
                                    onSelectionChanged: (days) {
                                      setState(() {
                                        _selectedDays = days;
                                      });
                                    },
                                  ),

                                  const SizedBox(height: 16),
                                  CustomAddNoteButton(
                                    onSubmitted: (value) {
                                      setState(() {
                                        _notes = value;
                                      });
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
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
}
