import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/presentation/features/classroom/view_model/assign_student_confirmation_cubit.dart';
import 'package:wowcare/presentation/features/classroom/view_model/assign_student_confirmation_state.dart';
import 'package:wowcare/presentation/features/classroom/view_model/assign_student_selection_cubit.dart';
import 'package:wowcare/presentation/features/classroom/view_model/assign_student_selection_state.dart';
import 'package:wowcare/presentation/features/classroom/forms/widgets/assign_classroom_form_widgets.dart';
import 'package:wowcare/shared/common/widgets/profile_avatar.dart';
import 'package:wowcare/shared/common/widgets/attendance_status_dot.dart';
import 'package:wowcare/shared/common/widgets/ellipsis_tooltip_text.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/confirmation_bottom_sheet.dart';
import 'package:wowcare/core/theme/app_icon.dart';

String? _studentImageUrl(Student student) {
  final raw = (student.profileImage ?? '').trim();
  return raw.isEmpty ? null : raw;
}

String? _studentAssetCode(Student student) {
  final raw = (student.profilePhotoAssetCode ?? '').trim();
  return raw.isEmpty ? null : raw;
}

class AssignStudentToClassroomForm extends StatelessWidget {
  const AssignStudentToClassroomForm({
    required this.onStudentsAssigned,
    required this.selectedRoomName,
    required this.classroomCode,
    super.key,
  });

  final VoidCallback onStudentsAssigned;
  final String selectedRoomName;
  final String classroomCode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AssignStudentSelectionCubit>(
      create: (_) =>
          serviceLocator<AssignStudentSelectionCubit>()
            ..init(classroomCode: classroomCode),
      child: _AssignStudentSelectionView(
        selectedRoomName: selectedRoomName,
        classroomCode: classroomCode,
        onStudentsAssigned: onStudentsAssigned,
      ),
    );
  }
}

class _AssignStudentSelectionView extends StatefulWidget {
  const _AssignStudentSelectionView({
    required this.selectedRoomName,
    required this.classroomCode,
    required this.onStudentsAssigned,
  });

  final String selectedRoomName;
  final String classroomCode;
  final VoidCallback onStudentsAssigned;

  @override
  State<_AssignStudentSelectionView> createState() =>
      _AssignStudentSelectionViewState();
}

