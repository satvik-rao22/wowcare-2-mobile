import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
// UI-only: use wowcare widgets and theme; backend/bloc imports removed
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/simmer_loader.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
// import 'package:flutter_bloc/flutter_bloc.dart'; // UI-only
// import 'package:wowcare/core/extentions/context_extentions.dart'; // UI-only
// import 'package:wowcare/core/services/injection_container.dart'; // UI-only
// import 'package:wowcare/core/util/core_utils.dart'; // UI-only
// import 'package:wowcare/core/util/typedefs.dart'; // UI-only
// import 'package:wowcare/features/...'; // UI-only
import 'package:shimmer/shimmer.dart';

// UI-only lightweight types
typedef DataMap = Map<String, dynamic>;

class RoomDTO {
  final int id;
  final String name;
  const RoomDTO({required this.id, required this.name});
}

class _TagEntity {
  final String name;
  const _TagEntity(this.name);
}

class StudentEntity {
  final int id;
  final String fullName;
  final String photoUuid;
  final String? roomName;
  final List<_TagEntity> tags;
  const StudentEntity({
    required this.id,
    required this.fullName,
    this.photoUuid = '',
    this.roomName,
    this.tags = const [],
  });
}

class AssignStudentToClassroomForm extends StatefulWidget {
  final VoidCallback onStudentsAssigned; // Add this line
  final String selectedRoomName;

  const AssignStudentToClassroomForm({
    required this.onStudentsAssigned,
    required this.selectedRoomName,
    super.key,
  });

  @override
  State<AssignStudentToClassroomForm> createState() =>
      _AssignStudentToClassroomFormState();
}

class _AssignStudentToClassroomFormState
    extends State<AssignStudentToClassroomForm> {
  bool isSelectAllChecked = false;
  String? _selectedClassroom = '';
  List<String> _selectedTag = [];
  List<StudentEntity> _filteredStudents = [];
  final List<StudentEntity> _allStudents = [];
  final List<String> _allRooms = [];
  final List<String> _allTags = [];
  Set<StudentEntity> selectedStudents = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getAllStudents();
    getAllTags();
    getClassroomsData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void getAllStudents() {
    // UI-only: populate with dummy students
    _allStudents
      ..clear()
      ..addAll([
        StudentEntity(
          id: 1,
          fullName: 'Alice Johnson',
          photoUuid: '',
          roomName: 'Room A',
          tags: const [_TagEntity('Tag 1')],
        ),
        StudentEntity(
          id: 2,
          fullName: 'Bob Smith',
          photoUuid: '',
          roomName: 'Room B',
          tags: const [_TagEntity('Tag 2')],
        ),
        StudentEntity(
          id: 3,
          fullName: 'Charlie Davis',
          photoUuid: '',
          roomName: 'Room A',
          tags: const [_TagEntity('Tag 3')],
        ),
      ]);
    _filterStudents();
    setState(() {});
  }

  void getAllTags() {
    // UI-only: static tags
    _allTags
      ..clear()
      ..addAll(['Tag 1', 'Tag 2', 'Tag 3']);
    setState(() {});
  }

  void getClassroomsData() {
    // UI-only: static rooms, exclude currently selected in filter dropdown later
    _allRooms
      ..clear()
      ..addAll(['Room A', 'Room B', 'Room C']);
    setState(() {});
  }

  void _onSearchChanged() {
    _filterStudents();
  }

  void _filterStudents() {
    final allStudents = _allStudents;
    _filteredStudents = allStudents.where((student) {
      bool matchesSearch = true;
      bool matchesRoom = true;
      bool matchesTag = true;

      if (_searchController.text.isNotEmpty) {
        matchesSearch = student.fullName
            .toLowerCase()
            .contains(_searchController.text.toLowerCase());
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
                hintStyle: TextStyle(fontFamily: 'Manrope', color: Colors.grey[700]),
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
                child: CustomMultiSelectDropdownAssignStudent(
                  hintText: 'Tags',
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
              const Text(
                'Select All',
                style: TextStyle(fontFamily: 'Manrope'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                // UI-only: no backend, show inline SnackBar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select at least one student')),
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
  final VoidCallback onStudentsAssigned;

  const StudentConfirmationForm({
    Key? key,
    required this.selectedStudents,
    required this.selectedRoomName,
    required this.onStudentsAssigned,
  }) : super(key: key);

  @override
  State<StudentConfirmationForm> createState() =>
      _StudentConfirmationFormState();
}

class _StudentConfirmationFormState extends State<StudentConfirmationForm> {
  late Set<StudentEntity> currentSelectedStudents;

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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
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
                      border: Border.all(
                        color: AppColors.themeColor,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromRGBO(249, 245, 250, 1),
                    ),
                    child: Row(
                      children: [
                        StudentProfileImage(
                          imageUrl: student.photoUuid,
                          studentId: student.id,
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
                        )
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
            onPressedConfirm: () {
              if (currentSelectedStudents.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select at least one student')),
                );
                return;
              }
              // UI-only: no backend. Simulate success and close.
              widget.onStudentsAssigned();
              Navigator.pop(context);
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
              StudentProfileImage(
                imageUrl: student.photoUuid,
                studentId: student.id,
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

class StudentProfileImage extends StatefulWidget {
  final String imageUrl;
  final int studentId;
  final double radius;

  const StudentProfileImage({
    Key? key,
    required this.imageUrl,
    required this.studentId,
    this.radius = 16,
  }) : super(key: key);

  @override
  State<StudentProfileImage> createState() => _StudentProfileImageState();
}

class _StudentProfileImageState extends State<StudentProfileImage> {
  // UI-only: remove backend image fetching; keep shimmer to preserve UI feel
  static final Map<String, Uint8List?> _imageCache = {};
  StreamSubscription? _subscription; // not used in UI-only
  Uint8List? _currentImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(StudentProfileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.studentId != widget.studentId) {
      _loadImage();
    }
  }

  void _loadImage() {
    // UI-only: skip downloading; always use placeholder/asset
    setState(() {
      _currentImage = null;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: widget.radius * 2,
          height: widget.radius * 2,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    if (_currentImage == null) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundImage: const AssetImage(MediaRes.userImageMale),
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundImage: MemoryImage(_currentImage!),
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
          fontFamily: 'Manrope',
          color: Color(0xff573353),
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
                    setState(() {}); // Update the main widget state
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
                            setState(() {}); // Update the main widget state
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
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            color: Color(0xff573353),
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
            fontFamily: 'Manrope',
            color:
                _localSelectedItems.isEmpty ? Colors.grey[600] : const Color(0xff573353),
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
