import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/activities/widgets/date_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/input_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/ounce_input_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/staff_present_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/time_widget.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';

import '../../../../../app/di/di.dart';
import '../../../../../core/util/core_utils.dart';
import '../../cubit/bottle_activity_cubit.dart';
import '../../../../../shared/common/widgets/custom_button_layout.dart';
import '../../widgets/activity_edit_student_scope_checkboxes.dart';
import '../../widgets/activity_student_display_tile.dart';
import '../../utils/activity_description_limits.dart';
import '../../utils/activity_selected_date_prefill.dart';
import '../utils/activity_attendance_window_validator.dart';
import '../../utils/activity_staff_display.dart';
import '../activity_daily_tab.dart';
import '../widgets/activity_admin_approve_reject_bar.dart';

/// Bottle activity create/edit/view form. All form state and the
/// create/update/approve/reject flow live in [BottleActivityCubit]; this widget
/// is a pure view over that state with no `setState`. It stays a
/// `StatefulWidget` to own the description + amount controllers and the ounce
/// field key.
class BottleActivityScreen extends StatelessWidget {
  const BottleActivityScreen({
    super.key,
    this.selectedStudents,
    this.isEdit = false,
    this.activityData,
    this.readOnly = false,
  });
  final List<Map<String, dynamic>>? selectedStudents;
  final bool isEdit;
  final ActivityItem? activityData;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BottleActivityCubit>(
      create: (_) => serviceLocator<BottleActivityCubit>()
        ..init(
          isEdit: isEdit,
          readOnly: readOnly,
          activityData: activityData,
          selectedStudents: selectedStudents,
        ),
      child: _BottleActivityView(
        isEdit: isEdit,
        readOnly: readOnly,
        activityData: activityData,
      ),
    );
  }
}

class _BottleActivityView extends StatefulWidget {
  const _BottleActivityView({
    required this.isEdit,
    required this.readOnly,
    required this.activityData,
  });

  final bool isEdit;
  final bool readOnly;
  final ActivityItem? activityData;

  @override
  State<_BottleActivityView> createState() => _BottleActivityViewState();
}

class _BottleActivityViewState extends State<_BottleActivityView> {
  late final TextEditingController _descriptionController =
      TextEditingController(
        text: (widget.isEdit || widget.readOnly)
            ? (widget.activityData?.description ?? '')
            : '',
      );
  late final TextEditingController _amountController = TextEditingController(
    text: (widget.isEdit || widget.readOnly)
        ? _ounceFieldTextFromAmountRaw(widget.activityData?.amountConsumed)
        : '',
  );

  final GlobalKey<OunceInputWidgetState> _ounceFiledKey =
      GlobalKey<OunceInputWidgetState>();

  bool get _layoutAsEdit => widget.isEdit || widget.readOnly;
  bool get _canInteract => !widget.readOnly;

  /// First numeric oz value for [OunceInputWidget] (strips " OZ", labels, etc.).
  static String _ounceFieldTextFromAmountRaw(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final cleaned = raw.replaceAll(',', '').trim();
    final m = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(cleaned);
    if (m != null) return m.group(1)!;
    return '';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  BottleActivityCubit get _cubit => context.read<BottleActivityCubit>();

  double? get _amountOz => _ounceFiledKey.currentState?.validValue;

  Future<bool> _validateAttendanceWindow() {
    return validateStudentsWithinAttendanceWindow(
      context: context,
      students: _cubit.state.selectedStudentsData,
      selectedDate: _cubit.activityDate,
      selectedTime: _cubit.activityTime,
    );
  }

  Future<void> _onSaveOrAddPressed() async {
    if (_cubit.state.isSubmitting || widget.readOnly) return;

    // Admin picked a staff member other than themselves on create: verify
    // that staff is signed in right now, same use case + true/false check the
    // staff persona's own + button is gated on. Admins are never gated on
    // their OWN sign-in — only on who they're attributing the activity to.
    if (!await _cubit.verifyPickedStaffSignedIn(
      isEdit: widget.isEdit,
      isAdminDesignation: _cubit.state.isAdminDesignation,
      pickedStaffCode: _cubit.staffPresentCode,
      ownStaffCode: _cubit.state.staffCode,
    )) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Staff is not signed in. You can only add an activity for '
            'staff who are signed in.',
        isWarning: true,
      );
      return;
    }

