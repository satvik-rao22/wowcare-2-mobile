import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/activity_status_panel.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/presentation/features/classrooom/views/widgets/classroom_student_list_item.dart';
import 'package:wowcare/presentation/features/students/widgets/student_action_panel.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen.dart';
// Backend/bloc and feature imports disabled for UI-only mode
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:wowcare/core/extentions/context_extentions.dart';
// import 'package:wowcare/core/services/injection_container.dart';
// import 'package:wowcare/core/util/api_paths.dart';
// import 'package:wowcare/core/util/constants.dart';
// import 'package:wowcare/core/util/core_utils.dart';
// import 'package:wowcare/core/util/typedefs.dart';
// import 'package:wowcare/features/...';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';

// import '../../../../../features/student/data/model/studentDataModel.dart';

// Local typedefs and dummy entities for UI-only usage
typedef DataMap = Map<String, dynamic>;

class RoomDTO {
  final int id;
  final String name;
  const RoomDTO({required this.id, required this.name});
}

class StudentEntity {
  final int id;
  final String fullName;
  final String photoUuid;
  final String profileStatus; // 'A' or 'Upcoming'
  final bool isSignedIn;
  final bool isAbsent;
  final bool isExpectedToday;
  final String medications;
  final String note;
  final String allergies;
  final String dietRestriction;
  final int roomId;
  final int? schoolId;
  final List<_Tag> tags;
  final List<String>? ongoingActivities;

  StudentEntity({
    required this.id,
    required this.fullName,
    this.photoUuid = '',
    this.profileStatus = 'A',
    this.isSignedIn = false,
    this.isAbsent = false,
    this.isExpectedToday = true,
    this.medications = '',
    this.note = '',
    this.allergies = '',
    this.dietRestriction = '',
    required this.roomId,
    this.schoolId,
    this.tags = const [],
    this.ongoingActivities,
  });
}

class _Tag {
  final String name;
  const _Tag(this.name);
}

class ClassroomStudentsTabCard extends StatefulWidget {
  const ClassroomStudentsTabCard({
    required this.scrollController,
    required this.selectedRoom,
    super.key,
  });

  final ScrollController scrollController;
  final RoomDTO? selectedRoom;

  @override
  State<ClassroomStudentsTabCard> createState() =>
      _ClassroomStudentsTabCardState();
}

class _ClassroomStudentsTabCardState extends State<ClassroomStudentsTabCard> {
  final TextEditingController _searchController = TextEditingController();
  bool isSelectAllChecked = false;
  Map<String, bool> studentSelections = {};
  List<String> _selectedStatus = [];
  List<String> _selectedTag = [];
  List<StudentEntity> _filteredStudents = [];
  bool _isNappingFilter = false; // Toggle for napping students
  List<StudentEntity> _nappingStudents = []; // List to store napping students
  List<StudentEntity> _allStudents = [];
  bool _isPresentFilter = false; // Toggle for present students
  StudentPanelType _currentPanel = StudentPanelType.none;
  bool _showActivitiesPanel = false;

  final List<String> statusDisplayValues = ['Active', 'Upcoming'];
  final List<String> stasuses = ['A', 'Upcoming'];

  final List<String> tags = [
    'Tag 1',
    'Tag 2',
    'Tag 3',
  ];

