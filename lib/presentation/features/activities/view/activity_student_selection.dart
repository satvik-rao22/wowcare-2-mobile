import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/activities/model/activity_route_args.dart';
import 'package:wowcare/presentation/features/activities/view/choose_activity.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_custom.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/ellipsis_tooltip_text.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_student_selection_cubit.dart';

class ActivityStudentSelection extends StatefulWidget {
  static const String routeName = CoreUtils.activityStudentSelectionRouteName;

  const ActivityStudentSelection({super.key});
  final bool showLoading = false;

  @override
  State<ActivityStudentSelection> createState() =>
      _ActivityStudentSelectionState();
}

class _ActivityStudentSelectionState extends State<ActivityStudentSelection> {
  final TextEditingController _searchController = TextEditingController();
  final Set<Map<String, dynamic>> _selectedStudents = <Map<String, dynamic>>{};

  // Filter / interaction state (UI-owned).
  String? _selectedClassroom;
  bool _selectAll = false;
  List<String> _selectedTags = [];
  DateTime _selectedAttendanceDate = AppTime.now();
  bool _filtersAdopted = false;

  late final ActivityStudentSelectionCubit _cubit;

  @override
  void initState() {
    super.initState();
    // Cubit itself is created by the router's BlocProvider (Mandate 5) — this
    // just reads the already-provided instance and kicks off the initial load.
    _cubit = context.read<ActivityStudentSelectionCubit>()..initFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    // No _cubit.close() here — the router's BlocProvider owns disposal now.
    super.dispose();
  }

  List<StudentAttendanceCustomItem> _filteredStudents(
    List<StudentAttendanceCustomItem> students,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return students;
    return students
        .where((student) => student.studentName.toLowerCase().contains(query))
        .toList();
  }

  void _updateSelectAllState(List<StudentAttendanceCustomItem> filtered) {
    if (filtered.isEmpty) {
      _selectAll = false;
      return;
    }
    _selectAll = filtered.every((student) {
      final code = student.studentCode;
      return _selectedStudents.any((s) => s['studentCode'] == code);
    });
  }

