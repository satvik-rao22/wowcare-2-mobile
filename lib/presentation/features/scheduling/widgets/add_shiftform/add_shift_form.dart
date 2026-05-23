import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timezone/timezone.dart';
import 'package:wowcare/app/di/di.dart' show serviceLocator;
import '../../../../../app/theme/colors.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/storage/storage_service.dart';
import '../../../../../core/util/core_utils.dart';
import '../../../../../core/util/school_timezone_resolver.dart';
import '../../../../../domain/features/staff/entities/staff_profile.dart';
import '../../../../../domain/features/staff/repositories/staff_repository.dart';
import '../../../../../shared/common/widgets/custom_add_notes_field.dart';
import '../../../../../shared/common/widgets/custom_button_layout.dart';
import '../../../../../shared/common/widgets/custom_date_time_field.dart';
import '../../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../../shared/common/widgets/custom_repeat_on_days_selector.dart';
import '../../../../../shared/common/widgets/custom_scaffold.dart';
import '../../../../../shared/common/widgets/gradient_time_picker_field.dart';
import '../../../../../shared/utils/responsive_helper.dart';
import '../../../classroom/cubit/classroom_cubit.dart';
import '../../../staff/cubit/staff_cubit.dart';
import '../../cubit/Add-Shift/cubit/add_shift_cubit.dart';
import '../../cubit/Add-Shift/cubit/edit_and_publish_schedule_form_cubit.dart';
import '../../cubit/Add-Shift/cubit/edit_and_publish_schedule_form_state.dart';
import '../../cubit/Add-Shift/cubit/add_shift_state.dart';
import '../../../../../domain/features/staff_scheduling/entities/staff_shift.dart';

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
  String? _startShiftError;
  String? _endShiftError;
  String? _breakStartError;
  String? _breakEndError;
  List<String> _selectedDays = [];
  String _notes = '';
  List<String> _allowedClassroomCodes = [];
  List<AllowedClassroom> _allowedClassrooms = [];
  bool _isLoadingProfile = false;

  bool _isBlank(String? value) => value == null || value.trim().isEmpty;

  Future<bool> _validateAgainstSchoolTimeZone() async {
    if (_shiftDate == null || _startTime == null) {
      return true;
    }

    try {
      final schoolTimeZone =
          await SchoolTimezoneResolver.resolveForCurrentSchool(
            storage: serviceLocator<StorageService>(),
            apiClient: serviceLocator<ApiClient>(),
          );

      final location = timeZoneDatabase.locations[schoolTimeZone];

      if (location == null) return true;

      final schoolNow = TZDateTime.now(location);

      final selectedShiftDateTime = TZDateTime(
        location,
        _shiftDate!.year,
        _shiftDate!.month,
        _shiftDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      /// If selected shift is before current school time
      if (selectedShiftDateTime.isBefore(schoolNow)) {
        final result = await showDialog<bool>(
          context: context,
          builder: (_) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'School Timezone Warning',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              content: Text(
                'Selected shift time is earlier than the current school timezone time.\n\n'
                'Do you still want to schedule this shift?',
                style: const TextStyle(height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.themeColor,
                  ),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text('Schedule Anyway'),
                ),
              ],
            );
          },
        );

        return result ?? false;
      }

      return true;
    } catch (_) {
      return true;
    }
  }


  void _onConfirm() async {
    // Sync current UI selections into the Cubit before validation/submission.
    final addShiftCubit = context.read<AddShiftCubit>();
    if (_shiftDate != null) addShiftCubit.selectDate(_shiftDate!);
    if (!_isBlank(_selectedStaffCode)) {
      // Avoid re-loading profile if already selected
      if (addShiftCubit.state.selectedStaffCode != _selectedStaffCode) {
        addShiftCubit.selectStaff(_selectedStaffCode!);
      }
    }
    if (!_isBlank(_selectedClassroomCode)) {
      addShiftCubit.selectClassroom(_selectedClassroomCode!);
    }
    if (_startTime != null) addShiftCubit.selectStartTime(_startTime!);
    if (_endTime != null) addShiftCubit.selectEndTime(_endTime!);
    if (_breakStartTime != null) {
      addShiftCubit.selectBreakStart(_breakStartTime!);
    }
    if (_breakEndTime != null) {
      addShiftCubit.selectBreakEnd(_breakEndTime!);
    }
    addShiftCubit.updateRepeatDays(_selectedDays);
    addShiftCubit.updateNotes(_notes);

    final isValidSchoolTime = await _validateAgainstSchoolTimeZone();
    if (!isValidSchoolTime) return;

    if (!mounted) return;

    final validation = await addShiftCubit.validateForSubmit(context);
    if (validation == null) return;

    if (!validation.isValid) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: validation.errors.first.message,
        isWarning: true,
      );
      return;
    }

    if (validation.requiresForceAddConfirmation &&
        !addShiftCubit.state.forceAddConfirmed) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Outside Availability'),
          content: const Text(
            'You are adding a shift outside this staff’s work & break times. Do you still want to add this shift?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.themeColor,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Add Shift'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      addShiftCubit.confirmForceAdd();
    }

    if (validation.requiresOverrideConfirmation &&
        !addShiftCubit.state.overrideConfirmed) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Conflicting Shifts'),
          content: const Text(
            'Shifts already exist for this staff for the selected date(s). Do you want to override?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.themeColor,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Override'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      addShiftCubit.confirmOverride();
    }

    final request = await addShiftCubit.buildRequest(context);
    if (request == null) return;

    if (!mounted) return;
    context.read<ScheduleFormCubit>().saveSchedule(data: request);
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

  // Existing shift auto-fill is handled via AddShiftCubit and the domain layer.

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return BlocListener<AddShiftCubit, AddShiftState>(
      listener: (context, state) {
        final StaffShiftEntity? shift = state.existingShift;
        if (shift == null) return;

        TimeOfDay? parseHhmm(String? value) {
          if (value == null || value.trim().isEmpty) return null;
          final parts = value.split(':');
          if (parts.length < 2) return null;
          final h = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          if (h == null || m == null) return null;
          return TimeOfDay(hour: h, minute: m);
        }

        setState(() {
          _shiftDate = DateTime.tryParse(shift.shiftDate) ?? _shiftDate;
          _selectedClassroomCode = shift.classroomCode;
          _startTime = parseHhmm(shift.startTime);
          _endTime = parseHhmm(shift.endTime);
          _breakStartTime = parseHhmm(shift.breakStartTime);
          _breakEndTime = parseHhmm(shift.breakEndTime);
          _notes = shift.notes ?? '';
        });
      },
      child: BlocListener<ScheduleFormCubit, ScheduleFormState>(
      listener: (context, state) {
        if (state is ScheduleFormSuccess) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Shift added successfully',
            isSuccess: true,
          );

          Navigator.pop(context);
        } else if (state is ScheduleFormError) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Error: ${state.message}',
            isWarning: true,
          );
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
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Add Shift",
                      style: TextStyle(
                        fontFamily: "Manrope",
                        fontSize: responsive.titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff573353),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    color: AppColors.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        responsive.isTablet ? 40.0 : 24.0,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                        responsive.isTablet ? 32.0 : 16.0,
                      ),
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

                                          initialDate:
                                              _shiftDate, // pass current/default date

                                          labelStyle: TextStyle(
                                            fontSize: responsive.titleFontSize,
                                            fontWeight: FontWeight.w500,
                                          ),

                                          fetchInitialTime: true,

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
                                          labelStyle: TextStyle(
                                            fontSize: responsive.labelFontSize,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          isRequired: true,
                                          prependHintAsSelectableItem: false,
                                          items: staffList
                                              .map<String>(
                                                (e) => e['name'] as String,
                                              )
                                              .toList(),

                                          // onSelect: (val) async {
                                          //   final found = staffList.firstWhere(
                                          //     (e) => e['name'] == val,
                                          //     orElse: () => {},
                                          //   );

                                          //   if (found.isEmpty) return;

                                          //   setState(() {
                                          //     _selectedStaffCode =
                                          //         found['code'];
                                          //     _allowedClassroomCodes = [];
                                          //     _allowedClassrooms = [];
                                          //     _selectedClassroomCode = null;
                                          //   });

                                          //   await _loadStaffProfile(
                                          //     found['code']!,
                                          //   );

                                          //   /// AUTO SELECT PRIMARY CLASSROOM
                                          //   if (_allowedClassrooms.isNotEmpty) {
                                          //     setState(() {
                                          //       _selectedClassroomCode =
                                          //           _allowedClassrooms
                                          //               .first
                                          //               .code;
                                          //     });
                                          //   } else if (_allowedClassroomCodes
                                          //       .isNotEmpty) {
                                          //     setState(() {
                                          //       _selectedClassroomCode =
                                          //           _allowedClassroomCodes
                                          //               .first;
                                          //     });
                                          //   }
                                          // },
                                          onSelect: (val) async {
                                            final found = staffList.firstWhere(
                                              (e) => e['name'] == val,
                                              orElse: () => {},
                                            );

                                            if (found.isEmpty) return;

                                            final staffCode = found['code'];

                                            setState(() {
                                              _selectedStaffCode = staffCode;
                                              _allowedClassroomCodes = [];
                                              _allowedClassrooms = [];
                                              _selectedClassroomCode = null;
                                            });

                                            await _loadStaffProfile(staffCode!);

                                            /// AUTO SELECT PRIMARY CLASSROOM
                                            if (_allowedClassrooms.isNotEmpty) {
                                              setState(() {
                                                _selectedClassroomCode =
                                                    _allowedClassrooms
                                                        .first
                                                        .code;
                                              });
                                            } else if (_allowedClassroomCodes
                                                .isNotEmpty) {
                                              setState(() {
                                                _selectedClassroomCode =
                                                    _allowedClassroomCodes
                                                        .first;
                                              });
                                            }

                                            /// FETCH EXISTING SHIFT
                                            if (!mounted) return;
                                            context
                                                .read<AddShiftCubit>()
                                                .fetchExistingShiftForSelectedDate(
                                                  staffCode: staffCode,
                                                );
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
                                        selectedItem: classroomList.firstWhere(
                                          (e) =>
                                              e['code'] ==
                                              _selectedClassroomCode,
                                          orElse: () => {},
                                        )['name'],
                                        labelStyle: TextStyle(
                                          fontSize: responsive.labelFontSize,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        hintText: _isLoadingProfile
                                            ? 'Loading classrooms...'
                                            : 'Classroom',
                                        label: 'Classroom',
                                        isRequired: true,
                                        prependHintAsSelectableItem: false,
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
                                        child: GradientTimePickerField(
                                          isRequired: true,

                                          onTimeSelected: (value) {
                                            setState(() {
                                              _startTime = value;
                                              _startShiftError = null;
                                            });
                                          },
                                          label: 'Start Shift',
                                          // time: _startTime,
                                          errorText: _startShiftError,
                                          time: _startTime,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: GradientTimePickerField(
                                          isRequired: true,
                                          onTimeSelected: (value) {
                                            setState(() {
                                              _endTime = value;
                                              _endShiftError = null;
                                            });
                                          },
                                          label: 'End Shift',
                                          errorText: _endShiftError,
                                          time: _endTime,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GradientTimePickerField(
                                          onTimeSelected: (value) {
                                            setState(() {
                                              _breakStartTime = value;
                                              _breakStartError = null;
                                            });
                                          },
                                          errorText: _breakStartError,
                                          label: 'Break Start',
                                          time: _breakStartTime,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: GradientTimePickerField(
                                          onTimeSelected: (value) {
                                            setState(() {
                                              _breakEndTime = value;
                                              _breakEndError = null;
                                            });
                                          },
                                          errorText: _breakEndError,
                                          label: 'Break End',
                                          time: _breakEndTime,
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
                                  BlocBuilder<AddShiftCubit, AddShiftState>(
                                    builder: (context, state) {
                                      return InkWell(
                                        onTap: () => context
                                            .read<AddShiftCubit>()
                                            .setPublish(!state.publish),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: state.publish,
                                              activeColor: AppColors.themeColor,
                                              onChanged: (v) => context
                                                  .read<AddShiftCubit>()
                                                  .setPublish(v ?? false),
                                            ),
                                            const SizedBox(width: 4),
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
                                      );
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
    ),
    );
  }
}
