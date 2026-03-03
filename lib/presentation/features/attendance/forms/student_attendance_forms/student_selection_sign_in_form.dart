import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_in_form_list_usecase.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'student_sign_in_form.dart';

class StudentSelectionSignInForm extends StatefulWidget {
  static const String routeName = '/student-selection-sign-in-form';

  const StudentSelectionSignInForm({
    super.key,
  });

  @override
  State<StudentSelectionSignInForm> createState() =>
      _StudentSelectionSignInFormState();
}

class _StudentSelectionSignInFormState
    extends State<StudentSelectionSignInForm> {
  bool isSelectAllChecked = false;
  String? _selectedClassroom = '';
  List<String> _selectedTag = [];
  Set<StudentEntity> selectedStudents = {};
  final TextEditingController _searchController = TextEditingController();

  // Backing list loaded from the Sign-In form API.
  List<StudentEntity> _allStudents = [];

  final List<String> _classrooms = ['Classroom A', 'Classroom B', 'Classroom C', 'Classroom D'];
  final List<String> _tags = ['Tag 1', 'Tag 2', 'Tag 3', 'Tag 4'];

  List<StudentEntity> _filteredStudents = [];

  bool _isLoading = false;
  String? _errorMessage;

  late final GetStudentSignInFormListUseCase
      _getStudentSignInFormListUseCase;

  @override
  void initState() {
    super.initState();
    _getStudentSignInFormListUseCase =
        serviceLocator<GetStudentSignInFormListUseCase>();
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

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final today = DateTime.now();
      final dateString = _formatDate(today);

      final classroomCodes =
          _selectedClassroom != null && _selectedClassroom!.isNotEmpty
              ? <String>[_selectedClassroom!]
              : null;

      final tagCodes = _selectedTag.isNotEmpty ? _selectedTag : null;

      final searchText =
          _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null;

      final page = await _getStudentSignInFormListUseCase(
        fromAttendanceDate: dateString,
        toAttendanceDate: dateString,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        search: searchText,
        page: 0,
        size: 100,
      );

      final students = page.items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return StudentEntity(
          id: index + 1,
          fullName: item.studentName,
          roomId: 0,
          roomName: item.classroomName,
          photoUuid: null,
        );
      }).toList();

      setState(() {
        _allStudents = students;
        _filteredStudents = List.from(students);
        _isLoading = false;
        isSelectAllChecked = _filteredStudents.isNotEmpty &&
            _filteredStudents.every((s) => selectedStudents.contains(s));
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
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
      _selectedClassroom = '';
      _selectedTag.clear();
      _filteredStudents = List.from(_allStudents);
    });
  }

  void _handleNext() {
    if (selectedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
          const AppText.subtitle('Select Students'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FA),
              borderRadius: BorderRadius.circular(15),
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
              onChanged: (_) => _loadStudents(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomDropdown(
                  hintText: 'Classroom',
                  items: _classrooms,
                  selectedItem: _selectedClassroom,
                  onSelect: (value) {
                    setState(() {
                      _selectedClassroom = value;
                    });
                    _loadStudents();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomMultiSelectDropdown(
                  hintText: 'Tags',
                  items: _tags,
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
                ? const Center(child: CircularProgressIndicator())
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
                        ? const Center(child: AppText.body("No students found"))
                        : GridView.builder(
                    shrinkWrap: false,
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: isTablet ? 16 : 12,
                      mainAxisSpacing: isTablet ? 16 : 12,
                      mainAxisExtent: 52,
                    ),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      final isSelected =
                          selectedStudents.contains(student);

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
        padding: EdgeInsets.only(
          bottom: safeAreaBottom,
        ),
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
          border: Border.all(
            color: AppColors.themeColor,
          ),
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
                size: 32,
                fontSize: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  student.fullName.split(' ').first,
                  overflow: TextOverflow.ellipsis,
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
