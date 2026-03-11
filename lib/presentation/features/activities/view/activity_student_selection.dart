import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/activities/view/choose_activity.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/common/widgets/custom_checkbox.dart';
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
  String? _selectedClassroom;
  bool _selectAll = false;
  List<String> _selectedTags = [];
  final List<String> _classroomOptions = ['1-Blue D', '3-Orange-D', '2-Red A'];
  final Map<String, dynamic> _studentsInSelectedClassroom = {
    '1-Blue D': {
      'Ajay': {'tags' :['5 Days', 'Full Day', 'Photo Permission'], 'nappingStatus' : true,},
      'Lex': {'tags': ['Full Day', 'Photo Permission', 'Vegetarian', 'First Aid'], 'nappingStatus' : false},
      'Brinder': {'tags': [
        '5 Days',
        'Photo Permission',
        'Vegetarian',
        'First Aid',
        'Allergy',
        'Pickup Authorized',
        'Medication',
        'Half Day',
      ], 'nappingStatus' : false}
    },
    '3-Orange-D': {
      'Devi': {'tags': [
        '5 Days',
        'Full Day',
        'Photo Permission',
        'Vegetarian',
        'First Aid',
        'Allergy',
        'Pickup Authorized',
        'Medication',
      ], 'nappingStatus': false},
      'Jessica': {'tags': [
        'Allergy',
        'Pickup Authorized',
        'Medication',
        'Half Day',
        'Girl',
      ], 'nappingStatus' : true},
      'Kimberly': {'tags' : ['Allergy', 'Pickup Authorized', 'Girl'], 'nappingStatus' : false},
      'Nichole': {'tags': ['5 Days', 'Full Day', 'Photo Permission'], 'nappingStatus': true}
    },
    '2-Red A': {
      'Sree': {'tags': ['5 Days', 'Full Day', 'Photo Permission'], 'nappingStatus' : false},
      'Aria': {'tags': ['5 Days', 'Full Day', 'Photo Permission'], 'nappingStatus' : false},
      'Kabir': {'tags': ['5 Days', 'Half Day', 'Photo Permission'], 'nappingStatus' : true},
      'Sara': {'tags': ['5 Days', 'Full Day', 'Photo Permission'], 'nappingStatus' : true},
      'Raghav': {'tags': ['5 Days', 'Half Day', 'Photo Permission'], 'nappingStatus' : false},
    },
  };
  final List<String> _tagOptions = [
    '5 Days',
    'Full Day',
    'Photo Permission',
    'Vegetarian',
    'First Aid',
    'Allergy',
    'Pickup Authorized',
    'Medication',
    'Half Day',
    'Boy',
    'Girl',
  ];
  Set<Map<String, dynamic>> _selectedStudents = <Map<String, dynamic>>{};

  List<MapEntry<String, Map<String, dynamic>>> get _filteredStudents {
    final query = _searchController.text.trim().toLowerCase();
    final Map<String, Map<String, dynamic>> resultMap = {};

    if (_selectedClassroom == null) {
      return [];
    }

    // Get the students of the selected classroom
    final classroomStudents = _studentsInSelectedClassroom[_selectedClassroom];
    if (classroomStudents == null) {
      return [];
    }

    resultMap.addAll(classroomStudents);

    if (_selectedTags.isNotEmpty) {
      resultMap.removeWhere((name, info) =>
      !_selectedTags.every((tag) => (info['tags'] as List<String>).contains(tag)));
    }

    // Apply search filter (if there's a query)
    if (query.isNotEmpty) {
      resultMap.removeWhere((name, _) => !name.toLowerCase().contains(query));
    }

    return resultMap.entries.toList();
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
    if (_filteredStudents.isEmpty) {
      _selectAll = false;
    } else {
      _selectAll = _filteredStudents
          .every((entry) => _selectedStudents.any((s) => s['name'] == entry.key && s['classroom'] == _selectedClassroom));
    }
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
    _selectedClassroom = _classroomOptions.first;
  }

  void _applyFilters() => setState(() {});

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
                  (v) => setState(() {
                    _selectedClassroom = v;
                    _selectedStudents.clear(); // students across classrooms can not be selected together
                    _selectAll = false;
                    _updateSelectAllState();
                  }),
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
                      _updateSelectAllState();
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
                  value: _selectAll,
                  onChanged: (v) {
                    final newVal = v ?? false;
                    setState(() {
                      _selectAll = newVal;
                      if (newVal) {
                        for (final entry in _filteredStudents) {
                          final name = entry.key;
                          final info = entry.value;
                          final bool isNapping =
                              info['nappingStatus'] as bool;

                          _selectedStudents.add({
                            'name': name,
                            'classroom': _selectedClassroom!,
                            'tags': info['tags'],
                            'nappingStatus': isNapping,
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
                    _selectedClassroom = _classroomOptions.first;
                    _selectedStudents.clear();
                    _searchController.clear();
                    _selectedTags = [];
                    _selectAll = false;
                    _updateSelectAllState();
                  });
                },
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filteredStudents.isEmpty
                ? Center(
                    child: Text(
                      _selectedClassroom == null
                          ? 'Select a classroom to view students or use the search bar'
                          : 'No students match the selected filters',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontFamily: 'Manrope',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: false,
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: responsive.isTablet ? 3 : 2,
                      crossAxisSpacing: responsive.isTablet ? 16 : 12,
                      mainAxisSpacing: responsive.isTablet ? 16 : 12,
                      mainAxisExtent: 52,
                    ),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      final String name = student.key;
                      final Map<String, dynamic> studentInfo = student.value;
                      final bool isNapping = studentInfo['nappingStatus'];
                      final bool isSelected = _selectedStudents.any(
                        (s) =>
                            s['name'] == name &&
                            s['classroom'] == _selectedClassroom,
                      );

                      return _ActivityStudentListItem(
                        name: name,
                        isSelected: isSelected,
                        onSelectionChanged: (selected) {
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          setState(() {
                            if (selected == true) {
                              _selectedStudents.add({
                                'name': name,
                                'classroom': _selectedClassroom!,
                                'tags': studentInfo['tags'],
                                'nappingStatus': isNapping,
                              });
                            } else {
                              _selectedStudents.removeWhere(
                                (s) =>
                                    s['name'] == name &&
                                    s['classroom'] == _selectedClassroom,
                              );
                            }
                            _updateSelectAllState();
                          });
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
