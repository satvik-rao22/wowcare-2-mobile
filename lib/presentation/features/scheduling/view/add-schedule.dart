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
import '../cubit/schedule_form_cubit.dart';
import '../cubit/schedule_form_state.dart';
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
      child: const AddShiftForm(),
    );
  }
}

class AddShiftForm extends StatefulWidget {
  const AddShiftForm({super.key});

  @override
  State<AddShiftForm> createState() => _AddShiftFormState();
}

class _AddShiftFormState extends State<AddShiftForm> {
  bool _isSubmitting = false;
  DateTime? _shiftDate;
  String? _selectedClassroomCode;
  String? _selectedStaffCode;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  TimeOfDay? _breakStartTime;
  TimeOfDay? _breakEndTime;
  List<String> _selectedDays = [];
  DateTime? _repeatUntil;
  String _notes = '';
  List<String> _allowedClassroomCodes = [];
  List<AllowedClassroom> _allowedClassrooms = [];
  bool _isLoadingProfile = false;

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

    final storage = serviceLocator<StorageService>();
    final schoolCode = await storage.getString(StorageKeys.schoolCode);
    final organizationCode = await storage.getString(
      StorageKeys.organizationCode,
    );

    String formatTime(TimeOfDay? t) {
      if (t == null) return "00:00:00";
      return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00";
    }

    final data = {
      "staffCode": _selectedStaffCode,
      "classroomCode": _selectedClassroomCode,
      "schoolCode": schoolCode,
      "organizationCode": organizationCode,
      "shiftDate": DateFormat('yyyy-MM-dd').format(_shiftDate!),
      "startTime": formatTime(_startTime),
      "endTime": formatTime(_endTime),
      "breakStartTime": formatTime(_breakStartTime),
      "breakEndTime": formatTime(_breakEndTime),
      "publish": true,
      "repeat": _selectedDays.isNotEmpty,
      "overrideConflicts": true,
      "forceAdd": true,
      "notes": _notes,
    };

    if (mounted) {
      context.read<ScheduleFormCubit>().saveSchedule(data: data);
    }
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
                                          onTimeSelected: (time) {
                                            setState(() {
                                              _startTime = time;
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
                                          onTimeSelected: (time) {
                                            setState(() {
                                              _endTime = time;
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
                                          onTimeSelected: (time) {
                                            setState(() {
                                              _breakStartTime = time;
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
                                          onTimeSelected: (time) {
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
                                  CustomDateTimeField(
                                    label: 'Until Date',
                                    isRequired: true,
                                    onDateSelected: (date) {
                                      setState(() {
                                        _repeatUntil = date;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  CustomAddNoteButton(
                                    onSubmitted: (value) {
                                      print(value);
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