class _AssignStudentSelectionViewState
    extends State<_AssignStudentSelectionView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    context.read<AssignStudentSelectionCubit>().onSearchChanged(
      _searchController.text,
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AssignStudentSelectionCubit>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AssignFormHeader(title: 'Assign to ${widget.selectedRoomName}'),
          const SizedBox(height: 16),
          const Text(
            'Select Students',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          CustomSearchBar(
            controller: _searchController,
            hintText: 'Search Students',
          ),
          const SizedBox(height: 12),
          BlocBuilder<AssignStudentSelectionCubit, AssignStudentSelectionState>(
            builder: (context, state) => Row(
              children: [
                Expanded(
                  flex: 4,
                  child: CustomDropdown(
                    onSelect: cubit.selectClassroom,
                    hintText: 'Classroom',
                    items: state.rooms
                        .where((name) => name != widget.selectedRoomName)
                        .toList(),
                    isField: true,
                    isEnabled: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: CustomMultiSelectDropdown(
                    hintText: 'Tags',
                    showSelectAll: true,
                    items: state.tags,
                    selectedItems: state.selectedTags,
                    onChanged: cubit.selectTags,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BlocBuilder<AssignStudentSelectionCubit, AssignStudentSelectionState>(
            builder: (context, state) => SelectAllCheckboxRow(
              value: state.isSelectAllChecked,
              onChanged: (value) => cubit.toggleSelectAll(value ?? false),
              checkboxBuilder: (value, onChanged) => CustomCheckbox(
                borderColor: AppColors.themeColor,
                value: value,
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child:
                BlocBuilder<
                  AssignStudentSelectionCubit,
                  AssignStudentSelectionState
                >(
                  builder: (context, state) => AssignFormResultsArea(
                    isLoading: state.isLoading,
                    errorMessage: state.errorMessage,
                    onRetry: cubit.loadStudents,
                    content: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 72,
                          ),
                      itemCount: state.visibleStudents.length,
                      itemBuilder: (context, index) {
                        final student = state.visibleStudents[index];
                        final isSelected = state.selectedStudents.contains(
                          student,
                        );
                        return StudentListItem(
                          student: student,
                          isSelected: isSelected,
                          isSignedIn: state.isStudentSignedIn(student.code),
                          onSelectionChanged: (value) =>
                              cubit.toggleStudent(student, value ?? false),
                        );
                      },
                    ),
                  ),
                ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<AssignStudentSelectionCubit, AssignStudentSelectionState>(
            builder: (context, state) => CustomButtonLayout(
              confirmButtonLabel: 'Next',
              cancelButtonLabel: 'Cancel',
              onPressedCancel: () => Navigator.pop(context),
              onPressedConfirm: () {
                if (state.selectedStudents.isEmpty) {
                  CoreUtils.showTopSnackBar(
                    context: context,
                    message: 'Please select at least one student',
                    isWarning: true,
                  );
                  return;
                }
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.transparentColor,
                  builder: (context) => DraggableScrollableSheet(
                    maxChildSize: 0.95,
                    builder: (_, controller) => StudentConfirmationForm(
                      selectedStudents: state.selectedStudents,
                      selectedRoomName: widget.selectedRoomName,
                      classroomCode: widget.classroomCode,
                      onStudentsAssigned: widget.onStudentsAssigned,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StudentConfirmationForm extends StatelessWidget {
  const StudentConfirmationForm({
    required this.selectedStudents,
    required this.selectedRoomName,
    required this.classroomCode,
    required this.onStudentsAssigned,
    super.key,
  });

  final Set<Student> selectedStudents;
  final String selectedRoomName;
  final String classroomCode;
  final VoidCallback onStudentsAssigned;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AssignStudentConfirmationCubit>(
      create: (_) => serviceLocator<AssignStudentConfirmationCubit>()
        ..init(
          initialSelection: selectedStudents,
          classroomCode: classroomCode,
        ),
      child: _StudentConfirmationView(
        selectedRoomName: selectedRoomName,
        classroomCode: classroomCode,
        onStudentsAssigned: onStudentsAssigned,
      ),
    );
  }
}

class _StudentConfirmationView extends StatelessWidget {
  const _StudentConfirmationView({
    required this.selectedRoomName,
    required this.classroomCode,
    required this.onStudentsAssigned,
  });

  final String selectedRoomName;
  final String classroomCode;
  final VoidCallback onStudentsAssigned;

  /// Shows an amber confirm listing any selected students whose age is
  /// outside the target room. Returns true to proceed (including when
  /// there's nothing to warn about, or the room's bounds/DOBs are unknown).
  Future<bool> _confirmIfAnyOutsideAgeRange(
    BuildContext context,
    AssignStudentConfirmationCubit cubit,
  ) async {
    final outside = cubit.outsideAgeRangeNames();
    if (outside.isEmpty) return true;

    final names = outside.where((n) => n.isNotEmpty).toList();
    final subject = names.isEmpty
        ? '${outside.length} selected student(s)'
        : (names.length == 1 ? names.first : names.join(', '));
    // Same phrasing as the Edit Student flow's classroomAgeRangeWarning(),
    // adapted for a possibly-multiple selection, for consistency.
    final message =
        "$subject ${names.length == 1 ? 'is' : 'are'} outside the "
        "classroom's age range. Do you want to continue?";

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparentColor,
      builder: (ctx) => ConfirmationBottomSheet(
        icon: Icons.warning_amber_rounded,
        title: message,
        confirmText: 'Continue anyway',
        cancelText: 'Cancel',
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AssignStudentConfirmationCubit>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AssignFormHeader(title: 'Assign to $selectedRoomName'),
          const SizedBox(height: 16),
          BlocBuilder<
            AssignStudentConfirmationCubit,
            AssignStudentConfirmationState
          >(
            builder: (context, state) {
              if (state.selectedStudents.isEmpty) {
                return const AssignFormEmptySelection(
                  message: 'No students selected',
                );
              }
              final studentList = state.selectedStudents.toList();
              return Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 72,
                  ),
                  itemCount: studentList.length,
                  itemBuilder: (context, index) {
                    final student = studentList[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.themeColor),
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.classroomNeutralTintColor,
                      ),
                      child: Row(
                        children: [
                          ProfileAvatar(
                            name: student.fullName,
                            imageUrl: _studentImageUrl(student),
                            assetCode: _studentAssetCode(student),
                            studentCode: student.code,
                            size: 32,
                            fontSize: 12,
                            statusDot: AttendanceStatusDot(
                              studentCode: student.code,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: EllipsisTooltipText(
                              text: student.fullName.trim().isEmpty
                                  ? 'Student'
                                  : student.fullName.trim(),
                              maxLines: 2,
                              preferLongPress: true,
                              style: const TextStyle(
                                fontFamily: AppFonts.body,
                                color: AppColors.primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => cubit.removeStudent(student),
                            child: AppIcon(
                              MediaRes.delete_icon,
                              tone: IconTone.danger,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          BlocBuilder<
            AssignStudentConfirmationCubit,
            AssignStudentConfirmationState
          >(
            builder: (context, state) => CustomButtonLayout(
              confirmButtonLabel: 'Submit',
              cancelButtonLabel: 'Cancel',
              onPressedCancel: () => Navigator.pop(context),
              onPressedConfirm: state.isSubmitting
                  ? () {}
                  : () async {
                      if (state.selectedStudents.isEmpty) {
                        CoreUtils.showTopSnackBar(
                          context: context,
                          message: 'Please select at least one student',
                          isWarning: true,
                        );
                        return;
                      }

                      // WARN (never block) if any selected student is
                      // outside the target room's age range — matching web
                      // "warn but allow".
                      final proceed = await _confirmIfAnyOutsideAgeRange(
                        context,
                        cubit,
                      );
                      if (!proceed || !context.mounted) return;

                      await submitClassroomAssignment(
                        context: context,
                        isSelectionEmpty: state.selectedStudents.isEmpty,
                        emptySelectionMessage:
                            'Please select at least one student',
                        submit: () =>
                            cubit.submit(classroomCode: classroomCode),
                        onSuccess: onStudentsAssigned,
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class StudentListItem extends StatelessWidget {
  const StudentListItem({
    required this.student,
    required this.isSelected,
    required this.onSelectionChanged,
    this.isSignedIn = false,
    super.key,
  });

  final Student student;
  final bool isSelected;
  final bool isSignedIn;
  final ValueChanged<bool?> onSelectionChanged;

  String get _disabledReason =>
      "This Student ${student.fullName.trim().isEmpty ? 'This student' : student.fullName.trim()} is already signed in. Please sign out before assigning to another classroom.";

  @override
  Widget build(BuildContext context) {
    final content = InkWell(
      onTap: () {
        if (isSignedIn) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: _disabledReason,
            isWarning: true,
          );
          return;
        }
        onSelectionChanged(!isSelected);
      },
      child: Opacity(
        opacity: isSignedIn ? 0.45 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.themeColor),
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? AppColors.classroomNeutralTintColor
                : AppColors.cardColor,
          ),
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CustomCheckbox(
                    borderColor: AppColors.themeColor,
                    value: isSelected,
                    onChanged: isSignedIn ? null : onSelectionChanged,
                  ),
                ),
                ProfileAvatar(
                  name: student.fullName,
                  imageUrl: _studentImageUrl(student),
                  assetCode: _studentAssetCode(student),
                  studentCode: student.code,
                  size: 32,
                  fontSize: 12,
                  statusDot: AttendanceStatusDot(studentCode: student.code),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: EllipsisTooltipText(
                    text: student.fullName.trim().isEmpty
                        ? 'Student'
                        : student.fullName.trim(),
                    maxLines: 2,
                    preferLongPress: true,
                    style: const TextStyle(
                      fontFamily: AppFonts.body,
                      color: AppColors.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isSignedIn) {
      return Tooltip(message: _disabledReason, child: content);
    }
    return content;
  }
}

// NOTE: Tags multi-select uses the shared `CustomMultiSelectDropdown`
// (`lib/shared/common/widgets/custom_multi_select_dropdown.dart`).
