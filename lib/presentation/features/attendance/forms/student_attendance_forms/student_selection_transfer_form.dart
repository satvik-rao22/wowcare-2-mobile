import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/ellipsis_tooltip_text.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/simmer_loader.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_transfer_form_list_usecase.dart';
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
  String? _selectedClassroom = null;
  String? _selectedClassroomCode;
  List<String> _selectedTag = [];
  List<StudentEntity> _filteredStudents = [];
  Set<StudentEntity> selectedStudents = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  late final GetStudentTransferFormListUseCase
  _getStudentTransferFormListUseCase;

  // Backing list populated from the Transfer form API.
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
    _getStudentTransferFormListUseCase =
        serviceLocator<GetStudentTransferFormListUseCase>();
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
          _selectedClassroom = '';
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
        _selectedClassroom = null;
        _selectedClassroomCode = null;
      }
      _isClassroomDataReady = _classroomList.isNotEmpty;
    });
  }

  Future<void> _loadStudents() async {
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

      final tagCodes = _selectedTag.isNotEmpty ? _selectedTag : null;

      final searchText = _searchController.text.trim().isNotEmpty
          ? _searchController.text.trim()
          : null;

      final page = await _getStudentTransferFormListUseCase(
        fromAttendanceDate: dateString,
        toAttendanceDate: dateString,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        search: searchText,
        page: 0,
        size: 200,
      );

      final students = page.items.asMap().entries.map((entry) {
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
          tags: item.tagNames.map((name) => TagEntity(name: name)).toList(),
        );
      }).toList();

      // Build tag list from API data if available
      final tagSet = <String>{};
      for (final item in page.items) {
        tagSet.addAll(item.tagNames);
      }

      setState(() {
        _allStudents = students;
        _isLoading = false;
        _tags = tagSet.isNotEmpty ? tagSet.toList() : _tags;
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

        if (_selectedClassroom != null && _selectedClassroom!.isNotEmpty) {
          matchesRoom = _selectedClassroom == student.roomName;
        }

        if (_selectedTag.isNotEmpty) {
          matchesTag = student.tags.any(
            (tag) => _selectedTag.contains(tag.name),
          );
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
        matchesSearch = student.fullName.toLowerCase().contains(
          _searchController.text.toLowerCase(),
        );
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
      itemBuilder: (context, index) =>
          const ShimmerLoaderCard(child: SizedBox()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    return StaffFormLayout(
      title: 'Transfer',
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

                    if (isLoading && items.isEmpty) {
                      return const ShimmerLoaderCard(child: SizedBox());
                    }

                    return CustomDropdown(
                      selectedItem: _selectedClassroom,
                      onSelect: (value) {
                        if (isLoading) return;
                        setState(() {
                          _selectedClassroom = value;
                          _selectedClassroomCode = value == null
                              ? null
                              : _classroomNameToCode[value];
                          _filterStudents();
                        });
                        _loadStudents();
                      },
                      hintText: 'Classroom',
                      items: items,
                      isField: true,
                      isEnabled: true,
                    );
                  },
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
                : _filteredStudents.isEmpty
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
      bottomBar: Padding(
        padding: EdgeInsets.only(bottom: safeAreaBottom),
        child: CustomButtonLayout(
          confirmButtonLabel: 'Next',
          onPressedConfirm: () {
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
                  builder: (context) => StudentTransferForm(
                    students: selectedStudents.toSet().toList(),
                    classroomNameToCode: _classroomNameToCode,
                  ),
                ),
              );
            }
          },
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
        style: const TextStyle(color: Colors.black87, fontSize: 16),
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
                      CustomCheckbox(
                        value: isSelected,
                        borderColor: AppColors.themeColor,
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
            color: _localSelectedItems.isEmpty
                ? Colors.grey[600]
                : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
