import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/gradient_circular_progress.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

// NOTE: UI-only screen. All API/backend-related code has been removed or commented out.
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:wowcare/core/util/api_paths.dart';
// import 'package:wowcare/core/util/constants.dart';
// import 'package:wowcare/core/common/app/providers/auth_providers.dart';
// import 'package:wowcare/core/util/core_utils.dart';
// import 'selected_students_receipt_screen.dart';

class Tag {
  final int id;
  final String name;
  Tag({required this.id, required this.name});
}

class Student {
  final int id;
  final String fullName;
  final String? photoUuid;
  final String? roomName;
  final int? roomId;
  final List<Tag> tags;
  Student({
    required this.id,
    required this.fullName,
    this.photoUuid,
    this.roomName,
    this.roomId,
    required this.tags,
  });
}

class SelectStudentsScreen extends StatefulWidget {
  const SelectStudentsScreen({Key? key, this.invoiceData}) : super(key: key);
  final Map<String, dynamic>? invoiceData;

  @override
  State<SelectStudentsScreen> createState() => _SelectStudentsScreenState();
}

class _SelectStudentsScreenState extends State<SelectStudentsScreen> {
  List<Student> students = [];
  List<String> classrooms = ['Select Classroom'];
  List<String> tags = ['Select Tags'];
  String selectedClassroom = 'Select Classroom';
  String selectedTag = 'Select Tags';
  String searchQuery = '';
  bool selectAll = false;
  List<bool> selected = [];
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDummyData();
  }

  void _loadDummyData() {
    // Dummy tags
    final reading = Tag(id: 1, name: 'Reading');
    final sports = Tag(id: 2, name: 'Sports');
    final arts = Tag(id: 3, name: 'Arts');

    // Dummy students
    students = [
      Student(id: 1, fullName: 'Alex Johnson', roomName: 'Room 101', roomId: 101, tags: [reading, sports]),
      Student(id: 2, fullName: 'Maria Gomez', roomName: 'Room 102', roomId: 102, tags: [arts]),
      Student(id: 3, fullName: 'Liam Chen', roomName: 'Room 101', roomId: 101, tags: [sports]),
      Student(id: 4, fullName: 'Sophia Patel', roomName: 'Room 103', roomId: 103, tags: [reading, arts]),
      Student(id: 5, fullName: 'Noah Smith', roomName: 'Room 102', roomId: 102, tags: [reading]),
      Student(id: 6, fullName: 'Emma Brown', roomName: 'Room 104', roomId: 104, tags: [sports, arts]),
    ];

    // Classrooms list from dummy data
    final classroomSet = <String>{};
    for (final s in students) {
      if (s.roomName != null) classroomSet.add(s.roomName!);
    }
    classrooms = ['Select Classroom', ...classroomSet.toList()..sort()];

    // Tags list from dummy data
    final tagSet = <String>{};
    for (final s in students) {
      for (final t in s.tags) {
        tagSet.add(t.name);
      }
    }
    tags = ['Select Tags', ...tagSet.toList()..sort()];

    selected = List.generate(students.length, (_) => false);
    isLoading = false;
    setState(() {});
  }

  List<Student> get filteredStudents {
    return students.where((student) {
      final matchesSearch = student.fullName.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesClassroom = selectedClassroom == 'Select Classroom' || student.roomName == selectedClassroom;
      final matchesTag = selectedTag == 'Select Tags' || student.tags.any((tag) => tag.name == selectedTag);
      return matchesSearch && matchesClassroom && matchesTag;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
    final containerWidth = isLargeTablet
        ? (screenWidth * 0.8).clamp(800.0, 1200.0)
        : isTablet
            ? screenWidth * 0.9
            : screenWidth - 32.0;
    final horizontalSpacing = isLargeTablet
        ? (screenWidth * 0.1).clamp(32.0, 64.0)
        : isTablet
            ? 32.0
            : 16.0;
    final verticalSpacing = isLargeTablet
        ? 32.0
        : isTablet
            ? 24.0
            : 16.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GlobalScaffold(
        hasBackButton: true,
        showCustomNavigationBar: false,
        body: Center(
          child: Container(
            width: containerWidth,
            margin: EdgeInsets.symmetric(horizontal: horizontalSpacing, vertical: verticalSpacing),
            padding: EdgeInsets.all(isTablet ? 32.0 : 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(
                Radius.circular(isTablet ? 40.0 : 24.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.cardBorderColor),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.cardColor,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomSearchBar(
                              controller: _searchController,
                              hintText: 'Search Students',
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          CustomClearAllChip(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                searchQuery = '';
                                selectedClassroom = classrooms[0];
                                selectedTag = tags[0];
                                selectAll = false;
                                selected = List.generate(students.length, (_) => false);
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomDropdown(
                        hintText: selectedClassroom,
                        items: classrooms,
                        selectedItem: selectedClassroom,
                        onSelect: (val) {
                          if (val != null) {
                            setState(() {
                              selectedClassroom = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomDropdown(
                        hintText: selectedTag,
                        items: tags,
                        selectedItem: selectedTag,
                        onSelect: (val) {
                          if (val != null) {
                            setState(() {
                              selectedTag = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: selectAll,
                      onChanged: (val) {
                        setState(() {
                          selectAll = val ?? false;
                          final current = filteredStudents;
                          selected = List.generate(current.length, (_) => selectAll);
                        });
                      },
                      activeColor: AppColors.themeColor,
                      checkColor: Colors.white,
                      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                        if (states.contains(MaterialState.selected)) {
                          return AppColors.themeColor;
                        }
                        return Colors.transparent;
                      }),
                    ),
                    const Text(
                      'Select All',
                      style: TextStyle(
                        fontFamily: "Manrope",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff573353),
                        height: 19 / 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: isLoading
                      ? const Center(child: GradientCircularProgress())
                      : ListView.builder(
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];
                            final isChecked = selected.length > index ? selected[index] : false;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  final next = !isChecked;
                                  if (selected.length <= index) {
                                    selected = List<bool>.from(selected)..add(next);
                                  } else {
                                    selected[index] = next;
                                  }
                                  selectAll = selected.isNotEmpty && selected.every((e) => e);
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF6657F8), width: 1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    DocumentImageWidget(
                                      fileUuid: (student.photoUuid ?? student.fullName),
                                      name: student.fullName,
                                      size: 40,
                                      shape: BoxShape.circle,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student.fullName,
                                            style: const TextStyle(
                                              fontFamily: 'Manrope',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xff573353),
                                              height: 19 / 14,
                                            ),
                                          ),
                                          if (student.roomName != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              student.roomName!,
                                              style: const TextStyle(
                                                fontFamily: 'Manrope',
                                                fontSize: 12,
                                                color: Color(0x99573353),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Checkbox(
                                      value: isChecked,
                                      onChanged: (val) {
                                        setState(() {
                                          final v = val ?? false;
                                          if (selected.length <= index) {
                                            selected = List<bool>.from(selected)..add(v);
                                          } else {
                                            selected[index] = v;
                                          }
                                          selectAll = selected.isNotEmpty && selected.every((e) => e);
                                        });
                                      },
                                      activeColor: AppColors.themeColor,
                                      checkColor: Colors.white,
                                      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                                        if (states.contains(MaterialState.selected)) {
                                          return AppColors.themeColor;
                                        }
                                        return Colors.transparent;
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 16.0,
              left: 16,
              right: 16,
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
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24.0),
                topRight: Radius.circular(24.0),
              ),
            ),
            child: Container(
              height: 48.0,
              decoration: BoxDecoration(
                gradient: AppColors.buildPrimaryGradient(),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TextButton(
                onPressed: () {
                  // UI-only: handle "Next" with a placeholder
                  final selectedStudents = <Student>[];
                  final current = filteredStudents;
                  for (int i = 0; i < current.length; i++) {
                    if (selected.length > i && selected[i]) {
                      selectedStudents.add(current[i]);
                    }
                  }
                  if (selectedStudents.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one student')),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Selected ${selectedStudents.length} student(s) — UI only')),
                  );
                  // Intended next navigation (UI-only, commented):
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => SelectedStudentsReceiptScreen(...)));
                },
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}