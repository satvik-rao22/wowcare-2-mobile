import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_school_time.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_search_field.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_select_all_row.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_selectable_person_tile.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_selection_shimmer_grid.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_custom.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/view_model/student_transfer_selection_cubit.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_permission_service.dart';
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

  @override
  Widget build(BuildContext context) {
    if (!AttendancePermissionService.hasPermissionToManageStudentAttendance(
      context,
    )) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Access Denied: You must be inside geofence and signed in to manage student attendance.',
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(color: AppColors.errorColor),
            ),
          ),
        ),
      );
    }

    final safeAreaBottom = MediaQuery.paddingOf(context).bottom;

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
              AttendanceSearchField(
                controller: _searchController,
                hintText: 'Search Students',
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
              AttendanceSelectAllRow(
                isChecked: isSelectAllChecked,
                onChanged: (value) => _toggleSelectAll(value, visibleStudents),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: state.isLoadingStudents
                    ? const AttendanceSelectionShimmerGrid()
                    : state.studentsError != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppText.body(
                              state.studentsError ?? 'Failed to load students',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.errorColor,
                              ),
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

                          return AttendanceSelectablePersonTile(
                            name: student.fullName,
                            photoUuid: student.photoUuid ?? '',
                            code: student.studentCode,
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
                  // GoRouter holdout (documented): carries a refreshCallback closure and a form-local StudentEntity list, which don't fit GoRouter's URL/extra model — kept as an imperative Navigator.push.
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
