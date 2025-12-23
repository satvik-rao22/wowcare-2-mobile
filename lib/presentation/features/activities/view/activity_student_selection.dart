import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/activities/view/choose_activity.dart';
import 'package:wowcare/presentation/features/activities/widgets/student_tile.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../shared/common/widgets/custom_checkbox.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/common/widgets/custom_multi_select_dropdown.dart';
import '../../../../shared/common/widgets/custom_search_bar.dart';

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
      'Ajay': ['5 Days', 'Full Day', 'Photo Permission'],
      'Lex': ['Full Day', 'Photo Permission', 'Vegetarian', 'First Aid'],
      'Brinder': [
        '5 Days',
        'Photo Permission',
        'Vegetarian',
        'First Aid',
        'Allergy',
        'Pickup Authorized',
        'Medication',
        'Half Day',
      ],
    },
    '3-Orange-D': {
      'Devi': [
        '5 Days',
        'Full Day',
        'Photo Permission',
        'Vegetarian',
        'First Aid',
        'Allergy',
        'Pickup Authorized',
        'Medication',
      ],
      'Jessica': [
        'Allergy',
        'Pickup Authorized',
        'Medication',
        'Half Day',
        'Girl',
      ],
      'Kimberly': ['Allergy', 'Pickup Authorized', 'Girl'],
      'Nichole': ['5 Days', 'Full Day', 'Photo Permission'],
    },
    '2-Red A': {
      'Sree': ['5 Days', 'Full Day', 'Photo Permission'],
      'Aria': ['5 Days', 'Full Day', 'Photo Permission'],
      'Kabir': ['5 Days', 'Half Day', 'Photo Permission'],
      'Sara': ['5 Days', 'Full Day', 'Photo Permission'],
      'Raghav': ['5 Days', 'Half Day', 'Photo Permission'],
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
  Set<String> _selectedStudents = <String>{};

  List<MapEntry<String, List<String>>> get _filteredStudents {
    final query = _searchController.text.trim().toLowerCase();

    // If there is NO search query → show nothing unless classroom is selected
    if (query.isEmpty) {
      if (_selectedClassroom == null) {
        return []; // No search + no classroom → show nothing
      }

      // Classroom selected + no search → show all from that classroom
      final classroomStudents = _studentsInSelectedClassroom[_selectedClassroom];
      if (classroomStudents == null) return [];

      Map<String, List<String>> filtered = Map.from(classroomStudents);

      // Apply tags if any
      if (_selectedTags.isNotEmpty) {
        filtered.removeWhere((name, tags) =>
        !_selectedTags.every((tag) => tags.contains(tag)));
      }

      return filtered.entries.toList();
    }

    // There IS a search query → search across ALL classrooms
    Map<String, List<String>> allStudents = {};
    _studentsInSelectedClassroom.forEach((classroom, students) {
      allStudents.addAll(students);
    });

    // Filter by search query
    allStudents.removeWhere(
            (name, tags) => !name.toLowerCase().contains(query));

    // If classroom is selected, restrict search results to that classroom
    if (_selectedClassroom != null) {
      allStudents.removeWhere((name, _) =>
      !_studentsInSelectedClassroom[_selectedClassroom]!.containsKey(name));
    }

    // // If classroom is selected, further restrict to that classroom
    // if (_selectedClassroom != null) {
    //   allStudents.removeWhere((name, tags) =>
    //       _studentsInSelectedClassroom[_selectedClassroom]!.containsKey(name));
    // }

    // Apply tags only if classroom is selected (optional – you can remove this if you want global tag filter)
    if (_selectedClassroom != null && _selectedTags.isNotEmpty) {
      allStudents.removeWhere((name, tags) =>
      !_selectedTags.every((tag) => tags.contains(tag)));
    }

    return allStudents.entries.toList();
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
          .every((entry) => _selectedStudents.contains(entry.key));
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
    //_applyFilters();
    _searchController.addListener(_applyFilters);
  }

  void _applyFilters(){
    setState(() {});
  }

  @override
  void dispose() {
    //_searchController.removeListener(_applyFilters);
    //_searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(hasBackButton: true),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.buildScaffoldGradient(),
              ),
              child: Image.asset(
                MediaRes.wowcareMobileBg,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalSpacing,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add Activity',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: responsive.titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff573353),
                    ),
                  ),
                ),
              ),
              SizedBox(height: responsive.isTablet ? 32.0 : 20.0),
              Expanded(
                child: Container(
                  width: responsive.containerWidth,
                  margin: EdgeInsets.symmetric(
                    horizontal: responsive.horizontalSpacing,
                  ),
                  padding: EdgeInsets.all(responsive.isTablet ? 32.0 : 16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(responsive.isTablet ? 30.0 : 20.0),
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
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'Select Students',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff573353),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: CustomSearchBar(
                              controller: _searchController,
                              hintText: 'Search Students',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
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
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                      // Select All
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CustomCheckbox(
                          label: 'Select All',
                          value: _selectAll,
                          borderColor: AppColors.themeColor,
                          onChanged: (v) {
                            final newVal = v ?? false;
                            setState(() {
                              _selectAll = newVal;
                              if(newVal){
                                _selectedStudents.addAll(_filteredStudents.map((e) => e.key));
                              } else {
                                _selectedStudents.removeAll(_filteredStudents.map((e) => e.key));
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12,),
                      Expanded(
                        child: _filteredStudents.isEmpty
                            ? Center(
                          child: Text(
                            _selectedClassroom == null 
                                ? 'Select a classroom to view students or use the search bar'
                                : 'No students match the selected filters',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                             :
                            GridView.builder(
                                padding: EdgeInsets.all(10),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: responsive.isTablet ? 3 : 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: responsive.isTablet ? 3.8 : 4.2
                                ),
                                itemCount: _filteredStudents.length,
                                itemBuilder: (context, index) {
                                  final student = _filteredStudents[index];
                                  final String name = student.key;
                                  final bool isSelected = _selectedStudents.contains(name);

                                  return StudentTile(
                                      name: name,
                                      isSelected: isSelected,
                                      onSelected: (bool? selected){
                                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                        setState(() {
                                          if(selected == true){
                                            _selectedStudents.add(name);
                                          } else {
                                            _selectedStudents.remove(name);
                                          }
                                          _updateSelectAllState();
                                        });
                                      },
                                  );
                                }
                            )
                        //     ListView.builder(
                        //   padding: EdgeInsets.all(10),
                        //   itemCount: _filteredStudents.length,
                        //   itemBuilder: (context, index) {
                        //     final student = _filteredStudents[index];
                        //     final String name = student.key;
                        //     final bool isSelected =
                        //     _selectedStudents.contains(name);
                        //
                        //     return Padding(
                        //       padding:
                        //       const EdgeInsets.only(bottom: 8.0),
                        //       child: StudentTile(
                        //         name: name,
                        //         isSelected: isSelected,
                        //         onSelected: (bool? selected) {
                        //           setState(() {
                        //             if (selected == true) {
                        //               _selectedStudents.add(name);
                        //             } else {
                        //               _selectedStudents.remove(name);
                        //             }
                        //             _updateSelectAllState();
                        //           });
                        //         },
                        //       ),
                        //     );
                        //   },
                        // ),
                      ),
                      // Expanded(  // Use Expanded instead of Flexible for the list area
                      //   child: ListView(
                      //     padding: EdgeInsets.zero,
                      //     children: [
                      //       StudentTile(name: 'Lex'),  // Example – replace with your actual list later
                      //       StudentTile(name: 'Ajay'),
                      //       StudentTile(name: 'Brinder'),
                      //       // ... more tiles
                      //       const SizedBox(height: 20), // optional bottom padding
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, responsive),
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

  Widget _buildBottomBar(BuildContext context, ResponsiveHelper responsive) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    return Container(
      padding: EdgeInsets.only(
        bottom: safeAreaBottom,
        left: 16,
        right: 16,
        top: 16,
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
          topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
          topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Container(
              height: responsive.buttonHeight,
              decoration: BoxDecoration(
                gradient: AppColors.buildPrimaryGradient(),
                borderRadius: BorderRadius.circular(
                  responsive.isTablet ? 16.0 : 8.0,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(1),
                child: Container(
                  //alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      responsive.isTablet ? 16.0 : 8.0,
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      overlayColor: Colors.transparent,
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return AppColors.buildPrimaryGradient().createShader(
                          bounds,
                        );
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: responsive.buttonFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: responsive.buttonHeight,
              decoration: BoxDecoration(
                gradient: AppColors.buildPrimaryGradient(),
                borderRadius: BorderRadius.circular(
                  responsive.isTablet ? 16.0 : 8.0,
                ),
              ),
              child: TextButton(
                onPressed: (){
                  if(_selectedStudents.isNotEmpty){
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChooseActivity(selectedStudents: _selectedStudents.toList(),)));
                  } else {
                    _showWarningMessage('Select at least one student.');
                  }
                  
                },
                style: TextButton.styleFrom(overlayColor: Colors.transparent),
                child: Text(
                  'Next',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: responsive.buttonFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
