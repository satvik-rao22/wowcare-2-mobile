import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_dimensions.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/gradient_time_picker_field.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/presentation/features/students/view_model/student_schedule_cubit.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';

class AddStudentStep3Screen extends StatefulWidget {
  const AddStudentStep3Screen({
    super.key,
    this.initialSchedule,
    this.title,
    this.primaryButtonLabel,
    this.showSkip = true,
  });

  static const String routeName = '/add-student-step3-screen';

  final Map<String, Map<String, TimeOfDay>>? initialSchedule;

  /// Optional heading; defaults to "Add Student - Step 3 of 3 (Optional)".
  final String? title;

  /// Optional primary CTA label; defaults to "Next".
  final String? primaryButtonLabel;

  /// Whether to show the "Skip" button in the bottom bar. Defaults to true.
  final bool showSkip;

  @override
  State<AddStudentStep3Screen> createState() => _AddStudentStep3ScreenState();
}

class _AddStudentStep3ScreenState extends State<AddStudentStep3Screen> {
  /// The cubit owns the schedule state + all schedule/validation logic; the
  /// screen only renders it and surfaces the error strings it returns.
  final StudentScheduleCubit _scheduleCubit =
      serviceLocator<StudentScheduleCubit>();

  @override
  void initState() {
    super.initState();
    _scheduleCubit.initialize(widget.initialSchedule);
    _loadSchoolRegularSchedules();
  }

  @override
  void dispose() {
    _scheduleCubit.close();
    super.dispose();
  }

  Future<void> _loadSchoolRegularSchedules() async {
    final schoolCode =
        (await serviceLocator<StorageService>().getString(
                  StorageKeys.schoolCode,
                ) ??
                '')
            .trim();
    if (schoolCode.isEmpty) return;
    final removedOffDays = await _scheduleCubit.loadSchoolSchedules(schoolCode);
    if (mounted && removedOffDays.isNotEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            '${removedOffDays.join(', ')} removed from the schedule — '
            'the school is closed that day.',
        isError: true,
      );
    }
  }

  void _showError(String message) {
    CoreUtils.showTopSnackBar(
      context: context,
      message: message,
      isError: true,
    );
  }

  void _onNext() {
    final error = _scheduleCubit.validateForSubmit();
    if (error != null) {
      _showError(error);
      return;
    }
    context.pop(_scheduleCubit.state.schedule);
  }

  void _onSkip() {
    context.pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return BlocBuilder<StudentScheduleCubit, StudentScheduleState>(
      bloc: _scheduleCubit,
      builder: (context, state) => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.pageBackgroundColor,
          appBar: const CustomAppBar(hasBackButton: true),
          body: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(color: AppColors.pageBackgroundColor),
              ),
              Column(
                children: [
                  AppSpacing.gapVMd,
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.horizontalSpacing,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.title ??
                            StudentStrings.addStudentStep3Of3Optional,
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: responsive.titleFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.isTablet ? 32.0 : 20.0),
                  Expanded(
                    child: Container(
                      width: responsive.containerWidth,
                      margin: EdgeInsets.symmetric(
                        horizontal: responsive.horizontalSpacing,
                      ),
                      padding: EdgeInsets.all(
                        responsive.isTablet ? 32.0 : 16.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.all(
                          Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blackColor.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                SizedBox(height: responsive.verticalSpacing),
                                Text(
                                  StudentStrings.schedule,
                                  style: TextStyle(
                                    fontSize: responsive.labelFontSize,
                                    fontFamily: AppFonts.body,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                AppSpacing.gapVXs,
                                Text(
                                  StudentStrings
                                      .selectDaysAndTimesForThisStudentDefaultTimesAr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        AppColors.attendanceDialogHintTextColor,
                                    fontFamily: AppFonts.body,
                                  ),
                                ),
                                AppSpacing.gapVSm,
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    CustomToggle(
                                      label: StudentStrings.copyToAllDays,
                                      isToggled: state.copyToAllDays,
                                      labelOnLeftSide: true,
                                      onToggle: (v) {
                                        if (v) {
                                          final err = _scheduleCubit
                                              .validateAllScheduledDays();
                                          if (err != null) {
                                            _showError(err);
                                            return;
                                          }
                                        }
                                        _scheduleCubit.setCopyToAllDays(v);
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: responsive.verticalSpacing),
                                // Day selection and time pickers
                                ..._scheduleCubit.workingDays.map(
                                  (day) => _buildDayScheduleCard(
                                    day,
                                    responsive,
                                    state,
                                  ),
                                ),
                                AppSpacing.gapVSm,
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapVSm,
                ],
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: EdgeInsets.only(
              bottom: safeAreaBottom,
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackColor.withValues(alpha: 0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 16,
                ),
              ],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
              ),
            ),
            child: Row(
              children: [
                if (widget.showSkip) ...[
                  Expanded(
                    child: Container(
                      height: responsive.buttonHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryColor),
                        borderRadius: BorderRadius.circular(
                          responsive.isTablet ? 16.0 : 8.0,
                        ),
                      ),
                      child: TextButton(
                        onPressed: _onSkip,
                        child: Text(
                          StudentStrings.skip,
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: responsive.buttonFontSize,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapHSm,
                ],
                Expanded(
                  child: Container(
                    height: responsive.buttonHeight,
                    decoration: AppSurfaces.key(KeyVariant.primary, radius: responsive.isTablet ? 16.0 : 8.0,),
                    child: TextButton(
                      onPressed: _onNext,
                      child: Text(
                        widget.primaryButtonLabel ?? StudentStrings.next,
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: responsive.buttonFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppColors.whiteColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayScheduleCard(
    String day,
    ResponsiveHelper responsive,
    StudentScheduleState state,
  ) {
    final hasSchedule = state.schedule.containsKey(day);
    final schedule = state.schedule[day];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: hasSchedule
            ? AppColors.primaryColor.withValues(alpha: 0.05)
            : AppColors.staffVeryLightGrey,
        borderRadius: AppRadius.allMd,
        border: Border.all(
          color: hasSchedule
              ? AppColors.primaryColor.withValues(alpha: 0.3)
              : AppColors.attendanceBorderLightColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: responsive.labelFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
              if (hasSchedule)
                IconButton(
                  icon: const Icon(Icons.close, size: AppDimensions.iconSm),
                  color: AppColors.errorColor,
                  onPressed: () => _scheduleCubit.removeDay(day),
                ),
            ],
          ),
          if (hasSchedule) ...[
            AppSpacing.gapVSm,
            Row(
              children: [
                Expanded(
                  child: GradientTimePickerField(
                    label: StudentStrings.startTime,
                    minuteInterval: 15,
                    time:
                        schedule!['start'] ??
                        _scheduleCubit.defaultStartForDay(day),
                    onTimeSelected: (picked) {
                      final err = _scheduleCubit.applyPickedTime(
                        day,
                        'start',
                        picked,
                      );
                      if (err != null) _showError(err);
                    },
                  ),
                ),
                AppSpacing.gapHSm,
                Expanded(
                  child: GradientTimePickerField(
                    label: StudentStrings.endTime,
                    minuteInterval: 15,
                    time:
                        schedule['end'] ?? _scheduleCubit.defaultEndForDay(day),
                    onTimeSelected: (picked) {
                      final err = _scheduleCubit.applyPickedTime(
                        day,
                        'end',
                        picked,
                      );
                      if (err != null) _showError(err);
                    },
                  ),
                ),
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    StudentStrings.holiday,
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.attendanceDialogHintTextColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _scheduleCubit.enableDay(day),
                    child: const Text(
                      StudentStrings.enable,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
