import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen.dart';
import 'package:wowcare/presentation/features/students/widgets/student_action_panel.dart';
import 'package:wowcare/shared/common/views/filter_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_stat_bar_card.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import '../../../../shared/common/widgets/gradient_add_button.dart';
import '../../../../shared/common/widgets/post_add_student_bottom_sheet.dart';
import '../widgets/student_card.dart';
import 'add_student_wizard_screen.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  static const String routeName = '/students';

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showInactive = false;
  List<bool> _selectedDemo = [false, false, false];
  bool _selectAll = false;
  StudentPanelType _currentPanel = StudentPanelType.none;
  Map<String, List<String>> _currentFilters = {'Status': ['Active']};
  List<Map<String, dynamic>> _demoStudentData =  [
    {
      'name': 'Kabir Mehta',
      'Classroom': '1-Blue D',
      'Tags': ['5 Days', 'Full Day', 'Allergies', 'Medication'],
      'schedule': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      'birthDate': '12 Jan 2022',
      'movementDate': '05 Sep 2024',
      'Status': 'Active',
      'Attendance': 'Present',
      'Parents': ['Father Mehta', 'Mother Mehta'],
      'sibling': {'name': ['Anya Mehta'], 'relation': ['sister'], 'status': ['upcoming']}
    },
    {
      'name': 'Sara Khan',
      'Classroom': '3-Orange-D',
      'Tags': ['3 Days', 'Full Day', 'Allergies'],
      'schedule': ['Mon', 'Tue', 'Wed', 'Thu'],
      'birthDate': '12 Jan 2022',
      'movementDate': '05 Sep 2024',
      'Status': 'Inactive',
      'Attendance': 'Absent',
      'Parents': ['Father Khan', 'Mother Khan'],
      'sibling': {'name': [], 'relation': [], 'status': []}
    },
    {
      'name': 'Rohan Gupta',
      'Classroom': '2-Red A',
      'Tags': [ 'Half Day', 'Medication'],
      'schedule': ['Mon', 'Wed', 'Thu', 'Fri'],
      'birthDate': '12 Jan 2022',
      'movementDate': '05 Sep 2024',
      'Status': 'Upcoming',
      'Attendance': 'Expected',
      'Parents': ['Father Gupta', 'Mother Gupta'],
      'sibling': {'name': ['Raghave Gupta', 'Ruhi Gupta'], 'relation': ['brother', 'sister'], 'status': ['signedIn', 'isAbsent']}
    },
  ];

  late List<Map<String, dynamic>> _filteredStudents;

  @override
  void initState(){
    super.initState();
    _applyFilters();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters(){
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredStudents = _demoStudentData.where((student) {
        final name = (student['name'] as String).toLowerCase();
        if(query.isNotEmpty && !name.contains(query)){
          return false;
        }

        bool matches = true; // will stay true if for a student all filters applied are true

        _currentFilters.forEach((filterKey, selectedValues) {
          if (selectedValues.isEmpty) return;
          switch (filterKey) {
            case 'Classroom':
              if (!selectedValues.contains(student['Classroom'])) matches = false;
              break;
            case 'Status' :
              if (!selectedValues.contains(student['Status'])) matches = false;
              break;
            case 'Attendance':
              if (!selectedValues.contains(student['Attendance'])) matches = false;
              break;
            case 'Tags':
              final studentTags = student['Tags'] as List<String>;
              if (!selectedValues.any((tag) => studentTags.contains(tag))) matches = false;
              break;
            case 'Parents':
              final studentParents = student['Parents'] as List<String>;
              if(!selectedValues.any((parent) => studentParents.contains(parent))) matches = false;
              break;
          }
        });
        return matches;
      }).toList();
      _selectedDemo = List.filled(_filteredStudents.length, false);
      _selectAll = false;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _currentFilters.clear();
      _currentFilters['Status'] = ['Active']; // active filter is always on by default
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final double titleFontSize = ResponsiveSizing.titleFontSize(context);
    final double titleLineHeight = ResponsiveSizing.titleLineHeight(context);

    final bool anySelected = _selectedDemo.any((e) => e);
    final int selectedCount = _selectedDemo.where((e) => e).length;

    return GlobalScaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: ResponsiveSizing.contentPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Students',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff573353),
                            height: titleLineHeight,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      GradientAddButton(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddStudentWizardScreen()),
                          );
                          if (!mounted) return;
                          print('[StudentScreen] Received result from AddStudentWizardScreen: ' + result.toString());
                          if (result is Map && (result['showPostAddPrompt'] == true)) {
                            final studentName = (result['studentName'] as String?) ?? '';
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    topRight: Radius.circular(24),
                                  ),
                                ),
                                builder: (ctx) => PostAddStudentBottomSheet(
                                  studentName: studentName,
                                  onLater: () => Navigator.of(ctx).pop(),
                                  onYes: () {
                                    Navigator.of(ctx).pop();
                                    //Navigator.of(context).pushNamed('/edit-profile-details-screen');
                                  },
                                ),
                              );
                            });
                          }
                        },
                        isTablet: MediaQuery.of(context).size.width >= 600,
                        isLargeTablet: MediaQuery.of(context).size.width >= 900,
                      ),
                      SizedBox(width: 10,),
                      // Clock action button
                      // Container(
                      //   width: 38,
                      //   height: 38,
                      //   margin: const EdgeInsets.only(right: 8),
                      //   decoration: BoxDecoration(
                      //     gradient: AppColors.buildPrimaryGradient(),
                      //     borderRadius: BorderRadius.circular(8),
                      //   ),
                      //   alignment: Alignment.center,
                      //   child: GestureDetector(
                      //     onTap: () {},
                      //     child: SvgPicture.asset(
                      //       MediaRes.calenderClockIcon,
                      //       width: 22,
                      //       height: 22,
                      //       fit: BoxFit.contain,
                      //       colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Total Students stat card
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isTablet = constraints.maxWidth >= 600;
                      final double active = 120.0; // demo
                      final double upcoming = 8.0; // demo
                      final int totalCount = (active + upcoming).toInt();
                      final String total = '$totalCount';
                      final items = [
                        ProgressItemHelper(
                          label: 'Active (${active.toInt()})',
                          value: active,
                          color: AppColors.lightBlueProgressBar,
                          filterValue: 'Active'
                        ),
                        ProgressItemHelper(
                          label: 'Upcoming (${upcoming.toInt()})',
                          value: upcoming,
                          color: AppColors.mustardProgressBar,
                          filterValue: 'Upcoming'
                        ),
                      ];
                      return Container(
                        margin: EdgeInsets.only(top: isTablet ? 16 : 12, bottom: isTablet ? 8 : 8),
                        child: CustomStatBarCard(
                          title: 'Total\nStudents',
                          number: total,
                          items: items,
                          fullWidthBar: false,
                          selectedFilterValue: (_currentFilters['Status']?.length == 1) ? _currentFilters['Status']!.first : null,
                          onLegendTap: (String label, String? filterValue){
                            setState(() {
                              final current = _currentFilters['Status'];
                              if (current != null && current.length == 1 && current.first == filterValue){
                                _currentFilters.remove('Status');
                              } else {
                                _currentFilters['Status'] = [filterValue!];
                              }
                            });
                            _applyFilters();
                          },

                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Attendance stat card (Present/Absent)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isTablet = constraints.maxWidth >= 600;
                      final double present = 98.0; // demo
                      final double absent = 22.0; // demo
                      final int expectedTotal = (present + absent).toInt();
                      final String total = '$expectedTotal';
                      final items = [
                        ProgressItemHelper(
                          label: 'Present (${present.toInt()})',
                          value: present,
                          color: AppColors.lightGreenProgressBar,
                          filterValue: 'Present'
                        ),
                        ProgressItemHelper(
                          label: 'Absent (${absent.toInt()})',
                          value: absent,
                          color: AppColors.redProgressBar,
                          filterValue: 'Absent'
                        ),
                      ];
                      return Container(
                        margin: EdgeInsets.only(top: isTablet ? 8 : 8, bottom: isTablet ? 8 : 8),
                        child: CustomStatBarCard(
                          title: 'Expected\nAttendance',
                          number: total,
                          selectedFilterValue: (_currentFilters['Attendance']?.length == 1) ? _currentFilters['Attendance']!.first : null,
                          items: items,
                          fullWidthBar: false,
                          onLegendTap: (String label, String? filterValue){
                            setState(() {
                              setState(() {
                                final current = _currentFilters['Attendance'];
                                if (current != null && current.length == 1 && current.first == filterValue) {
                                  _currentFilters.remove('Attendance');
                                } else {
                                  _currentFilters['Attendance'] = [filterValue!];
                                }
                              });
                              _applyFilters();
                            });
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Filter/search card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.cardBorderColor),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.cardColor,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CustomSearchBar(
                                controller: _searchController,
                                hintText: 'Search student by student/parent name',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FilterScreen(
                                          sections: [
                                            FilerSection(
                                                label: 'Classroom',
                                                hintText: 'Select classroom',
                                                items: ['1-Blue D', '3-Orange-D', '2-Red A'],
                                                initialSelected: _currentFilters['Classroom'] ?? [],
                                                isMultiSelectDropDown: false
                                            ),
                                            FilerSection(
                                                label: 'Status',
                                                hintText: 'Select status',
                                                items: ['Active', 'Inactive', 'Upcoming'],
                                                initialSelected: _currentFilters['Status'] ?? [],
                                                isMultiSelectDropDown: false,
                                            ),
                                            FilerSection(
                                                label: 'Tags',
                                                hintText: 'Select tags',
                                                items:  [
                                                  '5 Days',
                                                  'Full Day',
                                                  'Photo Permission',
                                                  'Vegetarian',
                                                  'First Aid',
                                                  'Allergy',
                                                  'Pickup Authorized',
                                                ],
                                                isMultiSelectDropDown: false,
                                                initialSelected: _currentFilters['Tags'] ?? []
                                            ),
                                            FilerSection(
                                                label: 'Parents',
                                                hintText: 'Select parents',
                                                items:  ['Father Mehta', 'Mother Mehta', 'Father Khan', 'Mother Khan', 'Father Gupta', 'Mother Gupta'],
                                                isMultiSelectDropDown: false,
                                                initialSelected: _currentFilters['Parent'] ?? []
                                            ),
                                            FilerSection(
                                                label: 'Attendance',
                                                items:  ['Expected', 'Present', 'Absent'],
                                                isMultiSelectDropDown: false,
                                                initialSelected: _currentFilters['Attendance'] ?? []
                                            ),
                                          ],
                                          onApply: (filters) {
                                            setState(() {
                                              _currentFilters = filters;
                                            });
                                            _applyFilters();
                                          }
                                      ),
                                    ),
                                  );
                                  if (!mounted) return;
                                  if (result is Map) {
                                    // TODO: apply filters to list
                                    setState(() {});
                                  }
                                },
                                borderRadius: BorderRadius.circular(100),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: SvgPicture.asset(MediaRes.filterIcon, height: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // const CustomChip(
                                //   label: 'Active',
                                //   labelStyle: TextStyle(
                                //     color: AppColors.secondaryColor,
                                //     fontSize: 13,
                                //     fontWeight: FontWeight.w500,
                                //   ),
                                //   color: Color.fromRGBO(177, 175, 233, 0.3),
                                // ),
                                const CustomClearAllChip(onTap: null, label: 'Active'),// should be turned on by default and show active students
                                const SizedBox(width: 8),
                                CustomClearAllChip(onTap: _clearAllFilters),
                              ],
                            ),
                            // CustomToggle(
                            //   label: '',
                            //   isToggled: _showInactive,
                            //   onToggle: (v) => setState(() => _showInactive = v),
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Select All
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CustomCheckbox(
                      label: 'Select All',
                      value: _selectAll,
                      onChanged: (v) {
                        final newVal = v ?? false;
                        setState(() {
                          _selectAll = newVal;
                          _selectedDemo = List.filled(_filteredStudents.length, newVal);
                          // for (int i = 0; i < _selectedDemo.length; i++) {
                          //   _selectedDemo[i] = newVal;
                          // }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Demo student list - filtered according to selected filters
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final demo = _filteredStudents[index];

                      return Column(
                        children: [
                          StudentCard(
                            name: demo['name'] as String,
                            classroom: demo['Classroom'] as String,
                            tags: (demo['Tags'] as List<String>),
                            sibling: demo['sibling'] as Map<String, dynamic>,
                            schedule: (demo['schedule'] as List<String>),
                            birthDate: (demo['birthDate'] as String),
                            movementDate: (demo['movementDate'] as String),
                            status: (demo['Status'] as String),
                            isSelected: index < _selectedDemo.length ? _selectedDemo[index]: false,
                            onSelected: (v) => setState(() {
                              if (index < _selectedDemo.length){
                                _selectedDemo[index] = v ?? false;
                              }
                              if (!_selectedDemo.any((e) => e)) {
                                _currentPanel = StudentPanelType.none;
                              }
                              _selectAll = _selectedDemo.every((e) => (e));

                            }),
                            onEdit: () {},
                            onDeactivate: () {},
                          ),
                          if (index != _filteredStudents.length -1) const SizedBox(height: 10),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (anySelected)
            Positioned(
                right: 16,
              bottom: 16,
              child: StudentActionPanel(
                  currentPanel: _currentPanel,
                onAttendanceTap: (){},
                onActivitiesTap: (){},
                onMessageTap: (){},
                onProfileTap: selectedCount == 1 ? (){
                    final idx = _selectedDemo.indexWhere((e) => e);
                    if(idx != -1){
                      final demo = _demoStudentData[idx];
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => StudentProfileScreen(
                                  name: demo['name'] as String? ?? "Unknown Student",
                                  sibling: demo['sibling'] as Map<String, dynamic>,
                                  schedule : (demo['schedule'] as List<dynamic>?)
                                      ?.map((e) => e.toString())
                                      .toList() ??
                                      ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
                                  classroom: demo['classroom'] as String? ?? "Unknown Class",
                                  tags: (demo['tags'] as List<dynamic>?)
                                      ?.map((e) => e.toString())
                                      .toList() ??
                                      ['5 days', 'Full day', 'Allergies', 'Medication'],
                              )
                          )
                      );
                    }

                }: null,
                onClearSelections: (){
                    setState(() {
                      for (int i = 0; i < _selectedDemo.length; i++){
                        _selectedDemo[i] = false;
                      }
                      _selectAll = false;
                      _currentPanel = StudentPanelType.none;
                    });
                },
                isProfileEnabled: selectedCount == 1,
                activitiesEnabled: selectedCount > 0,
              ),
            )

        ],
      ),
      showCustomNavigationBar: true,
    );
  }
}