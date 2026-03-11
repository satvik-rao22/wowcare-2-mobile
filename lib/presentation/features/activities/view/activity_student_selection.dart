import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/activities/view/choose_activity.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../app/di/di.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../../../domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import '../../../../domain/features/student_classroom/entities/student_classroom_item.dart';
import '../../../../domain/features/student_classroom/usecases/get_student_classroom_list_usecase.dart';
import '../../../../shared/common/widgets/custom_checkbox.dart';
import '../../../../shared/common/widgets/custom_refresh_indicator.dart';
import '../../../../shared/common/widgets/primary_circular_loader.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/common/widgets/custom_multi_select_dropdown.dart';
import '../../../../shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';

class ActivityStudentSelection extends StatefulWidget {
  const ActivityStudentSelection({super.key});
  final bool showLoading = false;

  @override
  State<ActivityStudentSelection> createState() =>
      _ActivityStudentSelectionState();
}

class _ActivityStudentSelectionState extends State<ActivityStudentSelection> {
  final TextEditingController _searchController = TextEditingController();
  final Set<Map<String, dynamic>> _selectedStudents = <Map<String, dynamic>>{};

  // Filters & options
  String? _selectedClassroom;
  bool _selectAll = false;
  List<String> _selectedTags = [];

  // Options loaded from backend
  List<String> _classroomOptions = [];
  final Map<String, String> _classroomCodeByName = {};

  List<String> _tagOptions = [];
  final Map<String, String> _tagCodeByName = {};

  // API + storage
  late final StorageService _storageService;
  late final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  late final GetTagNameCodeMapForSchoolUseCase _getTagNameCodeMapForSchoolUseCase;
  late final GetStudentClassroomListUseCase _getStudentClassroomListUseCase;
  String? _schoolCode;

  // Students from /api/v1/student-classroom for current filters
  List<StudentClassroomItem> _studentsForCurrentFilters = [];
  bool _isLoadingFilters = false;
  bool _isLoadingStudents = false;
  String? _studentsError;

  List<StudentClassroomItem> get _filteredStudents {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _studentsForCurrentFilters;

    return _studentsForCurrentFilters.where((student) {
      final fullName = student.fullName.toLowerCase();
      return fullName.contains(query);
    }).toList();
  }

  // List<MapEntry<String, List<String>>> get _filteredStudents {
  //   // 1. Start with all students
  //   Map<String, List<String>> allStudents = {};
  //
  //   // If no classroom selected → show all
  //   if (_selectedClassroom == null) {
  //     return [];
  //   } else {
  //     // Only selected classroom
  //     final selected = _studentsInSelectedClassroom[_selectedClassroom];
  //     if (selected != null) {
  //       allStudents = Map<String, List<String>>.from(selected);
  //     } else {
  //       return [];
  //     }
  //   }
  //
  //   // 2. Apply tag filtering if any tags selected
  //   if (_selectedTags.isNotEmpty) {
  //     allStudents.removeWhere((name, tags) {
  //       // Keep student only if they have ALL selected tags
  //       return !_selectedTags.every((tag) => tags.contains(tag));
  //     });
  //   }
  //
  //   // 3. Apply search filter
  //   final query = _searchController.text.trim().toLowerCase();
  //   if (query.isNotEmpty) {
  //     allStudents.removeWhere((name, tags) =>
  //     !name.toLowerCase().contains(query));
  //   }
  //
  //   return allStudents.entries.toList();
  // }

  void _updateSelectAllState() {
    final students = _filteredStudents;
    if (students.isEmpty) {
      _selectAll = false;
      return;
    }

    _selectAll = students.every((student) {
      final code = student.studentCode;
      return _selectedStudents.any((s) => s['studentCode'] == code);
    });
  }