  void getAllStudents() {
    // Backend disabled: using dummy local students while preserving UI
    final roomId = widget.selectedRoom?.id ?? 0;
    _allStudents = [
      StudentEntity(
        id: 1,
        fullName: 'Alice Johnson',
        profileStatus: 'A',
        isSignedIn: true,
        isAbsent: false,
        isExpectedToday: true,
        medications: 'Asthma Inhaler',
        note: 'Bring homework',
        allergies: 'Peanuts',
        dietRestriction: 'Vegetarian',
        roomId: roomId,
        tags: const [_Tag('Tag 1')],
        ongoingActivities: ['Nap start']
      ),
      StudentEntity(
        id: 2,
        fullName: 'Bob Smith',
        profileStatus: 'Upcoming',
        isSignedIn: false,
        isAbsent: false,
        isExpectedToday: false,
        roomId: roomId,
        tags: const [_Tag('Tag 2')],
        ongoingActivities: ['Bathroom']
      ),
      StudentEntity(
        id: 3,
        fullName: 'Charlie Davis',
        profileStatus: 'A',
        isSignedIn: false,
        isAbsent: true,
        isExpectedToday: true,
        roomId: roomId,
        tags: const [_Tag('Tag 3')],
        ongoingActivities: ['Medication']
      ),
      StudentEntity(
          id: 4,
          fullName: 'Alex Song',
          profileStatus: 'A',
          isSignedIn: true,
          isAbsent: false,
          isExpectedToday: true,
          medications: 'Asthma Inhaler',
          note: 'Bring homework',
          allergies: 'Peanuts',
          dietRestriction: 'Vegetarian',
          roomId: roomId,
          tags: const [_Tag('Tag 1')],
          ongoingActivities: ['Meal']
      ),
    ];
    // Mark first student as napping for demo
    _nappingStudents = [_allStudents.first];
    studentSelections.clear();
    _filterStudents();
    setState(() {});
  }

  void getAllTags() {
    // Backend disabled; static tags list already present
  }

  Future<void> fetchNappingStudents() async {
    // Backend disabled; napping students are set locally in getAllStudents
  }

