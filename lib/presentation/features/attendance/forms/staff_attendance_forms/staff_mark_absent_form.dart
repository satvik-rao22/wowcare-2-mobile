import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/cubit/staff_mark_absent_cubit.dart';
import 'staff_entity.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';

class StaffMarkAbsentForm extends StatefulWidget {
  const StaffMarkAbsentForm({super.key, this.staff, this.staffList});

  final StaffEntity? staff;
  final List<StaffEntity>? staffList;

  static const String routeName = '/staff-mark-absent-form';

  @override
  State<StaffMarkAbsentForm> createState() => _StaffMarkAbsentFormState();
}

class _StaffMarkAbsentFormState extends State<StaffMarkAbsentForm> {
  late final StaffMarkAbsentFormCubit _cubit;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = serviceLocator<StaffMarkAbsentFormCubit>()
      ..init(staff: widget.staff, staffList: widget.staffList);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _reasonController.dispose();
    _typeController.dispose();
    // ignore: discarded_futures
    _cubit.close();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final outcome = await _cubit.submit(
      reason: _reasonController.text,
      type: _typeController.text,
      notes: _notesController.text,
    );
    if (!mounted) return;
    if (outcome.success) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: SnackBar(
          content: Text(outcome.message ?? 'Marked Absent successfully'),
          backgroundColor: AppColors.successColor,
        ),
      );
      if (outcome.returnToTabbedView) {
        context.go(StaffAttendanceTabbedView.routeName);
      } else {
        if (context.canPop()) {
          context.pop();
        } else {
          Navigator.of(context).pop();
        }
      }
    } else {
      final message = outcome.error != null
          ? ApiErrorHandler.extractErrorMessage(outcome.error)
          : outcome.message;
      // `noop` (already submitting / empty selection) carries no message.
      if (message == null) return;
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: SnackBar(
          content: Text(message),
          backgroundColor: AppColors.warningColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffMarkAbsentFormCubit>.value(
      value: _cubit,
      child: BlocListener<StaffMarkAbsentFormCubit, StaffMarkAbsentState>(
        // Pop the form once the last staff member has been removed.
        listenWhen: (prev, curr) =>
            prev.selectedStaff.isNotEmpty && curr.selectedStaff.isEmpty,
        listener: (context, _) => Navigator.pop(context),
        child: BlocBuilder<StaffMarkAbsentFormCubit, StaffMarkAbsentState>(
          builder: (context, state) => _buildForm(context, state),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, StaffMarkAbsentState state) {
    return StaffFormLayout(
      title: 'Mark Absent',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText.label('Reason'),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'Enter absence reason',
                hintStyle: AppTextStyles.body.copyWith(
                  color: const Color.fromRGBO(87, 51, 83, 0.5),
                  fontSize: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(87, 51, 83, 0.4),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(87, 51, 83, 0.4),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(87, 51, 83, 0.4),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: AppColors.cardColor,
              ),
            ),
            // const SizedBox(height: 16),
            // const AppText.label('Absence Type'),
            // const SizedBox(height: 8),
            // TextField(
            //   controller: _typeController,
            //   decoration: InputDecoration(
            //     hintText: 'Enter absence type',
            //     hintStyle: AppTextStyles.body.copyWith(
            //       color: const Color.fromRGBO(87, 51, 83, 0.5),
            //       fontSize: 15,
            //     ),
            //     border: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(10),
            //       borderSide: const BorderSide(
            //         color: Color.fromRGBO(87, 51, 83, 0.4),
            //       ),
            //     ),
            //     enabledBorder: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(10),
            //       borderSide: const BorderSide(
            //         color: Color.fromRGBO(87, 51, 83, 0.4),
            //         width: 1,
            //       ),
            //     ),
            //     focusedBorder: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(10),
            //       borderSide: const BorderSide(
            //         color: Color.fromRGBO(87, 51, 83, 0.4),
            //         width: 2,
            //       ),
            //     ),
            //     filled: true,
            //     fillColor: AppColors.cardColor,
            //   ),
            // ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText.label('Start Date'),
                      const SizedBox(height: 8),
                      CustomDateTimeField(
                        hasLabel: false,
                        isRangePicker: false,
                        isTime: false,
                        fetchInitialTime: false,
                        initialDate: state.startDate,
                        isDisabled: state.isStaffAdminPersona == false,
                        onDateSelected: _cubit.selectStartDate,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText.label('End Date'),
                      const SizedBox(height: 8),
                      CustomDateTimeField(
                        hasLabel: false,
                        isRangePicker: false,
                        isTime: false,
                        fetchInitialTime: false,
                        initialDate: state.endDate,
                        isDisabled: state.isStaffAdminPersona == false,
                        onDateSelected: _cubit.selectEndDate,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (state.selectedStaff.isNotEmpty) ...[
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 3.5,
                ),
                itemCount: state.selectedStaff.length,
                itemBuilder: (context, index) => RemoveStaffTile(
                  staff: state.selectedStaff[index],
                  canRemove: state.selectedStaff.length > 1,
                  onRemove: () =>
                      _cubit.removeStaff(state.selectedStaff[index]),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'Enter Absent Notes',
                  hintStyle: AppTextStyles.body.copyWith(
                    color: const Color.fromRGBO(87, 51, 83, 0.5),
                    fontSize: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(87, 51, 83, 0.4),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(87, 51, 83, 0.4),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(87, 51, 83, 0.4),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.cardColor,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
      bottomBar: CustomButtonLayout(
        confirmButtonLabel: 'Submit',
        onPressedConfirm: _handleSubmit,
        showCancelButton: false,
        isLoading: state.isSubmitting,
      ),
    );
  }
}

class RemoveStaffTile extends StatelessWidget {
  final StaffEntity staff;
  final bool canRemove;
  final VoidCallback onRemove;

  const RemoveStaffTile({
    super.key,
    required this.staff,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.themeColor),
        borderRadius: BorderRadius.circular(10),
        color: const Color.fromRGBO(249, 245, 250, 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                DocumentImageWidget(
                  fileUuid: staff.photoUuid ?? '',
                  size: 30,
                  name: staff.name,
                  fontSize: 12,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    staff.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (canRemove)
            GestureDetector(
              onTap: onRemove,
              child: SvgPicture.asset(MediaRes.delete_icon),
            ),
        ],
      ),
    );
  }
}
