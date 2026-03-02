import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/simmer_loader.dart';
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
  bool isSelectAllChecked = false;
  String? _selectedClassroom = '';
  List<String> _selectedTag = [];
  List<StudentEntity> _filteredStudents = [];
  Set<StudentEntity> selectedStudents = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  // Mock data for UI-only implementation
  final List<StudentEntity> _allStudents = List.generate(
    15,
    (index) => StudentEntity(
      id: index + 1,
      fullName: 'Student ${index + 1}',
      roomId: (index % 4) + 1,
      roomName: 'Classroom ${String.fromCharCode(65 + (index % 4))}',
      photoUuid: '',
      tags: [
        TagEntity(name: 'Tag ${(index % 3) + 1}'),
      ],
    ),
  );

  final List<String> _classrooms = [
    'Classroom A',
    'Classroom B',
    'Classroom C',
    'Classroom D'
  ];
  final List<String> _tags = ['Tag 1', 'Tag 2', 'Tag 3', 'Tag 4'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _filteredStudents = List.from(_allStudents);
        });
      }
    });
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

        if (_selectedTag.isNotEmpty) {
          matchesTag =
              student.tags.any((tag) => _selectedTag.contains(tag.name));
        }

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

  List<StudentEntity> _getVisibleStudents() {
    return _allStudents.where((student) {
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

      if (_selectedTag.isNotEmpty) {
        matchesTag = student.tags.any((tag) => _selectedTag.contains(tag.name));
      }

      return matchesSearch && matchesRoom && matchesTag;
    }).toList();
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
      itemBuilder: (context, index) => const ShimmerLoaderCard(
        child: SizedBox(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        height: screenSize.height * 0.8,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transfer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Students',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: const Color(0xFFF8F7FA),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey)),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Students',
                  hintStyle: TextStyle(color: Colors.grey[700]),
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
                  child: CustomDropdown(
                    selectedItem: _selectedClassroom,
                    onSelect: (value) {
                      setState(() {
                        _selectedClassroom = value;
                        _filterStudents();
                      });
                    },
                    hintText: 'Classroom',
                    items: _classrooms,
                    isField: true,
                    isEnabled: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: CustomMultiSelectDropdownAssignStudent(
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
                    borderColor: AppColors.themeColor,
                    value: isSelectAllChecked,
                    onChanged: _toggleSelectAll,
                  ),
                ),
                const Text('Select All'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? _buildShimmerGrid()
                  : _filteredStudents.isEmpty
                      ? const Center(child: Text("No students found"))
                      : GridView.builder(
                          shrinkWrap: false,
                          physics: const AlwaysScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 52,
                          ),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
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
      ),
      bottomNavigationBar: CustomButtonLayout(
        confirmButtonLabel: 'Next',
        onPressedConfirm: () {
          if (selectedStudents.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
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
                ),
              ),
            );
          }
        },
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
                fileUuid: student.photoUuid,
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

class CustomMultiSelectDropdownAssignStudent extends StatefulWidget {
  final String hintText;
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;
  final bool isField;
  final double? width;

  const CustomMultiSelectDropdownAssignStudent({
    Key? key,
    required this.hintText,
    required this.items,
    required this.selectedItems,
    required this.onChanged,
    this.isField = false,
    this.width,
  }) : super(key: key);

  @override
  State<CustomMultiSelectDropdownAssignStudent> createState() =>
      _CustomMultiSelectDropdownAssignStudentState();
}

class _CustomMultiSelectDropdownAssignStudentState
    extends State<CustomMultiSelectDropdownAssignStudent> {
  late List<String> _localSelectedItems;
  bool isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _localSelectedItems = List.from(widget.selectedItems);
    _localSelectedItems.removeWhere((item) => !widget.items.contains(item));
  }

  @override
  void didUpdateWidget(CustomMultiSelectDropdownAssignStudent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.items, widget.items) ||
        !listEquals(oldWidget.selectedItems, widget.selectedItems)) {
      setState(() {
        _localSelectedItems = List.from(widget.selectedItems);
        _localSelectedItems.removeWhere((item) => !widget.items.contains(item));
      });
    }
  }

  String get displaySuffix {
    if (widget.hintText.toLowerCase() == 'status') {
      return 'status';
    } else if (widget.hintText.toLowerCase() == 'tags') {
      return 'tag${_localSelectedItems.length > 1 ? 's' : ''}';
    }
    return 'items';
  }

  @override
  Widget build(BuildContext context) {
    String displayText = _localSelectedItems.isEmpty
        ? widget.hintText
        : '${_localSelectedItems.length} $displaySuffix';

    return Container(
      height: 40,
      width: widget.width,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF8F7FA),
          hintText: widget.hintText,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
        ),
        icon: const Icon(Icons.keyboard_arrow_down),
        iconSize: 24,
        elevation: 2,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
        dropdownColor: Colors.white,
        items: widget.items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            enabled: false,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setMenuItemState) {
                final isSelected = _localSelectedItems.contains(item);
                return InkWell(
                  onTap: () {
                    setMenuItemState(() {
                      if (isSelected) {
                        _localSelectedItems.remove(item);
                      } else {
                        _localSelectedItems.add(item);
                      }
                    });
                    setState(() {});
                    widget.onChanged(_localSelectedItems);
                  },
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (bool? checked) {
                            setMenuItemState(() {
                              if (checked == true) {
                                _localSelectedItems.add(item);
                              } else {
                                _localSelectedItems.remove(item);
                              }
                            });
                            setState(() {});
                            widget.onChanged(_localSelectedItems);
                          },
                          activeColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }).toList(),
        onChanged: (_) {},
        isExpanded: true,
        hint: Text(
          displayText,
          style: TextStyle(
            color:
                _localSelectedItems.isEmpty ? Colors.grey[600] : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
