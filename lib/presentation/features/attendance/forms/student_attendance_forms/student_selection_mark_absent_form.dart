import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_school_time.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/ellipsis_tooltip_text.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/simmer_loader.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/attendance_cross_class_resolver.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_absent_form_list_usecase.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_permission_service.dart';
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
  List<StudentEntity> _filteredStudents = [];
  Set<StudentEntity> selectedStudents = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  late final GetStudentAbsentFormListUseCase _getStudentAbsentFormListUseCase;

  // Backing list populated from the Absent form API.
  List<StudentEntity> _allStudents = [];

  // Classroom filter options loaded from Classroom API.
  List<String> _classroomList = [];
  Map<String, String> _classroomNameToCode = {};
  List<String> _tags = ['Tag 1', 'Tag 2', 'Tag 3', 'Tag 4'];

  late final ClassroomCubit _classroomCubit;
  bool _isClassroomDataReady = false;

  @override
  void initState() {
    super.initState();
    _getStudentAbsentFormListUseCase =
        serviceLocator<GetStudentAbsentFormListUseCase>();
    _classroomCubit = serviceLocator<ClassroomCubit>();
    _searchController.addListener(_onSearchChanged);
    _loadClassrooms();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterStudents();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadClassrooms() async {
    // Cross-class enabled → list ALL classrooms (like an admin); else scope to
    // the teacher's allowed classrooms.
    final crossClass =
        await AttendanceCrossClassResolver.isEnabledForCurrentSchool(
          storage: serviceLocator<StorageService>(),
        );
    _classroomCubit.loadActiveClassrooms(
      applyAttendanceStaffScope: !crossClass,
    );

    if (!_classroomCubit.state.isLoading &&
        _classroomCubit.state.classrooms.isNotEmpty) {
      setState(() {
        _classroomNameToCode = {
          for (final c in _classroomCubit.state.classrooms) c.name: c.code,
        };
        _classroomList = _classroomNameToCode.keys.toList(growable: false);
        _selectedClassrooms.removeWhere(
          (c) => !_classroomNameToCode.containsKey(c),
        );
        _isClassroomDataReady = true;
      });
      return;
    }

    int attempts = 0;
    while (_classroomCubit.state.isLoading && attempts < 100) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!mounted) return;
    setState(() {
      _classroomNameToCode = {
        for (final c in _classroomCubit.state.classrooms) c.name: c.code,
      };
      _classroomList = _classroomNameToCode.keys.toList(growable: false);
      _selectedClassrooms.removeWhere(
        (c) => !_classroomNameToCode.containsKey(c),
      );
      _isClassroomDataReady = _classroomList.isNotEmpty;
    });
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await bootstrapAttendanceSchoolTimezone();
      final today = attendanceSchoolToday();
      final dateString = _formatDate(today);

      // Resolve selected classroom NAMES -> classroomCodes via _classroomNameToCode map.
      List<String>? classroomCodes;
      if (_selectedClassrooms.isNotEmpty) {
        final codes = _selectedClassrooms
            .map((name) => _classroomNameToCode[name])
            .whereType<String>()
            .where((c) => c.trim().isNotEmpty)
            .toList();
        if (codes.isNotEmpty) {
          classroomCodes = codes;
        }
      }

      // The Absent form API doesn't return tag data on its items (unlike
      // Sign-In/Sign-Out/Transfer), so there's no name->code map to resolve
      // against — send the selected names through as-is, same as before.
      final tagCodes = _selectedTag.isNotEmpty ? _selectedTag : null;

      final searchText = _searchController.text.trim().isNotEmpty
          ? _searchController.text.trim()
          : null;

      final page = await _getStudentAbsentFormListUseCase(
        fromAbsenceDate: dateString,
        toAbsenceDate: dateString,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        search: searchText,
        page: 0,
        size: 200,
      );

      if (!mounted) return;

      var items = page.items;
      // Safety net: enforce the classroom filter client-side too, in case
      // the backend returns rows outside the requested scope. Tags aren't
      // in this endpoint's response, so there's nothing to re-check there.
      if (classroomCodes != null && classroomCodes.isNotEmpty) {
        final allowedClassrooms = classroomCodes.toSet();
        items = items
            .where((i) => allowedClassrooms.contains(i.classroomCode))
            .toList();
      }

      final students = items.asMap().entries.map((entry) {
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

      setState(() {
        _allStudents = students;
        _isLoading = false;
        _filterStudents();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = ApiErrorHandler.extractErrorMessage(e);
      });
    }
  }

  void _filterStudents() {
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        bool matchesSearch = true;
        bool matchesRoom = true;
        bool matchesTag = true;

        if (_searchController.text.isNotEmpty) {
          matchesSearch = student.fullName.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );
        }

        if (_selectedClassrooms.isNotEmpty) {
          matchesRoom = _selectedClassrooms.contains(student.roomName);
        }

        // The Absent form API doesn't return per-student tag data, so
        // `student.tags` is always empty here — re-checking it locally
        // would incorrectly hide every row whenever a tag is selected.
        // The server-side `tagCodes` param (sent above) is the only tag
        // filter available for this form.

        return matchesSearch && matchesRoom && matchesTag;
      }).toList();
    });
  }

  void _toggleSelectAll(bool? value) {
    if (value == null) return;

    setState(() {
      isSelectAllChecked = value;

      final List<StudentEntity> visibleStudents = _getVisibleStudents();

      if (value) {
        selectedStudents.addAll(visibleStudents);
      } else {
        selectedStudents.removeAll(visibleStudents);
      }
    });
  }

  void _toggleStudentSelection(StudentEntity student, bool? value) {
    if (value == null) return;

    setState(() {
      if (value) {
        selectedStudents.add(student);
      } else {
        selectedStudents.remove(student);
      }

      final visibleStudents = _getVisibleStudents();
      isSelectAllChecked = visibleStudents.every(
        (student) => selectedStudents.contains(student),
      );
    });
  }

  void refreshCallback() {
    setState(() {
      selectedStudents = {};
      _isLoading = true;
    });
    // Simulate refresh
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _filteredStudents = List.from(_allStudents);
        });
      }
    });
  }

  List<StudentEntity> _getVisibleStudents() {
    return _filteredStudents.isEmpty &&
            _searchController.text.isEmpty &&
            _selectedClassrooms.isEmpty &&
            _selectedTag.isEmpty
        ? _allStudents
        : _filteredStudents;
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
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
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

    return StaffFormLayout(
      title: 'Mark Absent',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText.subtitle('Select Students'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Students',
                hintStyle: AppTextStyles.body.copyWith(color: Colors.grey[700]),
                border: InputBorder.none,
                icon: const Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: BlocBuilder<ClassroomCubit, ClassroomState>(
                  bloc: _classroomCubit,
                  builder: (context, classroomState) {
                    final items = _classroomList.isNotEmpty
                        ? _classroomList
                        : classroomState.classrooms
                              .map((c) => c.name)
                              .toList(growable: false);
                    final isLoading =
                        classroomState.isLoading || !_isClassroomDataReady;

                    // Render the field even with no items yet — a shimmer
                    // here could get stuck showing forever if loading never
                    // actually resolves. The dropdown's own "No matches
                    // found" empty state covers the case where there's
                    // genuinely nothing to pick.

                    return CustomMultiSelectDropdown(
                      hintText: 'Classroom',
                      items: items,
                      selectedItems: _selectedClassrooms,
                      onChanged: (selectedItems) {
                        if (isLoading) return;
                        setState(() {
                          _selectedClassrooms = selectedItems;
                          _filterStudents();
                        });
                        _loadStudents();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: CustomMultiSelectDropdown(
                  hintText: 'Tags',
                  items: _tags,
                  selectedItems: _selectedTag,
                  onChanged: (selectedItems) {
                    setState(() {
                      _selectedTag = selectedItems;
                      _filterStudents();
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
                  borderColor: AppColors.themeColor,
                  value: isSelectAllChecked,
                  onChanged: _toggleSelectAll,
                ),
              ),
              const AppText.body('Select All'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? _buildShimmerGrid()
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText.body(
                          _errorMessage ?? 'Failed to load students',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadStudents,
                          child: const AppText.body('Retry'),
                        ),
                      ],
                    ),
                  )
                : _getVisibleStudents().isEmpty
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
                    itemCount: _getVisibleStudents().length,
                    itemBuilder: (context, index) {
                      final student = _getVisibleStudents()[index];
                      final isSelected = selectedStudents.contains(student);

                      return StudentListItem(
                        student: student,
                        isSelected: isSelected,
                        onSelectionChanged: (value) {
                          _toggleStudentSelection(student, value);
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
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? const Color.fromARGB(255, 249, 245, 250)
              : Colors.white,
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
                fileUuid: student.photoUuid,
                name: student.fullName,
                studentCode: student.studentCode,
                size: 32,
                fontSize: 14,
              ),
              const SizedBox(width: 8),
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