    final outcome = widget.isEdit
        ? await _cubit.submitUpdate(
            description: _descriptionController.text,
            amountOz: _amountOz,
            onValidateAttendanceWindow: _validateAttendanceWindow,
          )
        : await _cubit.submitCreate(
            description: _descriptionController.text,
            amountOz: _amountOz,
            onValidateAttendanceWindow: _validateAttendanceWindow,
          );
    _handleOutcome(outcome);
  }

  Future<void> _approve() async {
    final outcome = await _cubit.approve(
      description: _descriptionController.text,
      amountOz: _amountOz,
      onValidateAttendanceWindow: _validateAttendanceWindow,
    );
    _handleOutcome(outcome);
  }

  Future<void> _reject() async {
    _handleOutcome(await _cubit.reject());
  }

  void _handleOutcome(ActivityFormOutcome outcome) {
    if (!mounted) return;
    switch (outcome.type) {
      case ActivityFormResultType.warning:
        CoreUtils.showTopSnackBar(
          context: context,
          message: outcome.message,
          isWarning: true,
        );
      case ActivityFormResultType.error:
        CoreUtils.showTopSnackBar(
          context: context,
          message: outcome.message,
          isError: true,
        );
      case ActivityFormResultType.successExit:
        CoreUtils.showTopSnackBar(
          context: context,
          message: outcome.message,
          isSuccess: true,
        );
        CoreUtils.exitActivityFlow(context);
      case ActivityFormResultType.successPop:
        CoreUtils.showTopSnackBar(
          context: context,
          message: outcome.message,
          isSuccess: true,
        );
        Navigator.of(context).pop(true);
      case ActivityFormResultType.noop:
        break;
    }
  }

  void _removeStudent(String name) {
    _cubit.removeStudent(name);
    if (_cubit.state.selectedStudents.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return BlocListener<BottleActivityCubit, BottleActivityState>(
      // Sync the description + amount controllers when the detail (re)loads.
      listenWhen: (prev, curr) => prev.liveActivity != curr.liveActivity,
      listener: (context, state) {
        final desc = state.liveActivity?.description ?? '';
        if (_descriptionController.text != desc) {
          _descriptionController.text = desc;
        }
        final amount = _ounceFieldTextFromAmountRaw(
          state.liveActivity?.amountConsumed,
        );
        if (_amountController.text != amount) {
          _amountController.text = amount;
        }
      },
      child: BlocBuilder<BottleActivityCubit, BottleActivityState>(
        builder: (context, state) {
          final cubit = context.read<BottleActivityCubit>();
          final selectedStudents = state.selectedStudents;
          final effectiveActivity = cubit.effectiveActivity;
          final isAdminPersona = activeAdminPersona(context);

          return StaffFormLayout(
            title: 'Bottle',
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: AbsorbPointer(
                absorbing:
                    state.isSubmitting ||
                    state.isApprovingOrRejecting ||
                    state.loadingActivityDetail,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    if (_layoutAsEdit &&
                        !(widget.isEdit &&
                            !widget.readOnly &&
                            selectedStudents.length > 1))
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: responsive.isTablet ? 3 : 2,
                          crossAxisSpacing: responsive.isTablet ? 16 : 12,
                          mainAxisSpacing: responsive.isTablet ? 16 : 12,
                          mainAxisExtent: 64,
                        ),
                        itemCount: selectedStudents.length,
                        itemBuilder: (context, index) {
                          return ActivityStudentDisplayTile(
                            name: selectedStudents[index],
                            studentCode:
                                index < state.selectedStudentsData.length
                                ? state.selectedStudentsData[index]['studentCode']
                                      as String?
                                : null,
                          );
                        },
                      )
                    else if (!_layoutAsEdit)
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(10),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: responsive.isTablet ? 3 : 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 64,
                        ),
                        itemCount: selectedStudents.length,
                        itemBuilder: (context, index) {
                          final String name = selectedStudents[index];
                          return ActivityStudentDisplayTile(
                            name: name,
                            studentCode:
                                index < state.selectedStudentsData.length
                                ? state.selectedStudentsData[index]['studentCode']
                                      as String?
                                : null,
                            onRemove: () => _removeStudent(name),
                          );
                        },
                      ),
                    if (widget.isEdit &&
                        !widget.readOnly &&
                        selectedStudents.length > 1) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ActivityEditStudentScopeCheckboxes(
                          studentNames: selectedStudents,
                          checkedIndices: state.scopedEditStudentIndices,
                          onChanged: cubit.setScopedEditStudentIndices,
                        ),
                      ),
                    ],
                    SizedBox(height: responsive.verticalSpacing),
                    Row(
                      children: [
                        Flexible(
                          child: _layoutAsEdit
                              ? DateWidget(
                                  isEditable: false,
                                  isRequired: true,
                                  initialDate: effectiveActivity.date,
                                  onDateChanged: cubit.setActivityDate,
                                )
                              : DateWidget(
                                  isEditable: false,
                                  isRequired: true,
                                  initialDate: formatSelectedDateForDateWidget(
                                    cubit.activityDate,
                                  ),
                                  onDateChanged: cubit.setActivityDate,
                                ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: _layoutAsEdit
                              ? TimeWidget(
                                  isEditable: _canInteract,
                                  isRequired: true,
                                  prefilledTime: effectiveActivity.time,
                                  onTimeChanged: cubit.setActivityTime,
                                )
                              : TimeWidget(
                                  isRequired: true,
                                  isEditable: true,
                                  onTimeChanged: cubit.setActivityTime,
                                ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.verticalSpacing),
                    if (_layoutAsEdit)
                      OunceInputWidget(
                        key: _ounceFiledKey,
                        label: 'Amount(OZ)',
                        isRequired: true,
                        min: 0.5,
                        max: 20.0,
                        controller: _amountController,
                        readOnly: !_canInteract,
                      )
                    else
                      OunceInputWidget(
                        key: _ounceFiledKey,
                        label: 'Amount(OZ)',
                        isRequired: true,
                        min: 0.5,
                        max: 20.0,
                      ),
                    SizedBox(height: responsive.verticalSpacing),
                    Builder(
                      builder: (context) {
                        final isAdminPersona = state.isAdminDesignation;
                        final lockToLoggedInStaff =
                            _canInteract && !isAdminPersona;
                        return StaffPresentWidget(
                          staffName: staffPresentLabelForActivity(
                            layoutAsEdit: _layoutAsEdit,
                            activityCreatedBy: '',
                            loggedInDisplayName: state.staffName,
                            staffLabelFromParameters: _layoutAsEdit
                                ? (((cubit.staffPresentCode ?? '')
                                          .trim()
                                          .isNotEmpty)
                                      ? cubit.staffPresentCode
                                      : (((state.staffPresentLabelForEdit ?? '')
                                                .trim()
                                                .isNotEmpty)
                                            ? state.staffPresentLabelForEdit
                                            : effectiveActivity.staffPresent))
                                : null,
                          ),
                          isEditable: lockToLoggedInStaff
                              ? false
                              : _canInteract,
                          onStaffChanged: (_, selectedCode) {
                            cubit.setStaffPresentCode(selectedCode);
                          },
                        );
                      },
                    ),
                    SizedBox(height: responsive.verticalSpacing),
                    InputWidget(
                      controller: _descriptionController,
                      height: 100,
                      hint: 'Enter Description (optional)',
                      isRequired: false,
                      readOnly: !_canInteract,
                      maxLength: ActivityDescriptionLimits.maxLength,
                    ),
                    if (state.showRequireAdminApprovalToggle)
                      const SizedBox(height: 4),
                    if (state.showRequireAdminApprovalToggle)
                      CustomToggle(
                        label: 'Requires Admin Approval',
                        isToggled: state.requireAdminApproval,
                        labelOnLeftSide: true,
                        enabled: !_layoutAsEdit,
                        onToggle: cubit.setRequireAdminApproval,
                      ),
                    SizedBox(height: responsive.verticalSpacing),
                  ],
                ),
              ),
            ),
            bottomBar: widget.readOnly
                ? const SafeArea(child: SizedBox.shrink())
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ActivityAdminApproveRejectBar(
                            visible: cubit.showAdminApproveRejectActions(
                              isAdminPersona: isAdminPersona,
                            ),
                            isLoading:
                                state.isApprovingOrRejecting ||
                                state.isSubmitting ||
                                state.loadingActivityDetail,
                            onApprove: _approve,
                            onReject: _reject,
                          ),
                          if (!cubit.showAdminApproveRejectActions(
                            isAdminPersona: isAdminPersona,
                          ))
                            CustomButtonLayout(
                              confirmButtonLabel: widget.isEdit
                                  ? 'Save'
                                  : 'Add',
                              onPressedConfirm: _onSaveOrAddPressed,
                              showCancelButton: false,
                              isForm: false,
                              isLoading:
                                  state.isSubmitting ||
                                  state.isApprovingOrRejecting ||
                                  state.loadingActivityDetail,
                            ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
