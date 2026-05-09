import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
// UI-only: use wowcare widgets and theme; backend/bloc imports removed
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_page_usecase.dart';
import 'package:wowcare/domain/features/student_classroom/usecases/assign_students_to_classroom_usecase.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';

// UI-only lightweight types
class _TagEntity {
  final String name;
  const _TagEntity(this.name);
}

class StudentEntity {
  final int id;
  final String code;
  final String fullName;
  final String photoUuid;
  final String? roomName;
  final List<_TagEntity> tags;
  const StudentEntity({
    required this.id,
    required this.code,
    required this.fullName,
    this.photoUuid = '',
    this.roomName,
    this.tags = const [],
  });
}

class AssignStudentToClassroomForm extends StatefulWidget {
  final VoidCallback onStudentsAssigned; // Add this line
  final String selectedRoomName;
  final String classroomCode;

  const AssignStudentToClassroomForm({
    required this.onStudentsAssigned,
    required this.selectedRoomName,
    required this.classroomCode,
    super.key,
  });

  @override
  State<AssignStudentToClassroomForm> createState() =>
      _AssignStudentToClassroomFormState();
}

class _AssignStudentToClassroomFormState
    extends State<AssignStudentToClassroomForm> {
  static const int _pageSize = 100;

  bool isSelectAllChecked = false;
  String? _selectedClassroom = '';
  List<String> _selectedTag = [];
  List<StudentEntity> _filteredStudents = [];
  final List<StudentEntity> _allStudents = [];
  final List<String> _allRooms = [];
  final List<String> _allTags = [];
  bool _isLoadingStudents = false;
  String? _studentsError;
  Set<StudentEntity> selectedStudents = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudentsFromApi();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentsFromApi() async {
    setState(() {
      _isLoadingStudents = true;
      _studentsError = null;
    });

    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode = await storage.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.trim().isEmpty) {
        throw 'School code is not set. Please sign in and select a school.';
      }

      final getStudentPageUseCase = serviceLocator<GetStudentPageUseCase>();
      final fetchedStudents = <StudentEntity>[];
      final uniqueRooms = <String>{};
      final uniqueTags = <String>{};

      int page = 0;
      bool hasMore = true;
      while (hasMore) {
        final studentPage = await getStudentPageUseCase(
          schoolCode: schoolCode,
          page: page,
          size: _pageSize,
          status: 'ACTIVE',
        );

        for (final s in studentPage.items) {
          final tagEntities = s.tags
              .where((t) => t.trim().isNotEmpty)
              .map((t) => _TagEntity(t.trim()))
              .toList();
          fetchedStudents.add(
            StudentEntity(
              id: fetchedStudents.length + 1,
              code: s.code,
              fullName: s.fullName,
              photoUuid: '',
              roomName: s.classroom,
              tags: tagEntities,
            ),
          );
          if (s.classroom.trim().isNotEmpty) {
            uniqueRooms.add(s.classroom.trim());
          }
          for (final t in s.tags) {
            final normalized = t.trim();
            if (normalized.isNotEmpty) uniqueTags.add(normalized);
          }
        }

        hasMore = studentPage.hasMore;
        page += 1;
      }

      if (!mounted) return;
      setState(() {
        _allStudents
          ..clear()
          ..addAll(fetchedStudents);
        _allRooms
          ..clear()
          ..addAll(uniqueRooms.toList()..sort());
        _allTags
          ..clear()
          ..addAll(uniqueTags.toList()..sort());
        _filterStudents();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _studentsError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStudents = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    _filterStudents();
  }

  void _filterStudents() {
    final allStudents = _allStudents;
    _filteredStudents = allStudents.where((student) {
      // Exclude students already in the selected classroom from ClassroomScreen
      if ((student.roomName ?? '').trim() == widget.selectedRoomName.trim()) {
        return false;
      }
      bool matchesSearch = true;
      bool matchesRoom = true;
      bool matchesTag = true;

      if (_searchController.text.isNotEmpty) {
        matchesSearch = student.fullName.toLowerCase().contains(
          _searchController.text.toLowerCase(),
        );
      }

      if (_selectedClassroom != null && _selectedClassroom != '') {
        matchesRoom = (student.roomName ?? '').contains(_selectedClassroom!);
      }

      if (_selectedTag.isNotEmpty) {
        matchesTag = student.tags.any((tag) => _selectedTag.contains(tag.name));
      }

      return matchesSearch && matchesRoom && matchesTag;
    }).toList();
    setState(() {});
  }

  void _toggleSelectAll(bool? value) {
    if (value == null) return;

    setState(() {
      isSelectAllChecked = value;

      // Get the current visible students based on filters
      final List<StudentEntity> visibleStudents = _getVisibleStudents();

      if (value) {
        // Add all visible students to selection
        selectedStudents.addAll(visibleStudents);
      } else {
        // Remove all visible students from selection
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

      // Update select all checkbox based on visible students
      final visibleStudents = _getVisibleStudents();
      isSelectAllChecked = visibleStudents.every(
        (student) => selectedStudents.contains(student),
      );
    });
  }

  List<StudentEntity> _getVisibleStudents() {
    return _filteredStudents.isEmpty &&
            _searchController.text.isEmpty &&
            (_selectedClassroom?.isEmpty ?? true) &&
            _selectedTag.isEmpty
        ? _allStudents
        : _filteredStudents;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assign to ${widget.selectedRoomName}',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Students',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SearchBar(
            controller: _searchController,
            constraints: const BoxConstraints(minHeight: 44),
            hintText: 'Search Students',
            hintStyle: WidgetStatePropertyAll(
              TextStyle(
                fontFamily: 'Manrope',
                color: Colors.grey[700],
              ),
            ),
            backgroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
            surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.white),
            elevation: const WidgetStatePropertyAll<double>(0),
            side: const WidgetStatePropertyAll(
              BorderSide(
                width: 1,
                color: Color.fromARGB(255, 188, 173, 186),
              ),
            ),
            leading: const Icon(Icons.search, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: CustomDropdown(
                  onSelect: (value) {
                    setState(() {
                      _selectedClassroom = value;
                      _filterStudents();
                    });
                  },
                  hintText: 'Classroom',
                  items: _allRooms
                      .where((name) => name != widget.selectedRoomName)
                      .toList(),
                  isField: true,
                  isEnabled: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: CustomMultiSelectDropdown(
                  hintText: 'Tags',
                  showSelectAll: true,
                  items: _allTags,
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
                  onChanged: _toggleSelectAll, // Add the handler here
                ),
              ),
              const Text('Select All', style: TextStyle(fontFamily: 'Manrope')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoadingStudents
                ? const Center(child: PrimaryCircularLoader())
                : _studentsError != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _studentsError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _loadStudentsFromApi,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 52,
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
          const SizedBox(height: 16),
          CustomButtonLayout(
            confirmButtonLabel: 'Next',
            cancelButtonLabel: 'Cancel',
            onPressedCancel: () => Navigator.pop(context),
            onPressedConfirm: () {
              if (selectedStudents.isEmpty) {
                CoreUtils.showTopSnackBar(
                  context: context,
                  message: 'Please select at least one student',
                  isWarning: true,
                );
                return;
              } else {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => DraggableScrollableSheet(
                    maxChildSize: 0.95,
                    builder: (_, controller) => StudentConfirmationForm(
                      selectedStudents: selectedStudents,
                      selectedRoomName: widget.selectedRoomName,
                      classroomCode: widget.classroomCode,
                      onStudentsAssigned: widget.onStudentsAssigned,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class StudentConfirmationForm extends StatefulWidget {
  final Set<StudentEntity> selectedStudents;
  final String selectedRoomName;
  final String classroomCode;
  final VoidCallback onStudentsAssigned;

  const StudentConfirmationForm({
    Key? key,
    required this.selectedStudents,
    required this.selectedRoomName,
    required this.classroomCode,
    required this.onStudentsAssigned,
  }) : super(key: key);

  @override
  State<StudentConfirmationForm> createState() =>
      _StudentConfirmationFormState();
}

class _StudentConfirmationFormState extends State<StudentConfirmationForm> {
  late Set<StudentEntity> currentSelectedStudents;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    currentSelectedStudents = Set.from(widget.selectedStudents);
  }

  void removeStudent(StudentEntity student) {
    setState(() {
      currentSelectedStudents.remove(student);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Assign to ${widget.selectedRoomName}',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (currentSelectedStudents.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No students selected',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: const Color(0xff573353),
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 52,
                ),
                itemCount: currentSelectedStudents.length,
                itemBuilder: (context, index) {
                  final student = currentSelectedStudents.elementAt(index);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.themeColor),
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromRGBO(249, 245, 250, 1),
                    ),
                    child: Row(
                      children: [
                        DocumentImageWidget(
                          fileUuid: student.photoUuid,
                          name: student.fullName,
                          size: 32,
                          placeholderAsset: MediaRes.userImageMale,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            student.fullName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              color: AppColors.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => removeStudent(student),
                          child: SvgPicture.asset(MediaRes.delete_icon),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          CustomButtonLayout(
            confirmButtonLabel: 'Submit',
            cancelButtonLabel: 'Cancel',
            onPressedCancel: () => Navigator.pop(context),
            onPressedConfirm: _isSubmitting
                ? () {}
                : () async {
                    if (currentSelectedStudents.isEmpty) {
                      CoreUtils.showTopSnackBar(
                        context: context,
                        message: 'Please select at least one student',
                        isWarning: true,
                      );
                      return;
                    }

                    setState(() => _isSubmitting = true);
                    try {
                      final storage = serviceLocator<StorageService>();
                      final schoolCode = await storage.getString(
                        StorageKeys.schoolCode,
                      );
                      if (schoolCode == null || schoolCode.trim().isEmpty) {
                        throw 'Missing schoolCode. Please sign in / select a school again.';
                      }

                      // NOTE: In this UI module we only have the selected room name.
                      // The backend expects classroomCode; we pass the selectedRoomName
                      // as the code until the classroom code is wired into this form.
                      final classroomCode = widget.classroomCode.trim();
                      final studentCodes = currentSelectedStudents
                          .map((s) => s.code.trim())
                          .where((code) => code.isNotEmpty)
                          .toList();

                      final message =
                          await serviceLocator<
                            AssignStudentsToClassroomUseCase
                          >()(
                            schoolCode: schoolCode,
                            classroomCode: classroomCode,
                            studentCodes: studentCodes,
                          );

                      if (!mounted) return;
                      CoreUtils.showTopSnackBar(
                        context: context,
                        message:
                            message.isEmpty ? 'Assigned successfully' : message,
                        isSuccess: true,
                      );

                      widget.onStudentsAssigned();
                      Navigator.pop(context);
                    } catch (e) {
                      if (!mounted) return;
                      CoreUtils.showTopSnackBar(
                        context: context,
                        message: e.toString(),
                        isError: true,
                      );
                    } finally {
                      if (mounted) setState(() => _isSubmitting = false);
                    }
                  },
          ),
        ],
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
                size: 32,
                placeholderAsset: MediaRes.userImageMale,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  student.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
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

// NOTE: Tags multi-select uses the shared `CustomMultiSelectDropdown`
// (`lib/shared/common/widgets/custom_multi_select_dropdown.dart`).
