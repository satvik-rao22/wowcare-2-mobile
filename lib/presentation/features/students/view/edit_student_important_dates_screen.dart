import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/student/entities/student_important_dates.dart';
import 'package:wowcare/presentation/features/students/cubit/student_important_dates_cubit.dart';
import 'package:wowcare/app/di/di.dart';

class EditStudentImportantDatesScreen extends StatefulWidget {
  const EditStudentImportantDatesScreen({
    super.key,
    required this.studentCode,
    this.initialEnrollDate,
    this.initialSchoolStartDate,
  });

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
  DateTime? _enrollDate;
  DateTime? _schoolStartDate;

  @override
  void initState() {
    super.initState();
    _cubit = serviceLocator<StudentImportantDatesCubit>();
    _enrollDate = widget.initialEnrollDate;
    _schoolStartDate = widget.initialSchoolStartDate;
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
        current = _enrollDate;
        break;
      case 'schoolStart':
        current = _schoolStartDate;
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
        setState(() {
          if (field == 'enroll') {
            _enrollDate = selected;
          } else if (field == 'schoolStart') {
            _schoolStartDate = selected;
          }
        });
      }
    } catch (e) {
      CoreUtils.logApiError(e.toString());
    }
  }

  void _save() {
    final dates = StudentImportantDates(
      enrollDate: _enrollDate,
      schoolStartDate: _schoolStartDate,
    );

    _cubit.updateImportantDates(studentCode: widget.studentCode, dates: dates);
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
                Navigator.pop(context, true);
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
                      title: 'Edit Important Dates',
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isTablet = constraints.maxWidth > 600;

                          if (isTablet) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildDateField(
                                    label: 'Enroll Date',
                                    selectedDate: _enrollDate,
                                    fieldName: 'enroll',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDateField(
                                    label: 'School Start Date',
                                    selectedDate: _schoolStartDate,
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
                                label: 'Enroll Date',
                                selectedDate: _enrollDate,
                                fieldName: 'enroll',
                              ),
                              SizedBox(height: responsive.verticalSpacing),
                              _buildDateField(
                                label: 'School Start Date',
                                selectedDate: _schoolStartDate,
                                fieldName: 'schoolStart',
                              ),
                            ],
                          );
                        },
                      ),
                      bottomBar: Container(
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
                            topLeft: Radius.circular(
                              responsive.isTablet ? 40.0 : 24.0,
                            ),
                            topRight: Radius.circular(
                              responsive.isTablet ? 40.0 : 24.0,
                            ),
                          ),
                        ),
                        child: CustomButtonLayout(
                          confirmButtonLabel: 'Save',
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
      fontFamily: 'Manrope',
      fontWeight: FontWeight.w400,
      color: const Color(0xFF0A1C5D),
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
              color: Colors.white,
              border: Border.all(color: const Color(0x660A1C5D)),
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
                          : 'Select Date',
                      style: TextStyle(
                        color: selectedDate == null
                            ? Colors.grey
                            : Colors.black,
                        fontSize: responsive.inputFontSize,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                  SvgPicture.asset(
                    MediaRes.calender_icon,
                    height: responsive.isTablet ? 28.0 : 24.0,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primaryColor,
                      BlendMode.srcIn,
                    ),
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