  void _showWarningMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isWarning: true,
      );
    });
  }

  String _formatAttendanceDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final yyyy = normalized.year.toString().padLeft(4, '0');
    final mm = normalized.month.toString().padLeft(2, '0');
    final dd = normalized.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  String _classroomLabelForStudent(
    StudentAttendanceCustomItem student,
    Map<String, String> classroomNameByCode,
  ) {
    final fromApi = student.classroomName.trim();
    if (fromApi.isNotEmpty) return fromApi;
    final mapped = classroomNameByCode[student.classroomCode.trim()] ?? '';
    return mapped.trim().isEmpty ? 'Classroom' : mapped.trim();
  }

  Map<String, dynamic> _buildSelectedStudentMap(
    StudentAttendanceCustomItem student, {
    required bool isNapping,
    required Map<String, String> classroomNameByCode,
  }) {
    return {
      'name': student.studentName,
      'classroom': _classroomLabelForStudent(student, classroomNameByCode),
      'classroomCode': student.classroomCode,
      'studentCode': student.studentCode,
      'profilePictureUrl': '',
      'status': '',
      'expectedToday': student.isExpectedToday,
      'signedIn': student.hasSignIn,
      'absent': false,
      'notMarked': false,
      'nappingStatus': isNapping,
      'photoPermission': true,
      'notes': '',
      'medication': '',
      'allergies': '',
      'dietaryRestriction': '',
      'signedInBy': student.signedInBy,
      'signedInTime': student.signedInTime,
      'signedOutBy': student.signedOutBy,
      'signedOutTime': student.signedOutTime,
      'attendanceDate': _formatAttendanceDate(_selectedAttendanceDate),
      'classroomCodeAmbiguousForDate': student.attendedMultipleClassroomsOnDate,
    };
  }

  void _loadStudents() {
    _cubit.loadStudents(
      selectedClassroomName: _selectedClassroom,
      selectedTagNames: _selectedTags,
      date: _selectedAttendanceDate,
    );
  }

  /// Adopt default classroom + school-today date once metadata is ready, then
  /// load students (mirrors the original post-load behaviour).
  void _onFiltersReady(ActivityStudentSelectionState state) {
    final schoolNow = SchoolZoneDateTime.schoolCalendarDateAndTimeNow(
      state.schoolTimeZone,
    ).$1;
    setState(() {
      _selectedAttendanceDate = DateTime(
        schoolNow.year,
        schoolNow.month,
        schoolNow.day,
      );
      if (_selectedClassroom == null ||
          !state.classroomOptions.contains(_selectedClassroom)) {
        _selectedClassroom = state.defaultClassroomName;
      }
    });
    if (_selectedClassroom != null) {
      _loadStudents();
    }
  }

  Future<void> _onPullRefresh() async {
    await _cubit.refreshFilters();
    if (!mounted) return;
    if (_selectedClassroom != null) {
      _loadStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<
      ActivityStudentSelectionCubit,
      ActivityStudentSelectionState
    >(
      listenWhen: (prev, curr) =>
          (curr.filtersReady && !prev.filtersReady) ||
          (curr.filtersMessage != null &&
              curr.filtersMessage != prev.filtersMessage) ||
          curr.students != prev.students,
      listener: (context, state) {
        if (state.filtersReady && !_filtersAdopted) {
          _filtersAdopted = true;
          _onFiltersReady(state);
        }
        if (state.filtersMessage != null) {
          CoreUtils.logApiError(state.filtersMessage!);
          _showWarningMessage(state.filtersMessage!);
        }
        // Recompute Select-All against the freshly loaded/filtered list,
        // mirroring the original's post-load _updateSelectAllState().
        setState(
          () => _updateSelectAllState(_filteredStudents(state.students)),
        );
      },
      builder: (context, state) => _buildScaffold(context, state),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    ActivityStudentSelectionState state,
  ) {
    final responsive = ResponsiveHelper(context);
    final safeAreaBottom = MediaQuery.paddingOf(context).bottom;
    final students = state.students;
    final filtered = _filteredStudents(students);

    return StaffFormLayout(
      title: 'Add Activity',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Students', style: AppTextStyles.activityFieldValueBold),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.activitySearchFieldBg,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.activityMutedGreyColor),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Students',
                hintStyle: AppTextStyles.activitySearchHintText,
                border: InputBorder.none,
                icon: const Icon(
                  Icons.search,
                  color: AppColors.activityMutedGreyColor,
                ),
                suffixIcon: _searchController.text.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _updateSelectAllState(_filteredStudents(students));
                          });
                        },
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.activityMutedGreyColor,
                        ),
                      ),
              ),
              onChanged: (_) {
                setState(() {
                  _updateSelectAllState(_filteredStudents(students));
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          CustomDateTimeField(
            hasLabel: false,
            initialDate: _selectedAttendanceDate,
            fetchInitialTime: false,
            onDateSelected: (date) {
              setState(() {
                _selectedAttendanceDate = DateTime(
                  date.year,
                  date.month,
                  date.day,
                );
                _selectedStudents.clear();
                _selectAll = false;
              });
              _loadStudents();
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCustomDropdown(
                  'Classroom',
                  state.classroomOptions,
                  _selectedClassroom,
                  (v) {
                    setState(() {
                      _selectedClassroom = v;
                      // Students across classrooms cannot be selected together
                      _selectedStudents.clear();
                      _selectAll = false;
                    });
                    _loadStudents();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomMultiSelectDropdown(
                  hintText: 'Tags',
                  items: state.tagOptions,
                  selectedItems: _selectedTags,
                  gapHeight: 6,
                  onChanged: (selectedItems) {
                    setState(() {
                      _selectedTags = selectedItems;
                    });
                    _loadStudents();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: CustomCheckbox(
                  value: _selectAll,
                  onChanged: (v) {
                    final newVal = v ?? false;
                    setState(() {
                      _selectAll = newVal;
                      if (newVal) {
                        for (final student in filtered) {
                          final isNapping = state.nappingStudentCodes.contains(
                            student.studentCode,
                          );
                          // A Set<Map> dedupes by object identity, not by
                          // content — a student already present (selected
                          // individually before "Select All" was tapped, or
                          // appearing twice in `filtered`) would otherwise
                          // get a second, distinct Map entry added for the
                          // same studentCode, rendering as a duplicate name.
                          _selectedStudents.removeWhere(
                            (s) => s['studentCode'] == student.studentCode,
                          );
                          _selectedStudents.add(
                            _buildSelectedStudentMap(
                              student,
                              isNapping: isNapping,
                              classroomNameByCode: state.classroomNameByCode,
                            ),
                          );
                        }
                      } else {
                        _selectedStudents.removeWhere(
                          (s) => filtered.any(
                            (st) => st.studentCode == s['studentCode'],
                          ),
                        );
                      }
                    });
                  },
                  borderColor: AppColors.themeColor,
                ),
              ),
              Text('Select All', style: AppTextStyles.activityBodyValue),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (state.classroomOptions.isNotEmpty) {
                      _selectedClassroom =
                          state.defaultClassroomName ??
                          state.classroomOptions.first;
                    }
                    _selectedStudents.clear();
                    _searchController.clear();
                    _selectedTags = [];
                    final schoolNow =
                        SchoolZoneDateTime.schoolCalendarDateAndTimeNow(
                          state.schoolTimeZone,
                        ).$1;
                    _selectedAttendanceDate = DateTime(
                      schoolNow.year,
                      schoolNow.month,
                      schoolNow.day,
                    );
                    _selectAll = false;
                  });
                  _loadStudents();
                },
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomRefreshIndicator(
              onRefresh: _onPullRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (state.isLoadingFilters || state.isLoadingStudents)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: PrimaryCircularLoader()),
                    )
                  else if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          _selectedClassroom == null
                              ? 'Select a classroom to view students or use the search bar'
                              : (state.studentsError ??
                                    'No students match the selected filters'),
                          style: AppTextStyles.activityEmptyListText,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: responsive.isTablet ? 3 : 2,
                        crossAxisSpacing: responsive.isTablet ? 16 : 12,
                        mainAxisSpacing: responsive.isTablet ? 16 : 12,
                        mainAxisExtent: 72,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final student = filtered[index];
                        final String name = student.studentName;
                        final String studentCode = student.studentCode;
                        final bool isNapping = state.nappingStudentCodes
                            .contains(studentCode);

                        final bool isSelected = _selectedStudents.any(
                          (s) => s['studentCode'] == studentCode,
                        );

                        return _ActivityStudentListItem(
                          name: name,
                          studentCode: studentCode,
                          isNapping: isNapping,
                          isSelected: isSelected,
                          onSelectionChanged: (selected) {
                            ScaffoldMessenger.of(
                              context,
                            ).removeCurrentSnackBar();
                            setState(() {
                              if (selected == true) {
                                // Same dedupe-by-studentCode guard as
                                // Select All — see its comment.
                                _selectedStudents.removeWhere(
                                  (s) => s['studentCode'] == studentCode,
                                );
                                _selectedStudents.add(
                                  _buildSelectedStudentMap(
                                    student,
                                    isNapping: isNapping,
                                    classroomNameByCode:
                                        state.classroomNameByCode,
                                  ),
                                );
                              } else {
                                _selectedStudents.removeWhere(
                                  (s) => s['studentCode'] == studentCode,
                                );
                              }
                              _updateSelectAllState(filtered);
                            });
                          },
                        );
                      }, childCount: filtered.length),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomBar: Padding(
        padding: EdgeInsets.only(bottom: safeAreaBottom),
        child: CustomButtonLayout(
          confirmButtonLabel: 'Next',
          cancelButtonLabel: 'Cancel',
          onPressedCancel: () => Navigator.of(context).pop(),
          onPressedConfirm: () {
            if (_selectedStudents.isNotEmpty) {
              final selectedDate = _formatAttendanceDate(
                _selectedAttendanceDate,
              );
              final normalizedSelectedStudents = _selectedStudents
                  .map((student) {
                    final next = Map<String, dynamic>.from(student);
                    next['attendanceDate'] = selectedDate;
                    return next;
                  })
                  .toList(growable: false);
              context.push(
                ChooseActivity.routeName,
                extra: ChooseActivityArgs(
                  selectedStudents: normalizedSelectedStudents,
                ),
              );
            } else {
              _showWarningMessage('Select at least one student.');
            }
          },
        ),
      ),
    );
  }

  Widget _buildCustomDropdown(
    String hintText,
    List<String> items,
    String? selectedItem,
    ValueChanged<String?> onSelect, {
    bool isRequired = false,
    double? height = null,
  }) {
    final responsive = ResponsiveHelper(context);
    return CustomDropdown(
      label: null,
      hintText: hintText,
      items: items,
      height: height,
      selectedItem: selectedItem,
      onSelect: onSelect,
      showAsterisk: isRequired,
      labelStyle: AppTextStyles.activityInputFieldLabel(
        fontSize: responsive.labelFontSize,
      ),
      labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
      fieldHeight: 40,
      selectedTextStyle: AppTextStyles.activityInputValueText(
        fontSize: responsive.inputFontSize,
      ),
      popupItemTextStyle: AppTextStyles.activityInputPopupItemText(
        fontSize: responsive.inputFontSize,
      ),
    );
  }
}

class _ActivityStudentListItem extends StatelessWidget {
  final String name;
  final String? studentCode;
  final bool isNapping;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;

  const _ActivityStudentListItem({
    required this.name,
    this.studentCode,
    required this.isNapping,
    required this.isSelected,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onSelectionChanged(!isSelected),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.themeColor),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? AppPalette.surfaceSelected
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
                  onChanged: onSelectionChanged,
                ),
              ),
              DocumentImageWidget(
                fileUuid: '',
                name: name,
                studentCode: (studentCode ?? '').trim().isEmpty
                    ? null
                    : studentCode!.trim(),
                size: 32,
                fontSize: 14,
              ),
              if (isNapping) ...[
                const SizedBox(width: 4),
                Image.asset(
                  MediaRes.sleepStatusIcon,
                  width: 14,
                  height: 14,
                  fit: BoxFit.contain,
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: EllipsisTooltipText(
                  text: name.trim().isEmpty ? 'Student' : name.trim(),
                  maxLines: 2,
                  preferLongPress: true,
                  style: AppTextStyles.activityCompactBoldName,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
