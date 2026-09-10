import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/students/view_model/student_important_dates_cubit.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_icon.dart';

class EditStudentImportantDatesScreen extends StatefulWidget {
  const EditStudentImportantDatesScreen({
    super.key,
    required this.studentCode,
    this.initialEnrollDate,
    this.initialSchoolStartDate,
  });

  static const String routeName = '/edit-student-important-dates';

  final String studentCode;
  final DateTime? initialEnrollDate;
  final DateTime? initialSchoolStartDate;

  @override
  State<EditStudentImportantDatesScreen> createState() =>
      _EditStudentImportantDatesScreenState();
}

class _EditStudentImportantDatesScreenState
    extends State<EditStudentImportantDatesScreen> {
  late final StudentImportantDatesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = serviceLocator<StudentImportantDatesCubit>()
      ..initialize(
        enrollDate: widget.initialEnrollDate,
        schoolStartDate: widget.initialSchoolStartDate,
      );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _selectDate(String field) async {
    DateTime? current;
    switch (field) {
      case 'enroll':
        current = _cubit.state.enrollDate;
        break;
      case 'schoolStart':
        current = _cubit.state.schoolStartDate;
        break;
    }

    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => CalendarDialog(
          isRangePicker: false,
          isTimePicker: false,
          initialDate: current,
        ),
      );

      if (result != null && result['date'] != null) {
        final selected = result['date'] as DateTime;
        if (field == 'enroll') {
          _cubit.setEnrollDate(selected);
        } else if (field == 'schoolStart') {
          _cubit.setSchoolStartDate(selected);
        }
      }
    } catch (e) {
      CoreUtils.logApiError(e.toString());
    }
  }

  void _save() {
    _cubit.save(studentCode: widget.studentCode);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return BlocProvider<StudentImportantDatesCubit>.value(
      value: _cubit,
      child:
          BlocListener<StudentImportantDatesCubit, StudentImportantDatesState>(
            listener: (context, state) {
              if (state.isSuccess && state.message != null) {
                CoreUtils.showTopSnackBar(
                  context: context,
                  message: state.message!,
                  isSuccess: true,
                );
                context.pop(true);
              } else if (state.isError && state.message != null) {
                CoreUtils.showTopSnackBar(
                  context: context,
                  message: state.message!,
                  isError: true,
                );
              }
            },
            child:
                BlocBuilder<
                  StudentImportantDatesCubit,
                  StudentImportantDatesState
                >(
                  builder: (context, state) {
                    final isSubmitting = state.isLoading;

                    return StaffFormLayout(
                      title: StudentStrings.editImportantDates,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isTablet = constraints.maxWidth > 600;

                          if (isTablet) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildDateField(
                                    label: StudentStrings.enrollDate,
                                    selectedDate: state.enrollDate,
                                    fieldName: 'enroll',
                                  ),
                                ),
                                AppSpacing.gapHMd,
                                Expanded(
                                  child: _buildDateField(
                                    label: StudentStrings.schoolStartDate,
                                    selectedDate: state.schoolStartDate,
                                    fieldName: 'schoolStart',
                                  ),
                                ),
                              ],
                            );
                          }

                          return ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              _buildDateField(
                                label: StudentStrings.enrollDate,
                                selectedDate: state.enrollDate,
                                fieldName: 'enroll',
                              ),
                              SizedBox(height: responsive.verticalSpacing),
                              _buildDateField(
                                label: StudentStrings.schoolStartDate,
                                selectedDate: state.schoolStartDate,
                                fieldName: 'schoolStart',
                              ),
                            ],
                          );
                        },
                      ),
                      bottomBar: Container(
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
                              color: AppColors.blackColor.withValues(
                                alpha: 0.05,
                              ),
                              offset: const Offset(0, -4),
                              blurRadius: 16,
                            ),
                          ],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(
                              responsive.isTablet ? 40.0 : 24.0,
                            ),
                            topRight: Radius.circular(
                              responsive.isTablet ? 40.0 : 24.0,
                            ),
                          ),
                        ),
                        child: CustomButtonLayout(
                          confirmButtonLabel: StudentStrings.save,
                          onPressedConfirm: isSubmitting ? null : _save,
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

  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required String fieldName,
  }) {
    final responsive = ResponsiveHelper(context);
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w400,
      color: AppColors.primaryColor,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        GestureDetector(
          onTap: () => _selectDate(fieldName),
          child: Container(
            constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              border: Border.all(color: AppColors.inputBorderColor),
              borderRadius: BorderRadius.circular(
                responsive.isTablet ? 12.0 : 8.0,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDate != null
                          ? DateFormat('MMM dd, yyyy').format(selectedDate)
                          : StudentStrings.selectDate,
                      style: TextStyle(
                        color: selectedDate == null
                            ? AppColors.attendanceMutedTextColor
                            : AppColors.blackColor,
                        fontSize: responsive.inputFontSize,
                        fontFamily: AppFonts.body,
                      ),
                    ),
                  ),
                  AppIcon(
                    MediaRes.calender_icon,
                    height: responsive.isTablet ? 28.0 : 24.0,
                    color: AppColors.primaryColor,
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
