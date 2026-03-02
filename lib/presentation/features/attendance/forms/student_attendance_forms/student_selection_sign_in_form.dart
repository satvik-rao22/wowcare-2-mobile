import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';

import 'student_entity.dart';
import 'student_selection_chip.dart';
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

class _StudentSelectionSignInFormState extends State<StudentSelectionSignInForm> {
  bool isSelectAllChecked = false;
  String? _selectedClassroom = '';
  List<String> _selectedTag = [];
  Set<StudentEntity> selectedStudents = {};
  final TextEditingController _searchController = TextEditingController();

  // Mock data for UI-only implementation
  final List<StudentEntity> _allStudents = List.generate(
    20,
    (index) => StudentEntity(
      id: index + 1,
      fullName: 'Student ${index + 1}',
      roomId: (index % 4) + 1,
      roomName: 'Classroom ${String.fromCharCode(65 + (index % 4))}',
      photoUuid: '', // Empty string for mock data - will show initials avatar
    ),
  );

  final List<String> _classrooms = const [
    'Classroom A',
    'Classroom B',
    'Classroom C',
    'Classroom D',
  ];
  final List<String> _tags = const ['Tag 1', 'Tag 2', 'Tag 3', 'Tag 4'];

  List<StudentEntity> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    _filteredStudents = List.from(_allStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        bool matchesSearch = true;
        bool matchesRoom = true;
        bool matchesTag = true;

        if (_searchController.text.isNotEmpty) {
          matchesSearch = student.fullName
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
        }

        if (_selectedClassroom != null && _selectedClassroom!.isNotEmpty) {
          matchesRoom = _selectedClassroom == student.roomName;
        }

        // Tag matching would be implemented with actual tag data
        return matchesSearch && matchesRoom && matchesTag;
      }).toList();
    });
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
      _searchController.clear();
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
    final screenSize = mediaQuery.size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Container(
          height: screenSize.height * 0.8,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(5),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sign In', style: AppTextStyles.title),
              const SizedBox(height: 20),
              const Text('Select Students', style: AppTextStyles.subtitle),
              const SizedBox(height: 12),
              CustomSearchBar(
                controller: _searchController,
                hintText: 'Search Students',
                onChanged: (_) => _filterStudents(),
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
                          _selectedClassroom = value ?? '';
                          _filterStudents();
                        });
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
                          _filterStudents();
                        });
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
                  const Text('Select All', style: AppTextStyles.body),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _filteredStudents.isEmpty
                    ? const Center(child: Text("No students found"))
                    : GridView.builder(
                        shrinkWrap: false,
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: isTablet ? 16 : 12,
                          mainAxisSpacing: isTablet ? 16 : 12,
                          mainAxisExtent: 52,
                        ),
                        itemCount: _filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = _filteredStudents[index];
                          final isSelected = selectedStudents.contains(student);

                          return StudentSelectionChip(
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
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          bottom: safeAreaBottom,
          left: isTablet ? 24 : 16,
          right: isTablet ? 24 : 16,
          top: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 16,
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isTablet ? 40.0 : 24.0),
            topRight: Radius.circular(isTablet ? 40.0 : 24.0),
          ),
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

