
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen.dart';
import 'package:wowcare/presentation/features/students/widgets/student_action_panel.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_stat_bar_card.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';

import '../widgets/student_card.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  static const String routeName = '/students';

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showInactive = false;
  final List<bool> _selectedDemo = [false, false, false];
  bool _selectAll = false;
  StudentPanelType _currentPanel = StudentPanelType.none;
  List<Map<String, dynamic>> _demoStudentData =  [
    {
      'name': 'Kabir Mehta',
      'classroom': 'Nursery A',
      'tags': ['5 days', 'Full day', 'Allergies', 'Medication'],
      'schedule': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      'birthDate': '12 Jan 2022',
      'movementDate': '05 Sep 2024',
      'status': 'signedIn'
    },
    {
      'name': 'Sara Khan',
      'classroom': 'Nursery B',
      'tags': ['3 days', 'Full day', 'Allergies'],
      'schedule': ['Mon', 'Tue', 'Wed', 'Thu'],
      'birthDate': '12 Jan 2022',
      'movementDate': '05 Sep 2024',
      'status': 'isAbsent'
    },
    {
      'name': 'Rohan Gupta',
      'classroom': 'Playgroup',
      'tags': [ 'Half day', 'Medication'],
      'schedule': ['Mon', 'Wed', 'Thu', 'Fri'],
      'birthDate': '12 Jan 2022',
      'movementDate': '05 Sep 2024',
      'status': 'upcoming'
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                      // Clock action button
                      Container(
                        width: 38,
                        height: 38,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          gradient: AppColors.buildPrimaryGradient(),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: () {},
                          child: SvgPicture.asset(
                            MediaRes.calenderClockIcon,
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                        ),
                      ),
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
                        ),
                        ProgressItemHelper(
                          label: 'Upcoming (${upcoming.toInt()})',
                          value: upcoming,
                          color: AppColors.mustardProgressBar,
                        ),
                      ];
                      return Container(
                        margin: EdgeInsets.only(top: isTablet ? 16 : 12, bottom: isTablet ? 8 : 8),
                        child: CustomStatBarCard(
                          title: 'Total\nStudents',
                          number: total,
                          items: items,
                          fullWidthBar: false,
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
                        ),
                        ProgressItemHelper(
                          label: 'Absent (${absent.toInt()})',
                          value: absent,
                          color: AppColors.redProgressBar,
                        ),
                      ];
                      return Container(
                        margin: EdgeInsets.only(top: isTablet ? 8 : 8, bottom: isTablet ? 8 : 8),
                        child: CustomStatBarCard(
                          title: 'Expected\nAttendance',
                          number: total,
                          items: items,
                          fullWidthBar: false,
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
                                hintText: 'Search Students',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  // TODO: Open a student filter screen when implemented
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
                                const CustomChip(
                                  label: 'Active',
                                  labelStyle: TextStyle(
                                    color: AppColors.secondaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  color: Color.fromRGBO(177, 175, 233, 0.3),
                                ),
                                const SizedBox(width: 8),
                                const CustomClearAllChip(onTap: null),
                              ],
                            ),
                            CustomToggle(
                              label: '',
                              isToggled: _showInactive,
                              onToggle: (v) => setState(() => _showInactive = v),
                            ),
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
                          for (int i = 0; i < _selectedDemo.length; i++) {
                            _selectedDemo[i] = newVal;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Demo student list
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      final demo = _demoStudentData[index];
                      return Column(
                        children: [
                          StudentCard(
                            name: demo['name'] as String,
                            classroom: demo['classroom'] as String,
                            tags: (demo['tags'] as List<String>),
                            schedule: (demo['schedule'] as List<String>),
                            birthDate: (demo['birthDate'] as String),
                            movementDate: (demo['movementDate'] as String),
                            status: (demo['status'] as String),
                            isSelected: _selectedDemo[index],
                            onSelected: (v) => setState(() {
                              _selectedDemo[index] = v ?? false;
                              if (!_selectedDemo.any((e) => e)) {
                                _currentPanel = StudentPanelType.none;
                              }

                            }),
                            onEdit: () {},
                            onDeactivate: () {},
                          ),
                          if (index != 2) const SizedBox(height: 10),
                        ],
                      );
                      // return Container(
                      //   margin: EdgeInsets.only(bottom: index != 2 ? 8 : 0),
                      //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      //   decoration: BoxDecoration(
                      //     color: AppColors.cardColor,
                      //     border: Border.all(color: AppColors.cardBorderColor),
                      //     borderRadius: BorderRadius.circular(12),
                      //   ),
                      //   child: Row(
                      //     children: [
                      //       CustomCheckbox(
                      //         label: '',
                      //         value: _selectedDemo[index],
                      //         onChanged: (v) => setState(() {
                      //           _selectedDemo[index] = v ?? false;
                      //           if (!_selectedDemo.any((e) => e)) {
                      //             // nothing extra for now
                      //           }
                      //         }),
                      //       ),
                      //       const SizedBox(width: 8),
                      //       Expanded(
                      //         child: Column(
                      //           crossAxisAlignment: CrossAxisAlignment.start,
                      //           children: [
                      //             Text(
                      //               demo['name'] as String,
                      //               style: const TextStyle(
                      //                 fontFamily: 'Manrope',
                      //                 fontSize: 16,
                      //                 fontWeight: FontWeight.w600,
                      //                 color: Color(0xff573353),
                      //               ),
                      //             ),
                      //             const SizedBox(height: 4),
                      //             Text(
                      //               demo['classroom'] as String,
                      //               style: const TextStyle(
                      //                 fontFamily: 'Manrope',
                      //                 fontSize: 13,
                      //                 fontWeight: FontWeight.w400,
                      //                 color: Color(0xff7A6B78),
                      //               ),
                      //             ),
                      //           ],
                      //         ),
                      //       ),
                      //       const SizedBox(width: 8),
                      //       const Icon(
                      //         Icons.keyboard_arrow_right,
                      //         size: 18,
                      //         color: Color(0xff7A6B78),
                      //       ),
                      //     ],
                      //   ),
                      // );
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
                                  name: demo['name'] as String,
                                  classroom: demo['classroom'] as String
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