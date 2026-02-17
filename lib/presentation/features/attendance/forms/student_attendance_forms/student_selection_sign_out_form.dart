import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'student_sign_out_form.dart';

class StudentSelectionSignOutForm extends StatefulWidget {
  static const String routeName = '/student-selection-sign-out-form';

  const StudentSelectionSignOutForm({super.key});

  @override
  State<StudentSelectionSignOutForm> createState() =>
      _StudentSelectionSignOutFormState();
}

class _StudentSelectionSignOutFormState
    extends State<StudentSelectionSignOutForm> {
  bool isSelectAllChecked = false;
  String? _selectedClassroom = '';
  List<String> _selectedTag = [];
  Set<StudentEntity> selectedStudents = {};
  final TextEditingController _searchController = TextEditingController();

  // Mock data for UI-only implementation
  final List<StudentEntity> _allStudents = List.generate(
    15,
    (index) => StudentEntity(
      id: index + 1,
      fullName: 'Student ${index + 1}',
      roomId: (index % 4) + 1,
      roomName: 'Classroom ${String.fromCharCode(65 + (index % 4))}',
    ),
  );

  final List<String> _classrooms = ['Classroom A', 'Classroom B', 'Classroom C', 'Classroom D'];
  final List<String> _tags = ['Tag 1', 'Tag 2', 'Tag 3', 'Tag 4'];

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
        builder: (context) => StudentSignOutForm(
          students: selectedStudents.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveSizing.isTablet(context);
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 16,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.title('Sign Out'),
                const SizedBox(height: 20),
                AppText.sectionHeader('Select Students'),
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
                            _selectedClassroom = value;
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
                    CustomCheckbox(
                      value: isSelectAllChecked,
                      onChanged: _toggleSelectAll,
                      borderColor: AppColors.themeColor,
                    ),
                    const SizedBox(width: 8),
                    AppText.body('Select All'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredStudents.isEmpty
                ? const Center(child: Text("No students found"))
                : GridView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24 : 16,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: isTablet ? 16 : 12,
                      mainAxisSpacing: isTablet ? 16 : 12,
                      mainAxisExtent: isTablet ? 60 : 52,
                    ),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      final isSelected = selectedStudents.contains(student);

                      return _buildStudentItem(student, isSelected);
                    },
                  ),
          ),
        ],
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

  Widget _buildStudentItem(StudentEntity student, bool isSelected) {
    return InkWell(
      onTap: () => _toggleStudentSelection(student, !isSelected),
      child: CustomSectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        backgroundColor: isSelected
            ? AppColors.fieldBackgroundColor
            : AppColors.cardColor,
        child: Row(
          children: [
            CustomCheckbox(
              value: isSelected,
              onChanged: (value) => _toggleStudentSelection(student, value),
              borderColor: AppColors.themeColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppText.value(
                student.fullName.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
