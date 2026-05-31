import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/ellipsis_tooltip_text.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_in_form_list_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'guardian_student_selection_scope.dart';
import 'student_sign_in_form.dart';

class StudentSelectionSignInForm extends StatefulWidget {
  static const String routeName = '/student-selection-sign-in-form';

  const StudentSelectionSignInForm({super.key});

  @override
  State<StudentSelectionSignInForm> createState() =>
      _StudentSelectionSignInFormState();
}

class _StudentSelectionSignInFormState
    extends State<StudentSelectionSignInForm> {
  bool isSelectAllChecked = false;
  String? _selectedClassroom = null;
  String? _selectedClassroomCode;
  List<String> _selectedTag = [];
  Set<StudentEntity> selectedStudents = {};
  final TextEditingController _searchController = TextEditingController();

  // Backing list loaded from the Sign-In form API.
  List<StudentEntity> _allStudents = [];

  // Filter options loaded from APIs (similar to StudentFilterScreen).
  List<String> _classroomList = [];
  Map<String, String> _classroomNameToCode = {};
  List<String> _tagsList = [];
  Map<String, String> _tagNameToCode = {};

  List<StudentEntity> _filteredStudents = [];

  bool _isLoading = false;
  String? _errorMessage;

  bool _isClassroomDataReady = false;
  bool _isTagMapLoading = false;

  /// Parent persona: only linked children; hide classroom/tag filters.
  late final bool _restrictToGuardianChildren;

  late final GetStudentSignInFormListUseCase _getStudentSignInFormListUseCase;
  late final ClassroomCubit _classroomCubit;
  late final StorageService _storageService;
  late final GetTagNameCodeMapForSchoolUseCase
  _getTagNameCodeMapForSchoolUseCase;

  @override
  void initState() {
    super.initState();
    _restrictToGuardianChildren = context.read<RoleCubit>().isParent;
    _getStudentSignInFormListUseCase =
        serviceLocator<GetStudentSignInFormListUseCase>();
    _classroomCubit = serviceLocator<ClassroomCubit>();
    _storageService = serviceLocator<StorageService>();
    _getTagNameCodeMapForSchoolUseCase =
        serviceLocator<GetTagNameCodeMapForSchoolUseCase>();

    if (_restrictToGuardianChildren) {
      _isClassroomDataReady = true;
    } else {
      _loadClassrooms();
      _loadTags();
    }
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadClassrooms() async {
    _classroomCubit.loadActiveClassrooms(
      applyAttendanceStaffScope: true,
    );

    if (!_classroomCubit.state.isLoading &&
        _classroomCubit.state.classrooms.isNotEmpty) {
      setState(() {
        _classroomNameToCode = {
          for (final c in _classroomCubit.state.classrooms) c.name: c.code,
        };
        _classroomList = _classroomNameToCode.keys.toList(growable: false);
        if (_selectedClassroomCode != null &&
            !_classroomNameToCode.containsValue(_selectedClassroomCode)) {
          _selectedClassroom = null;
          _selectedClassroomCode = null;
        }
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
      if (_selectedClassroomCode != null &&
          !_classroomNameToCode.containsValue(_selectedClassroomCode)) {
        _selectedClassroom = null;
        _selectedClassroomCode = null;
      }
      _isClassroomDataReady = _classroomList.isNotEmpty;
    });
  }

  Future<void> _loadTags() async {
    if (_isTagMapLoading) return;
    setState(() {
      _isTagMapLoading = true;
    });

    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isTagMapLoading = false;
        });
        return;
      }

      final map = await _getTagNameCodeMapForSchoolUseCase(
        schoolCode: schoolCode,
      );
      if (!mounted) return;

      final names = map.keys.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      setState(() {
        _tagNameToCode = map;
        _tagsList = names;
        // Drop any selected tags that no longer exist.
        _selectedTag.removeWhere((t) => !_tagsList.contains(t));
        _isTagMapLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTagMapLoading = false;
      });
    }
  }

  Future<void> _loadStudents() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final today = DateTime.now();
      final dateString = _formatDate(today);

      final selectedClassroomCode = _selectedClassroomCode?.trim();
      final classroomCodes =
          (selectedClassroomCode != null && selectedClassroomCode.isNotEmpty)
          ? <String>[selectedClassroomCode]
          : null;

      // Resolve selected tag NAMES -> tagCodes via _tagNameToCode map.
      List<String>? tagCodes;
      if (_selectedTag.isNotEmpty) {
        final codes = _selectedTag
            .map((name) => _tagNameToCode[name])
            .whereType<String>()
            .where((c) => c.trim().isNotEmpty)
            .toList();
        if (codes.isNotEmpty) {
          tagCodes = codes;
        }
      }

      final searchText = _searchController.text.trim().isNotEmpty
          ? _searchController.text.trim()
          : null;

      final page = await _getStudentSignInFormListUseCase(
        fromAttendanceDate: dateString,
        toAttendanceDate: dateString,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        search: searchText,
        page: 0,
        size: 200,
      );

      if (!mounted) return;

      final allowUpper = await loadGuardianStudentAllowlistForSelection(
        context,
      );

      var items = page.items;
      if (allowUpper != null) {
        items = items
            .where(
              (i) => studentCodeAllowedForGuardianAllowlist(
                i.studentCode,
                allowUpper,
              ),
            )
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
          photoUuid: null,
          isExpectedToday: item.isExpectedToday,
        );
      }).toList();

      selectedStudents.removeWhere(
        (s) => !students.any((e) => e.studentCode == s.studentCode),
      );

      setState(() {
        _allStudents = students;
        _filteredStudents = List.from(students);
        _isLoading = false;
        isSelectAllChecked =
            _filteredStudents.isNotEmpty &&
            _filteredStudents.every((s) => selectedStudents.contains(s));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = ApiErrorHandler.extractErrorMessage(e);
      });
    }
  }

  void _toggleSelectAll(bool? value) {
    if (value == null) return;

    setState(() {
      isSelectAllChecked = value;
      if (value) {
        selectedStudents.addAll(_filteredStudents);
      } else {
        selectedStudents.removeAll(_filteredStudents);
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

      isSelectAllChecked = _filteredStudents.every(
        (student) => selectedStudents.contains(student),
      );
    });
  }

  void refreshCallback() {
    // Reset selections when returning from sign-in form
    setState(() {
      isSelectAllChecked = false;
      selectedStudents.clear();
      _selectedClassroom = null;
      _selectedClassroomCode = null;
      _selectedTag.clear();
      _filteredStudents = List.from(_allStudents);
    });
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
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentSignInForm(
          students: selectedStudents.toList(),
          refreshCallback: refreshCallback,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveSizing.isTablet(context);
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    return StaffFormLayout(
      title: 'Sign-In',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.subtitle(
            _restrictToGuardianChildren
                ? 'Select your children'
                : 'Select Students',
          ),
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
                hintText: _restrictToGuardianChildren
                    ? 'Search your children'
                    : 'Search Students',
                hintStyle: AppTextStyles.body.copyWith(color: Colors.grey[700]),
                border: InputBorder.none,
                icon: const Icon(Icons.search, color: Colors.grey),
              ),
              onChanged: (_) => _loadStudents(),
            ),
          ),
          const SizedBox(height: 12),
          if (!_restrictToGuardianChildren) ...[
            Row(
              children: [
                Expanded(
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

                      if (isLoading && items.isEmpty) {
                        return const ShimmerLoader(height: 40);
                      }

                      return CustomDropdown(
                        hintText: 'Classroom',
                        items: items,
                        selectedItem: _selectedClassroom,
                        onSelect: (value) {
                          if (isLoading) return;
                          setState(() {
                            _selectedClassroom = value;
                            _selectedClassroomCode = value == null
                                ? null
                                : _classroomNameToCode[value];
                          });
                          _loadStudents();
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomMultiSelectDropdown(
                    hintText: 'Tags',
                    items: _tagsList,
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
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: CustomCheckbox(
                  value: isSelectAllChecked,
                  onChanged: _toggleSelectAll,
                  borderColor: AppColors.themeColor,
                ),
              ),
              const AppText.body('Select All'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: PrimaryCircularLoader())
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
                : _filteredStudents.isEmpty
                ? Center(
                    child: AppText.body(
                      _restrictToGuardianChildren
                          ? 'No linked children appear in today\'s sign-in list. If this looks wrong, check the child selector at the top of the app.'
                          : 'No students found',
                      textAlign: TextAlign.center,
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: false,
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: isTablet ? 16 : 12,
                      mainAxisSpacing: isTablet ? 16 : 12,
                      mainAxisExtent: 72,
                    ),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      final isSelected = selectedStudents.contains(student);

                      return StudentListItem(
                        student: student,
                        isSelected: isSelected,
                        onSelectionChanged: (value) =>
                            _toggleStudentSelection(student, value),
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
    super.key,
    required this.student,
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
                fileUuid: student.photoUuid ?? '',
                name: student.fullName,
                studentCode: student.studentCode,
                showOnlyAbsentAttendanceDot: true,
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