  void _showWarningMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(!mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      final snackBar = SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade50,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.orange.shade100),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }


  @override
  void initState() {
    super.initState();
    _storageService = serviceLocator<StorageService>();
    _getActiveClassroomsUseCase = serviceLocator<GetActiveClassroomsUseCase>();
    _getTagNameCodeMapForSchoolUseCase =
        serviceLocator<GetTagNameCodeMapForSchoolUseCase>();
    _getStudentClassroomListUseCase =
        serviceLocator<GetStudentClassroomListUseCase>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFiltersAndLoad();
    });
  }

  Future<void> _initFiltersAndLoad() async {
    setState(() {
      _isLoadingFilters = true;
    });

    try {
      _schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';

      if (_schoolCode == null || _schoolCode!.trim().isEmpty) {
        _showWarningMessage(
          'School code is not set. Please ensure you are logged in and a school is selected.',
        );
        setState(() {
          _isLoadingFilters = false;
        });
        return;
      }

      await Future.wait([
        _loadClassrooms(),
        _loadTags(),
      ]);

      if (_selectedClassroom != null) {
        await _loadStudentsForCurrentFilters();
      }
    } catch (_) {
      _showWarningMessage('Failed to load filters. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFilters = false;
        });
      }
    }
  }

  Future<void> _loadClassrooms() async {
    if (_schoolCode == null || _schoolCode!.trim().isEmpty) return;

    final classrooms = await _getActiveClassroomsUseCase(
      schoolCode: _schoolCode!,
      onlyTypeClassroom: true,
    );

    if (!mounted) return;

    setState(() {
      _classroomOptions = classrooms.map((c) => c.name).toList();
      _classroomCodeByName
        ..clear()
        ..addEntries(
          classrooms.map(
            (c) => MapEntry(c.name, c.code),
          ),
        );

      _selectedClassroom ??=
          _classroomOptions.isNotEmpty ? _classroomOptions.first : null;
    });
  }

  Future<void> _loadTags() async {
    if (_schoolCode == null || _schoolCode!.trim().isEmpty) return;

    try {
      final nameCodeMap =
          await _getTagNameCodeMapForSchoolUseCase(schoolCode: _schoolCode!);
      if (!mounted) return;
      setState(() {
        _tagCodeByName
          ..clear()
          ..addAll(nameCodeMap);
        _tagOptions = nameCodeMap.keys.toList()..sort();
      });
    } catch (_) {
      // Non-critical for this screen; ignore errors.
    }
  }

  Future<void> _loadStudentsForCurrentFilters({bool refresh = false}) async {
    if (_schoolCode == null ||
        _schoolCode!.trim().isEmpty ||
        _selectedClassroom == null) {
      return;
    }

    final classroomCode = _classroomCodeByName[_selectedClassroom!];
    if (classroomCode == null || classroomCode.trim().isEmpty) return;

    final tagCodes = _selectedTags
        .map((name) => _tagCodeByName[name])
        .whereType<String>()
        .toList();

    setState(() {
      _isLoadingStudents = true;
      _studentsError = null;
    });

    try {
      final students = await _getStudentClassroomListUseCase(
        schoolCode: _schoolCode!,
        classroomCode: classroomCode,
        tagCodes: tagCodes,
        status: const ['ACTIVE'],
        attendanceStatus: 'SIGNED_IN',
        refresh: refresh,
      );

      if (!mounted) return;

      setState(() {
        _studentsForCurrentFilters = students;
        _isLoadingStudents = false;
        _studentsError = null;
      });
      _updateSelectAllState();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingStudents = false;
        _studentsError = 'Failed to load students';
      });
      _showWarningMessage('Failed to load students. Please try again.');
    }
  }

  void _applyFilters() => setState(() {});

  Future<void> _refreshStudents() async {
    await _loadStudentsForCurrentFilters(refresh: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return StaffFormLayout(
      title: 'Add Activity',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Students',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xff573353),
            ),
          ),
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
                hintStyle: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[700],
                ),
                border: InputBorder.none,
                icon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                          _updateSelectAllState();
                        },
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
              ),
              onChanged: (_) {
                _applyFilters();
                _updateSelectAllState();
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCustomDropdown(
                  'Classroom',
                  _classroomOptions,
                  _selectedClassroom,
                  (v) {
                    setState(() {
                      _selectedClassroom = v;
                      // Students across classrooms cannot be selected together
                      _selectedStudents.clear();
                      _selectAll = false;
                    });
                    _loadStudentsForCurrentFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomMultiSelectDropdown(
                  hintText: 'Tags',
                  items: _tagOptions,
                  selectedItems: _selectedTags,
                  gapHeight: 40,
                  onChanged: (selectedItems) {
                    setState(() {
                      _selectedTags = selectedItems;
                    });
                    _loadStudentsForCurrentFilters();
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
                  value: _selectAll,
                  onChanged: (v) {
                    final newVal = v ?? false;
                    setState(() {
                      _selectAll = newVal;
                      if (newVal) {
                        for (final student in _filteredStudents) {
                          _selectedStudents.add({
                            'name': student.fullName,
                            'classroom': _selectedClassroom!,
                            'classroomCode': student.classroomCode,
                            'studentCode': student.studentCode,
                            'profilePictureUrl': student.profilePictureUrl,
                            'status': student.status,
                            'expectedToday': student.expectedToday,
                            'signedIn': student.signedIn,
                            'absent': student.absent,
                            'notMarked': student.notMarked,
                            'nappingStatus': student.nap,
                            'photoPermission': student.photoPermission,
                            'notes': student.notes,
                            'medication': student.medication,
                            'allergies': student.allergies,
                            'dietaryRestriction': student.dietaryRestriction,
                          });
                        }
                      } else {
                        _selectedStudents.removeWhere(
                          (s) => s['classroom'] == _selectedClassroom,
                        );
                      }
                    });
                  },
                  borderColor: AppColors.themeColor,
                ),
              ),
              Text(
                'Select All',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff573353),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_classroomOptions.isNotEmpty) {
                      _selectedClassroom = _classroomOptions.first;
                    }
                    _selectedStudents.clear();
                    _searchController.clear();
                    _selectedTags = [];
                    _selectAll = false;
                  });
                  _loadStudentsForCurrentFilters();
                },
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoadingFilters || _isLoadingStudents
                ? const Center(child: PrimaryCircularLoader())
                : _filteredStudents.isEmpty
                    ? Center(
                        child: Text(
                          _selectedClassroom == null
                              ? 'Select a classroom to view students or use the search bar'
                              : (_studentsError ??
                                  'No students match the selected filters'),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontFamily: 'Manrope',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : CustomRefreshIndicator(
                        onRefresh: _refreshStudents,
                        child: GridView.builder(
                          shrinkWrap: false,
                          physics: const AlwaysScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: responsive.isTablet ? 3 : 2,
                            crossAxisSpacing: responsive.isTablet ? 16 : 12,
                            mainAxisSpacing: responsive.isTablet ? 16 : 12,
                            mainAxisExtent: 52,
                          ),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            final String name = student.fullName;
                            final bool isNapping = student.nap;
                            final String studentCode = student.studentCode;

                            final bool isSelected = _selectedStudents.any(
                              (s) => s['studentCode'] == studentCode,
                            );

                            return _ActivityStudentListItem(
                              name: name,
                              isSelected: isSelected,
                              onSelectionChanged: (selected) {
                                ScaffoldMessenger.of(context)
                                    .removeCurrentSnackBar();
                                setState(() {
                                  if (selected == true) {
                                    _selectedStudents.add({
                                      'name': name,
                                      'classroom': _selectedClassroom!,
                                      'classroomCode': student.classroomCode,
                                      'studentCode': student.studentCode,
                                      'profilePictureUrl':
                                          student.profilePictureUrl,
                                      'status': student.status,
                                      'expectedToday': student.expectedToday,
                                      'signedIn': student.signedIn,
                                      'absent': student.absent,
                                      'notMarked': student.notMarked,
                                      'nappingStatus': isNapping,
                                      'photoPermission': student.photoPermission,
                                      'notes': student.notes,
                                      'medication': student.medication,
                                      'allergies': student.allergies,
                                      'dietaryRestriction':
                                          student.dietaryRestriction,
                                    });
                                  } else {
                                    _selectedStudents.removeWhere(
                                      (s) =>
                                          s['studentCode'] == studentCode,
                                    );
                                  }
                                  _updateSelectAllState();
                                });
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomBar: Padding(
        padding: EdgeInsets.only(bottom: safeAreaBottom),
        child: CustomButtonLayout(
          confirmButtonLabel: 'Next',
          cancelButtonLabel: 'Cancel',
          onPressedCancel: () => Navigator.of(context).pop(),
          onPressedConfirm: () {
            if (_selectedStudents.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChooseActivity(
                    selectedStudents: _selectedStudents.toList(),
                  ),
                ),
              );
            } else {
              _showWarningMessage('Select at least one student.');
            }
          },
        ),
      ),
    );
  }

  Widget _buildCustomDropdown(
    String hintText,
    List<String> items,
    String? selectedItem,
    ValueChanged<String?> onSelect, {
    bool isRequired = false,
    double? height = null,
  }) {
    final responsive = ResponsiveHelper(context);
    return CustomDropdown(
      label: null,
      hintText: hintText,
      items: items,
      height: height,
      selectedItem: selectedItem,
      onSelect: onSelect,
      showAsterisk: isRequired,
      labelStyle: TextStyle(
        fontSize: responsive.labelFontSize,
        fontFamily: "Manrope",
        fontWeight: FontWeight.w400,
        color: const Color(0xff573353),
      ),
      labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
      //fieldHeight: responsive.isTablet ? 64.0 : 56.0,
      fieldHeight: 40,
      selectedTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: responsive.inputFontSize,
        fontWeight: FontWeight.w600,
        color: const Color(0xff573353),
        height: 19 / 14,
      ),
      popupItemTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: responsive.inputFontSize,
        fontWeight: FontWeight.w400,
        color: const Color(0xff573353),
      ),
      // contentPadding: EdgeInsets.symmetric(
      //   horizontal: responsive.isTablet ? 16.0 : 12.0,
      //   vertical: responsive.isTablet ? 16.0 : 12.0,
      // ),
    );
  }

  // Widget _buildShimmer() {
  //   return GridView.builder(
  //       padding: EdgeInsets.zero,
  //       physics: const NeverScrollableScrollPhysics(),
  //       shrinkWrap: true,
  //       itemCount: widget.sections.length,
  //       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.6),
  //       itemBuilder: (context, index) {
  //         return Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(widget.sections[index].label, style: TextStyle(color: AppColors.primaryColor, fontSize: 13),),
  //             const SizedBox(height: 8,),
  //             const ShimmerLoader(height: 40,)
  //           ],
  //         );
  //       }
  //   );
  // }

}

class _ActivityStudentListItem extends StatelessWidget {
  final String name;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;

  const _ActivityStudentListItem({
    required this.name,
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
                fileUuid: '',
                name: name,
                size: 32,
                fontSize: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name.split(' ').first,
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
