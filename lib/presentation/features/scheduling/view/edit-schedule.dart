import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import '../../../../app/di/di.dart';
import '../../../../app/theme/colors.dart';
import '../../../../shared/common/widgets/app_text_styles.dart';
import '../../../../shared/common/widgets/custom_add_notes_field.dart';
import '../../../../shared/common/widgets/custom_button_layout.dart';
import '../../../../shared/common/widgets/custom_repeat_on_days_selector.dart';
import '../../../../shared/utils/responsive_helper.dart';
import '../../../../core/util/core_utils.dart';
import '../cubit/schedule_form_cubit.dart';
import '../cubit/schedule_form_state.dart';
import 'edit-shift-permission.dart';

class EditShiftScreen extends StatelessWidget {
  const EditShiftScreen({super.key});

  static const String routeName = '/edit-shift';

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
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  TimeOfDay? _breakStartTime;
  TimeOfDay? _breakEndTime;

  int _toMinutes(TimeOfDay time) => (time.hour * 60) + time.minute;

  bool _isWithinShift(TimeOfDay t, TimeOfDay start, TimeOfDay end) {
    final value = _toMinutes(t);
    return value >= _toMinutes(start) && value <= _toMinutes(end);
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
          Navigator.pushNamed(context, EditShiftScheduleScreen.routeName);
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
                  AppText.body(
                    'Edit Shift',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: CustomDateTimeField(
                                  label: 'Date',
                                  isRequired: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomDropdown(
                                  hintText: 'Room',
                                  label: 'Room',
                                  isRequired: true,
                                  items: const ['Room 1', 'Room 2', 'Room 3'],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          CustomDropdown(
                            hintText: 'Staff',
                            label: 'Staff',
                            isRequired: true,
                            items: const ['Staff 1', 'Staff 2', 'Staff 3'],
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
                            selectedDays: const [],
                            onSelectionChanged: (days) {},
                          ),
                          const SizedBox(height: 16),
                          CustomDateTimeField(
                            label: 'Until Date',
                            isRequired: true,
                            onDateSelected: (_) {},
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
          context.read<ScheduleFormCubit>().saveSchedule(
            id: '123', // In a real app, use actual ID
            data: {},
          );
        },
        showCancelButton: false,
        isForm: false,
        isLoading: state is ScheduleFormSubmitting,
      ),
    );
  }
}