  @override
  void initState() {
    super.initState();
    getAllStudents();
    getAllTags();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(ClassroomStudentsTabCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRoom != widget.selectedRoom) {
      setState(() {
        isSelectAllChecked = false;
        studentSelections.updateAll((key, val) => false);
        _searchController.clear();
        _selectedStatus = [];
        _selectedTag = [];
        _filteredStudents = [];
        _isNappingFilter = false;
        _nappingStudents = [];
      });
      getAllStudents();
    }
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

  List<StudentEntity> _filterStudents() {
      final allStudents = _allStudents;
      if (_isNappingFilter) {
        // Start from napping students, optionally apply present filter
        _filteredStudents = List<StudentEntity>.from(_nappingStudents);
        if (_isPresentFilter) {
          _filteredStudents = _filteredStudents
              .where((student) => student.isSignedIn)
              .toList();
        }
        setState(() {});
        return _filteredStudents;
      }
      if (_searchController.text.isEmpty &&
          _selectedStatus.isEmpty &&
          _selectedTag.isEmpty) {
        _filteredStudents = _isPresentFilter
            ? allStudents.where((s) => s.isSignedIn).toList()
            : allStudents;
        setState(() {});
        return _filteredStudents;
      }

      _filteredStudents = allStudents.where((student) {
        bool matchesSearch = true;
        bool matchesStatus = true;
        bool matchesTag = true;
        bool matchesPresent = true;

        if (_searchController.text.isNotEmpty) {
          matchesSearch = student.fullName
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
        }

        if (_selectedStatus.isNotEmpty) {
          matchesStatus = _selectedStatus.contains(student.profileStatus);
        }

        if (_selectedTag.isNotEmpty) {
          matchesTag = student.tags.any((tag) => _selectedTag.contains(tag.name));
        }
        if (_isPresentFilter) {
          matchesPresent = student.isSignedIn;
        }

        return matchesSearch && matchesStatus && matchesTag && matchesPresent;
      }).toList();
      setState(() {});
      return _filteredStudents;
  }

  void _toggleSelectAll(bool? value) {
    if (value == null) return;

    setState(() {
      isSelectAllChecked = value;

      final List<StudentEntity> visibleStudents = _getVisibleStudents();

      for (var student in visibleStudents) {
        studentSelections[student.fullName] = value;
      }
    });
  }

  void _toggleStudentSelection(String name, bool? value) {
    if (value == null) return;

    setState(() {
      studentSelections[name] = value;

      final List<StudentEntity> visibleStudents = _getVisibleStudents();

      isSelectAllChecked = visibleStudents.every(
        (student) => studentSelections[student.fullName] == true,
      );

      // Reset panel if no students are selected
      if (!hasSelectedStudents) {
        _currentPanel = StudentPanelType.none;
      }
    });
  }

  bool get hasSelectedStudents {
    return studentSelections.values.any((selected) => selected);
  }

  List<StudentEntity> _getVisibleStudents() {
      return _filteredStudents.isEmpty &&
              _searchController.text.isEmpty &&
              _selectedStatus.isEmpty &&
              _selectedTag.isEmpty &&
              !_isNappingFilter
          ? _allStudents
          : _filteredStudents;
  }

  void _clearAllSelections() {
    setState(() {
      isSelectAllChecked = false;
      studentSelections.updateAll((key, val) => false);
      _searchController.clear();
      _selectedStatus = ['A'];
      _selectedTag = [];
      _isNappingFilter = false;
      _currentPanel = StudentPanelType.none;
      _filterStudents();
    });
  }

  int get _selectedCount {
    return studentSelections.values.where((selected) => selected).length;
  }

  List<StudentEntity> _getSelectedStudents() {
    final List<StudentEntity> visibleStudents = _getVisibleStudents();
    return visibleStudents
        .where((student) => studentSelections[student.fullName] == true)
        .toList();
  }

  DataMap _getStudentIcons(StudentEntity student) {
    DataMap icons = {};

    if (_nappingStudents
        .any((nappingStudent) => nappingStudent.id == student.id)) {
      icons["napping"] = {
        "icon": 'assets/images/icons/sleep.png',
        "info": 'Student is napping',
      };
    }
    // if (!student.isPhotoPermission) {
    //   icons["photo"] = {
    //     "icon": MediaRes.cameraIcon,
    //     "info": student.isPhotoPermission
    //         ? 'No Photo Permission'
    //         : 'No Photo Permission',
    //   };
    // }
    if (student.medications.isNotEmpty) {
      icons["medication"] = {
        "icon": MediaRes.healthIcon,
        "info": student.medications
      };
    }
    if (student.note.isNotEmpty) {
      icons["note"] = {"icon": MediaRes.docsIcon, "info": student.note};
    }
    if (student.allergies.isNotEmpty) {
      icons["allergies"] = {
        "icon": MediaRes.alertIcon,
        "info": student.allergies
      };
    }
    if (student.dietRestriction.isNotEmpty) {
      icons["dietRestriction"] = {
        "icon": MediaRes.foodIcon2,
        "info": student.dietRestriction
      };
    }

    return icons;
  }

  List<String> _getCombinedOngoingActivities(){
    final selectedStudents = _getSelectedStudents();
    final Set<String> activities = {};
    for (final student in selectedStudents){
      activities.addAll(student.ongoingActivities as Iterable<String>);
    }
    return activities.toList();
  }

  bool _canShowActivitiesPanel() {
    if(!hasSelectedStudents) return false;

    final selectedStudents = _getSelectedStudents();
    return selectedStudents.every((student) => student.isSignedIn);
  }

  // Backend disabled
  // Future<List<GuardianEntity>> getGuardianInfoForStudent(String studentId) async { return []; }

  // Backend disabled
  // Future<List<Staff>> fetchAllStaffs() async { return []; }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.all(0),
            shape: const Border(
              left: BorderSide(color: AppColors.themeColor),
              top: BorderSide(color: AppColors.themeColor),
              right: BorderSide(color: AppColors.themeColor),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SearchBar(
                          controller: _searchController,
                          constraints: const BoxConstraints(minHeight: 36),
                          hintText: 'Search',
                          hintStyle: const WidgetStatePropertyAll(
                            TextStyle(
                              fontFamily: 'Manrope',
                              color: Color.fromRGBO(87, 51, 83, 0.7),
                              fontSize: 13,
                            ),
                          ),
                          leading: const Icon(
                            Icons.search,
                            color: AppColors.primaryColor,
                            size: 18,
                          ),
                          elevation: const WidgetStatePropertyAll(0),
                          side: const WidgetStatePropertyAll(
                            BorderSide(
                              width: 1,
                              color: Color.fromARGB(255, 188, 173, 186),
                            ),
                          ),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          // TODO: Open filters screen/modal
                        },
                        icon: SvgPicture.asset(
                          MediaRes.filterIcon,
                          height: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: CustomCheckbox(
                              borderColor:
                                  AppColors.primaryColor.withValues(alpha: 0.2),
                              value: isSelectAllChecked,
                              onChanged: _toggleSelectAll,
                            ),
                          ),
                          const Text(
                            'Select All',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              color: AppColors.primaryColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color:
                                      const Color.fromRGBO(177, 175, 233, 0.3),
                                ),
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 3,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {},
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      color: Color.fromRGBO(27, 35, 126, 1),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: AppColors.buildPrimaryGradient(),
                                ),
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 3,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _clearAllSelections,
                                  child: const Text(
                                    'Clear All',
                                    style: TextStyle(fontFamily: 'Manrope', fontSize: 12),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Information'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children:
                                              details.entries.map((entry) {
                                            bool isSvg =
                                                entry.key.endsWith('.svg');
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4.0),
                                              child: Row(
                                                children: [
                                                  isSvg
                                                      ? SvgPicture.asset(
                                                          entry.key,
                                                          width: 24,
                                                          height: 24,
                                                        )
                                                      : Image.asset(
                                                          entry.key,
                                                          width: 24,
                                                          height: 24,
                                                        ),
                                                  const SizedBox(width: 20),
                                                  Expanded(
                                                    child: Text(
                                                      entry.value,
                                                      style: const TextStyle(
                                                          fontFamily: 'Manrope', fontSize: 14),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text('Close'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.primaryColor,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CustomToggle(
                            label: 'Present',
                            isToggled: _isPresentFilter,
                            onToggle: (value) {
                              setState(() {
                                _isPresentFilter = value;
                                _filterStudents();
                              });
                            },
                            labelStyle: const TextStyle(
                              fontFamily: 'Manrope',
                              color: AppColors.primaryColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 20),
                          CustomToggle(
                            label: 'Napping',
                            isToggled: _isNappingFilter,
                            onToggle: (value) {
                              setState(() {
                                _isNappingFilter = value;
                                _filterStudents();
                              });
                            },
                            labelStyle: const TextStyle(
                              fontFamily: 'Manrope',
                              color: AppColors.primaryColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                          final displayedStudents = _filteredStudents.isEmpty &&
                                  _searchController.text.isEmpty &&
                                  _selectedStatus.isEmpty &&
                                  _selectedTag.isEmpty &&
                                  !_isNappingFilter
                            ? _allStudents
                                .where((student) => student.profileStatus == 'A')
                                  .toList()
                              : _filteredStudents;

                          displayedStudents
                              .sort((a, b) => a.fullName.compareTo(b.fullName));

                          if (displayedStudents.isEmpty) {
                            return CustomRefreshIndicator(
                              onRefresh: () async {
                                getAllStudents();
                              },
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return ListView(
                                    children: [
                                      SizedBox(
                                        height: constraints.maxHeight,
                                        child: Center(
                                          child: Text(
                                            _isNappingFilter
                                                ? 'No students are napping.'
                                                : 'No students assigned.',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 16,
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.6),
                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          }

                          return CustomRefreshIndicator(
                            onRefresh: () async {
                              getAllStudents();
                            },
                            child: ListView.builder(
                              itemCount: displayedStudents.length,
                              itemBuilder: (context, index) {
                                final student = displayedStudents[index];
                              return ClassroomStudentListItem(
                                    studentId: student.id,
                                    isSignedIn: student.isSignedIn,
                                    isAbsent: student.isAbsent,
                                    isExpectedToday: student.isExpectedToday,
                                    studentStatus: student.profileStatus,
                                    name: student.fullName,
                                    imageUrl: student.photoUuid,
                                    icons: _getStudentIcons(student),
                                    isSelected:
                                    studentSelections[student.fullName] ?? false,
                                    onSelectionChanged: (bool? value) {
                                      _toggleStudentSelection(
                                          student.fullName, value);
                                    },
                              );
                            },
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
        // StudentActionPanel shown when students are selected
        if (hasSelectedStudents)
          Positioned(
            right: 16,
            bottom: 16,
            child: Row(
              children: [
                if(_showActivitiesPanel && _canShowActivitiesPanel())
                  ActivityStatusPanel(onGoingActivities: _getCombinedOngoingActivities(), isSignedIN: true,),
                const SizedBox(width: 10,),
                StudentActionPanel(
                  currentPanel: _currentPanel,
                  onAttendanceTap: () {
                    // TODO: Implement attendance functionality
                  },
                  onMessageTap: () {
                    // TODO: Implement message functionality
                  },
                  onActivitiesTap: _canShowActivitiesPanel() ? () {
                    setState(() {
                      _showActivitiesPanel = !_showActivitiesPanel;
                      _currentPanel = _showActivitiesPanel ? StudentPanelType.activities : StudentPanelType.none;
                    });
                  } : null,
                  onProfileTap: _selectedCount == 1
                      ? () {
                          final selectedStudents = _getSelectedStudents();
                          if (selectedStudents.isNotEmpty) {
                            final student = selectedStudents.first;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentProfileScreen(
                                  name: student.fullName,
                                  classroom: widget.selectedRoom?.name ?? 'Unknown Class',
                                  tags: student.tags.map((tag) => tag.name).toList(),
                                  schedule: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'], // Default schedule
                                  sibling: {'name': [], 'relation': [], 'status': []}, // Default empty sibling data
                                  studentCode: student.id.toString(),
                                ),
                              ),
                            );
                          }
                        }
                      : null,
                  onClearSelections: () {
                    setState(() {
                      isSelectAllChecked = false;
                      studentSelections.updateAll((key, val) => false);
                      _showActivitiesPanel = false;
                      _currentPanel = StudentPanelType.none;
                    });
                  },
                  isProfileEnabled: _selectedCount == 1,
                  activitiesEnabled: _canShowActivitiesPanel(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class CustomMultiSelectDropdown extends StatefulWidget {
  final String hintText;
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;
  final bool isField;
  final double? width;

  const CustomMultiSelectDropdown({
    Key? key,
    required this.hintText,
    required this.items,
    required this.selectedItems,
    required this.onChanged,
    this.isField = false,
    this.width,
  }) : super(key: key);

  @override
  State<CustomMultiSelectDropdown> createState() =>
      _CustomMultiSelectDropdownState();
}

class _CustomMultiSelectDropdownState extends State<CustomMultiSelectDropdown> {
  late List<String> _localSelectedItems;

  @override
  void initState() {
    super.initState();
    _localSelectedItems = List.from(widget.selectedItems);
  }

  @override
  void didUpdateWidget(CustomMultiSelectDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.selectedItems, widget.selectedItems)) {
      _localSelectedItems = List.from(widget.selectedItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayText = _localSelectedItems.isEmpty
        ? widget.hintText
        : '${_localSelectedItems.length} selected';

    return Container(
      height: 32,
      width: widget.width,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.primaryColor.withValues(alpha: 0.1),
          hintText: widget.hintText,
          contentPadding: const EdgeInsets.symmetric(horizontal: 5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Colors.transparent,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Colors.transparent,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Colors.transparent,
            ),
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
              builder: (BuildContext context, StateSetter setState) {
                final isSelected = _localSelectedItems.contains(item);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _localSelectedItems.remove(item);
                      } else {
                        _localSelectedItems.add(item);
                      }
                    });
                    widget.onChanged(_localSelectedItems);
                  },
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomCheckbox(
                          value: isSelected,
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) {
                                _localSelectedItems.add(item);
                              } else {
                                _localSelectedItems.remove(item);
                              }
                            });
                            widget.onChanged(_localSelectedItems);
                          },
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
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

Map<String, String> details = {
  'assets/images/icons/sleep.png': 'Student is napping',
  MediaRes.cameraIcon: 'No Photo',
  MediaRes.healthIcon: 'Medication',
  MediaRes.docsIcon: 'Notes',
  MediaRes.alertIcon: 'Allergies',
  MediaRes.foodIcon2: 'Dietary Restrictions',
};
