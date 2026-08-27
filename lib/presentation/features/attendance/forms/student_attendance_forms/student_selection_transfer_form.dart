import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_school_time.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/ellipsis_tooltip_text.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/simmer_loader.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_custom.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/cubit/student_transfer_selection_cubit.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_permission_service.dart';
import 'student_transfer_form.dart';

class StudentSelectionTransferForm extends StatefulWidget {
  const StudentSelectionTransferForm({super.key});

  static const String routeName = '/student-selection-transfer-form';

  @override
  State<StudentSelectionTransferForm> createState() =>
      _StudentSelectionTransferFormState();
}

class _StudentSelectionTransferFormState
    extends State<StudentSelectionTransferForm> {
  // Selection business state (classrooms/tags/students) now lives in
  // [StudentTransferSelectionCubit]'s state. `isSelectAllChecked` is a purely
  // visual checkbox flag kept in the View (its value is deliberately NOT
  // re-derived from the selection when filters change — preserving the
  // original behaviour).
  bool isSelectAllChecked = false;
  final TextEditingController _searchController = TextEditingController();

  late final StudentTransferSelectionCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = serviceLocator<StudentTransferSelectionCubit>();
    _searchController.addListener(_onSearchChanged);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _cubit.initFilters();
    // Staff persona: pre-select their primary classroom, if resolvable.
    final defaultClassroom = _cubit.state.defaultClassroomName;
    if (defaultClassroom != null) {
      _cubit.seedDefaultClassroom(defaultClassroom);
    }
    await _loadStudents();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onSearchChanged() {
    // Search is client-only against the already-fetched list — matches the
    // original behavior (classroom/tag changes are what trigger a re-fetch).
    setState(() {});
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadStudents() async {
    await bootstrapAttendanceSchoolTimezone();
    final dateString = _formatDate(attendanceSchoolToday());
    await _cubit.loadStudents(
      fromAttendanceDate: dateString,
      toAttendanceDate: dateString,
      selectedClassroomNames: _cubit.state.selectedClassroomNames,
      selectedTagNames: _cubit.state.selectedTagNames,
    );
  }

  List<StudentEntity> _mapStudents(List<StudentAttendanceCustomItem> items) {
    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return StudentEntity(
        id: index + 1,
        studentCode: item.studentCode,
        fullName: item.studentName,
        roomId: 0,
        roomName: item.classroomName,
        classroomCode: item.classroomCode,
        photoUuid: '',
        tags: item.tagNames.map((name) => TagEntity(name: name)).toList(),
      );
    }).toList();
  }

  /// Client-side re-filter on top of the fetched (already server-narrowed)
  /// list: search text (never sent to the server here) plus a redundant-but-
  /// harmless classroom/tag re-check.
  List<StudentEntity> _filterStudents(
    List<StudentEntity> allStudents,
    List<String> selectedClassrooms,
    List<String> selectedTag,
  ) {
    return allStudents.where((student) {
      bool matchesSearch = true;
      bool matchesRoom = true;
      bool matchesTag = true;

      if (_searchController.text.isNotEmpty) {
        matchesSearch = student.fullName.toLowerCase().contains(
          _searchController.text.toLowerCase(),
        );
      }

      if (selectedClassrooms.isNotEmpty) {
        matchesRoom = selectedClassrooms.contains(student.roomName);
      }

      if (selectedTag.isNotEmpty) {
        matchesTag = student.tags.any((tag) => selectedTag.contains(tag.name));
      }

      return matchesSearch && matchesRoom && matchesTag;
    }).toList();
  }

  void _toggleSelectAll(bool? value, List<StudentEntity> visibleStudents) {
    if (value == null) return;

    _cubit.setStudentsSelected(visibleStudents, value);
    setState(() {
      isSelectAllChecked = value;
    });
  }

  void _toggleStudentSelection(
    StudentEntity student,
    bool? value,
    List<StudentEntity> visibleStudents,
  ) {
    if (value == null) return;

    // The tile always passes `value == !isSelected`, so a toggle reproduces
    // the original explicit add/remove exactly.
    _cubit.toggleStudent(student);
    final selected = _cubit.state.selectedStudents;
    setState(() {
      isSelectAllChecked = visibleStudents.every(selected.contains);
    });
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 69,
      ),
      itemCount: 8,
      itemBuilder: (context, index) =>
          const ShimmerLoaderCard(child: SizedBox()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AttendancePermissionService.hasPermissionToManageStudentAttendance(
      context,
    )) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Access Denied: You must be inside geofence and signed in to manage student attendance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    return BlocBuilder<
      StudentTransferSelectionCubit,
      StudentTransferSelectionState
    >(
      bloc: _cubit,
      builder: (context, state) {
        final allStudents = _mapStudents(state.students);
        final visibleStudents = _filterStudents(
          allStudents,
          state.selectedClassroomNames,
          state.selectedTagNames,
        );
        // Pruning of stale selections happens in the cubit's loadStudents (when
        // the underlying list changes), not as a build-time side-effect.

        return StaffFormLayout(
          title: 'Transfer',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText.subtitle('Select Students'),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.r15),
                  border: Border.all(color: Colors.grey),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search Students',
                    hintStyle: AppTextStyles.body.copyWith(
                      color: Colors.grey[700],
                    ),
                    border: InputBorder.none,
                    icon: const Icon(Icons.search, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: CustomMultiSelectDropdown(
                      hintText: 'Classroom',
                      items: state.classroomOptions,
                      selectedItems: state.selectedClassroomNames,
                      onChanged: (selectedItems) {
                        if (state.isLoadingFilters) return;
                        _cubit.setSelectedClassrooms(selectedItems);
                        _loadStudents();
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 4,
                    child: CustomMultiSelectDropdown(
                      hintText: 'Tags',
                      items: state.tagOptions,
                      selectedItems: state.selectedTagNames,
                      onChanged: (selectedItems) {
                        _cubit.setSelectedTags(selectedItems);
                        _loadStudents();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: CustomCheckbox(
                      borderColor: AppColors.themeColor,
                      value: isSelectAllChecked,
                      onChanged: (value) =>
                          _toggleSelectAll(value, visibleStudents),
                    ),
                  ),
                  const AppText.body('Select All'),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: state.isLoadingStudents
                    ? _buildShimmerGrid()
                    : state.studentsError != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppText.body(
                              state.studentsError ?? 'Failed to load students',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            TextButton(
                              onPressed: _loadStudents,
                              child: const AppText.body('Retry'),
                            ),
                          ],
                        ),
                      )
                    : visibleStudents.isEmpty
                    ? const Center(child: AppText.body('No students found'))
                    : GridView.builder(
                        shrinkWrap: false,
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              mainAxisExtent: 72,
                            ),
                        itemCount: visibleStudents.length,
                        itemBuilder: (context, index) {
                          final student = visibleStudents[index];
                          final isSelected = state.selectedStudents.contains(
                            student,
                          );

                          return StudentListItem(
                            student: student,
                            isSelected: isSelected,
                            onSelectionChanged: (value) {
                              _toggleStudentSelection(
                                student,
                                value,
                                visibleStudents,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          bottomBar: Padding(
            padding: EdgeInsets.only(bottom: safeAreaBottom),
            child: CustomButtonLayout(
              confirmButtonLabel: 'Next',
              onPressedConfirm: () {
                final selectedStudents = state.selectedStudents;
                final selectedClassrooms = state.selectedClassroomNames;
                if (selectedStudents.isEmpty) {
                  CoreUtils.showTopSnackBarFromSnackBar(
                    context: context,
                    snackBar: const SnackBar(
                      content: Text('Please select at least one student'),
                      backgroundColor: AppColors.warningColor,
                    ),
                  );
                  return;
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentTransferForm(
                        students: selectedStudents.toSet().toList(),
                        classroomNameToCode: state.classroomCodeByName,
                        // Students were picked from this single room, so
                        // it's their current one — the student record can
                        // still name their enrolled room after a transfer.
                        // With more than one classroom selected there's no
                        // single "current" room to exclude from the
                        // destination list, so leave it unset (same as when
                        // no classroom filter is applied at all).
                        currentClassroomCode: selectedClassrooms.length == 1
                            ? state.classroomCodeByName[selectedClassrooms
                                  .single]
                            : null,
                        currentClassroomName: selectedClassrooms.length == 1
                            ? selectedClassrooms.single
                            : null,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class StudentListItem extends StatelessWidget {
  final StudentEntity student;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;

  const StudentListItem({
    Key? key,
    required this.student,
    required this.isSelected,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onSelectionChanged(!isSelected);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.themeColor),
          borderRadius: AppRadius.allSm,
          color: isSelected
              ? const Color.fromARGB(255, 249, 245, 250)
              : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xxs),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: CustomCheckbox(
                  borderColor: AppColors.themeColor,
                  value: isSelected,
                  onChanged: onSelectionChanged,
                ),
              ),
              DocumentImageWidget(
                fileUuid: student.photoUuid,
                name: student.fullName,
                studentCode: student.studentCode,
                size: 32,
                fontSize: 14,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: EllipsisTooltipText(
                  text: student.fullName,
                  maxLines: 2,
                  preferLongPress: true,
                  style: const TextStyle(
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
    );
  }
}
