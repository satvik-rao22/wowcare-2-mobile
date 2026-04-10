import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/core_utils.dart';
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
import '../cubit/schedule_form_cubit.dart';
import '../cubit/schedule_form_state.dart';
import 'publish-shift-schedule.dart';

class AddShiftScreen extends StatelessWidget {
  const AddShiftScreen({super.key});

  static const String routeName = '/add-shift';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => serviceLocator<ScheduleFormCubit>(),
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

  void _onNext() {
    setState(() {
      Navigator.pushNamed(context, PublishShiftScheduleScreen.routeName);
      _isSubmitting = false;
    });
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
                onPressedConfirm: _isSubmitting ? null : _onNext,
                showCancelButton: false,
                isForm: false,
                isLoading: _isSubmitting,
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
                          const Row(
                            children: [
                              Expanded(
                                child: CustomDateTimeField(
                                  label: 'Shift Start',
                                  isTime: true,
                                  isRequired: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomDateTimeField(
                                  label: 'Shift End',
                                  isTime: true,
                                  isRequired: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Expanded(
                                child: CustomDateTimeField(
                                  label: 'Break Start',
                                  isTime: true,
                                  isRequired: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomDateTimeField(
                                  label: 'Break End',
                                  isTime: true,
                                  isRequired: true,
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
                          const CustomDateTimeField(
                            label: 'Until Date',
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          CustomAddNoteButton(onTap: () {}),
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
          context.read<ScheduleFormCubit>().saveSchedule(
            data: {}, // In a real app, collect form data here
          );
        },
        showCancelButton: false,
        isForm: false,
        isLoading: state is ScheduleFormSubmitting,
      ),
    );
  }
}
