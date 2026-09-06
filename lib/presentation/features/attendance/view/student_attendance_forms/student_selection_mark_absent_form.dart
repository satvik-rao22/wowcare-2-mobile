import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_school_time.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_search_field.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_select_all_row.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_selectable_person_tile.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_selection_shimmer_grid.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_absent_form.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/view_model/student_mark_absent_selection_cubit.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_permission_service.dart';
import 'student_mark_absent_form.dart';

class StudentSelectionMarkAbsentForm extends StatefulWidget {
  static const String routeName = '/student-selection-mark-absent-form';

  const StudentSelectionMarkAbsentForm({super.key});

  @override
  State<StudentSelectionMarkAbsentForm> createState() =>
      _StudentSelectionMarkAbsentFormState();
}

class _StudentSelectionMarkAbsentFormState
    extends State<StudentSelectionMarkAbsentForm> {
  bool isSelectAllChecked = false;
  List<String> _selectedClassrooms = [];
  List<String> _selectedTag = [];
  Set<StudentEntity> selectedStudents = {};
  final TextEditingController _searchController = TextEditingController();

  late final StudentMarkAbsentSelectionCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = serviceLocator<StudentMarkAbsentSelectionCubit>();
    _searchController.addListener(_onSearchChanged);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _cubit.initFilters();
    // Staff persona: pre-select their primary classroom, if resolvable.
    final defaultClassroom = _cubit.state.defaultClassroomName;
    if (defaultClassroom != null) {
      _selectedClassrooms = [defaultClassroom];
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
      fromAbsenceDate: dateString,
      toAbsenceDate: dateString,
      selectedClassroomNames: _selectedClassrooms,
      selectedTagNames: _selectedTag,
    );
  }

  List<StudentEntity> _mapStudents(
    List<StudentAttendanceAbsentFormItem> items,
  ) {
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
        tags: const [], // Absent form API does not include tags
      );
    }).toList();
  }

  /// Client-side re-filter on top of the fetched (already server-narrowed)
  /// list: search text (never sent to the server here) plus a redundant
  /// classroom re-check. Tags aren't in this endpoint's response, so
  /// `student.tags` is always empty — never re-checked locally (that would
  /// incorrectly hide every row whenever a tag is selected); the server-side
  /// `tagCodes` param is the only tag filter available for this form.
  List<StudentEntity> _filterStudents(List<StudentEntity> allStudents) {
    return allStudents.where((student) {
      bool matchesSearch = true;
      bool matchesRoom = true;

      if (_searchController.text.isNotEmpty) {
        matchesSearch = student.fullName.toLowerCase().contains(
          _searchController.text.toLowerCase(),
        );
      }

      if (_selectedClassrooms.isNotEmpty) {
        matchesRoom = _selectedClassrooms.contains(student.roomName);
      }

      return matchesSearch && matchesRoom;
    }).toList();
  }

  void _toggleSelectAll(bool? value, List<StudentEntity> visibleStudents) {
    if (value == null) return;

    setState(() {
      isSelectAllChecked = value;
      if (value) {
        selectedStudents.addAll(visibleStudents);
      } else {
        selectedStudents.removeAll(visibleStudents);
      }
    });
  }

  void _toggleStudentSelection(
    StudentEntity student,
    bool? value,
    List<StudentEntity> visibleStudents,
  ) {
    if (value == null) return;

    setState(() {
      if (value) {
        selectedStudents.add(student);
      } else {
        selectedStudents.remove(student);
      }

      isSelectAllChecked = visibleStudents.every(
        (student) => selectedStudents.contains(student),
      );
    });
  }

  void refreshCallback() {
    setState(() {
      selectedStudents = {};
    });
    _loadStudents();
  }

  void _handleNext() {
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
          builder: (context) => StudentMarkAbsentForm(
            students: selectedStudents.toList(),
            refreshCallback: refreshCallback,
          ),
        ),
      );
    }
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
      StudentMarkAbsentSelectionCubit,
      StudentMarkAbsentSelectionState
    >(
      bloc: _cubit,
      builder: (context, state) {
        final allStudents = _mapStudents(state.students);
        final visibleStudents = _filterStudents(allStudents);
        selectedStudents.removeWhere(
          (s) => !allStudents.any((e) => e.studentCode == s.studentCode),
        );

        return StaffFormLayout(
          title: 'Mark Absent',
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
                      selectedItems: _selectedClassrooms,
                      onChanged: (selectedItems) {
                        if (state.isLoadingFilters) return;
                        setState(() {
                          _selectedClassrooms = selectedItems;
                        });
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
                      selectedItems: _selectedTag,
                      onChanged: (selectedItems) {
                        setState(() {
                          _selectedTag = selectedItems;
                        });
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
                          final isSelected = selectedStudents.contains(student);

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
              onPressedConfirm: _handleNext,
              showCancelButton: false,
            ),
          ),
        );
      },
    );
  }
}
