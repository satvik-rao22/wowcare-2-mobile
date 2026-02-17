import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen.dart';
import 'package:wowcare/presentation/features/students/widgets/student_action_panel.dart';
import 'package:wowcare/presentation/features/student/cubit/student_cubit.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/shared/common/views/filter_screen.dart';
import 'package:wowcare/shared/common/widgets/activity_status_panel.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_stat_bar_card.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
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
  final ScrollController _scrollController = ScrollController();
  bool _showActivitiesPanel = false;
  List<bool> _selectedDemo = [];
  bool _selectAll = false;
  StudentPanelType _currentPanel = StudentPanelType.none;
  Map<String, List<String>> _currentFilters = {'Status': ['Active']};

  @override
  void initState(){
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Load students from API via cubit after first frame to ensure BlocProvider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final cubit = context.read<StudentCubit>();
        cubit.loadInitial();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    context.read<StudentCubit>().updateSearch(query);
    // Refresh to apply search filter
    context.read<StudentCubit>().refresh();
  }

  void _applyFiltersToCubit() {
    final statusFilter = _currentFilters['Status']?.isNotEmpty == true 
        ? _currentFilters['Status']!.first 
        : null;
    
    context.read<StudentCubit>().updateFilters(
      status: statusFilter,
    );
    context.read<StudentCubit>().refresh();
  }

  // Convert Student entity to map format for compatibility with existing UI
  Map<String, dynamic> _studentToMap(Student student) {
    return {
      'name': student.fullName,
      'Classroom': student.classroom,
      'Tags': <String>[], // API doesn't provide tags yet
      'schedule': <String>[], // API doesn't provide schedule yet
      'birthDate': student.dob,
      'movementDate': student.movementDate,
      'Status': student.status,
      'Attendance': 'Expected', // API doesn't provide attendance yet
      'Parents': <String>[], // API doesn't provide parents yet
      'sibling': {'name': [], 'relation': [], 'status': []}, // API doesn't provide siblings yet
      'activities': <String>[], // API doesn't provide activities yet
      'code': student.code,
    };
  }

  void _clearAllFilters() {
    setState(() {
      _currentFilters.clear();
      _currentFilters['Status'] = ['Active']; // active filter is always on by default
    });
    _applyFiltersToCubit();
  }

  bool _canShowActivitiesButton(selectedCount, List<Student> students) {
    if (selectedCount == 0) return false;

    final selectedIndices = <int>[];
    for (int i = 0; i < _selectedDemo.length; i++) {
      if (_selectedDemo[i] && i < students.length) selectedIndices.add(i);
    }

    if (selectedIndices.isEmpty) return false;

    // Note: Attendance check removed since API doesn't provide it yet
    // If more than one selected → must be in same classroom
    if (selectedCount > 1) {
      final firstClassroom = students[selectedIndices.first].classroom;
      return selectedIndices.every((i) => students[i].classroom == firstClassroom);
    }

    return true; // Single student → allowed
  }

  bool _shouldShowActivityPanel(selectedCount, List<Student> students) {
    return _showActivitiesPanel && _canShowActivitiesButton(selectedCount, students);
  }

  List<String> _getCombinedOngoingActivities(selectedCount, List<Student> students) {
    if (!_canShowActivitiesButton(selectedCount, students)) return [];

    // API doesn't provide activities yet, return empty list
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final double titleFontSize = ResponsiveSizing.titleFontSize(context);
    final double titleLineHeight = ResponsiveSizing.titleLineHeight(context);

    return BlocBuilder<StudentCubit, StudentState>(
      builder: (context, state) {
        final studentCubit = context.read<StudentCubit>();
        final students = state.items;
        final bool anySelected = _selectedDemo.any((e) => e);
        final int selectedCount = _selectedDemo.where((e) => e).length;

        // Update selection list when students list changes
        if (_selectedDemo.length != students.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedDemo = List.filled(students.length, false);
              _selectAll = false;
            });
          });
        }

        final actionPanel = anySelected
            ? Positioned(
                right: 16,
                bottom: 16,
                child: Row(
                  children: [
                    if(_shouldShowActivityPanel(selectedCount, students))
                      ActivityStatusPanel(
                        onGoingActivities: _getCombinedOngoingActivities(selectedCount, students),
                        isSignedIN: true,
                      ),
                    const SizedBox(width: 10,),
                    StudentActionPanel(
                      currentPanel: _currentPanel,
                      onAttendanceTap: (){},
                      onActivitiesTap: _canShowActivitiesButton(selectedCount, students) ? () {
                        setState(() {
                          _showActivitiesPanel = !_showActivitiesPanel;
                          _currentPanel = _showActivitiesPanel ? StudentPanelType.activities : StudentPanelType.none;
                        });
                      } : null,
                      onMessageTap: (){},
                      onProfileTap: selectedCount == 1 ? (){
                        final idx = _selectedDemo.indexWhere((e) => e);
                        if(idx != -1 && idx < students.length){
                          final student = students[idx];
                          final studentMap = _studentToMap(student);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentProfileScreen(
                                name: studentMap['name'] as String? ?? "Unknown Student",
                                sibling: studentMap['sibling'] as Map<String, dynamic>,
                                schedule : (studentMap['schedule'] as List<dynamic>?)
                                    ?.map((e) => e.toString())
                                    .toList() ??
                                    ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
                                classroom: studentMap['Classroom'] as String? ?? "Unknown Class",
                                tags: (studentMap['Tags'] as List<dynamic>?)
                                    ?.map((e) => e.toString())
                                    .toList() ??
                                    [],
                                studentCode: studentMap['code'] as String?,
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
                          _showActivitiesPanel = false;
                          _currentPanel = StudentPanelType.none;
                        });
                      },
                      isProfileEnabled: selectedCount == 1,
                      activitiesEnabled: _canShowActivitiesButton(selectedCount, students),
                    ),
                  ],
                ),
              )
            : null;

        final stackChildren = <Widget>[
          CustomRefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                studentCubit.refresh(),
                context
                    .read<ClassroomCubit>()
                    .loadActiveClassrooms(force: true),
              ]);
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 200) {
                  studentCubit.loadNextPage();
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
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
                            // New student added successfully → refresh list (uses invalidated cache)
                            await studentCubit.refresh();
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
                            _applyFiltersToCubit();
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
                              final current = _currentFilters['Attendance'];
                              if (current != null && current.length == 1 && current.first == filterValue) {
                                _currentFilters.remove('Attendance');
                              } else {
                                _currentFilters['Attendance'] = [filterValue!];
                              }
                            });
                            // Note: Attendance filter not yet supported by API
                            // _applyFiltersToCubit();
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
                                            _applyFiltersToCubit();
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
                          _selectedDemo = List.filled(students.length, newVal);
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Student list from API
                  if (state.isLoading && students.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: PrimaryCircularLoader()),
                    )
                  else if (state.errorMessage != null && students.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              'Error loading students',
                              style: TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => context.read<StudentCubit>().refresh(),
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (students.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('No students found')),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final studentMap = _studentToMap(student);
                        final isActive =
                            (student.status).toUpperCase() == 'ACTIVE';

                        return Column(
                          children: [
                            StudentCard(
                              name: studentMap['name'] as String,
                              classroom: studentMap['Classroom'] as String,
                              tags: studentMap['Tags'] as List<String>,
                              sibling:
                                  studentMap['sibling'] as Map<String, dynamic>,
                              schedule: studentMap['schedule'] as List<String>,
                              birthDate: studentMap['birthDate'] as String,
                              movementDate:
                                  studentMap['movementDate'] as String,
                              status: studentMap['Status'] as String,
                              isSelected: index < _selectedDemo.length
                                  ? _selectedDemo[index]
                                  : false,
                              onSelected: (v) => setState(() {
                                if (index < _selectedDemo.length) {
                                  _selectedDemo[index] = v ?? false;
                                }
                                if (!_selectedDemo.any((e) => e)) {
                                  _currentPanel = StudentPanelType.none;
                                  _showActivitiesPanel = false;
                                }
                                _selectAll = _selectedDemo.every((e) => e);
                              }),
                              onEdit: () {},
                              onDeactivate: () async {
                                try {
                                  final message = isActive
                                      ? await studentCubit
                                          .deactivateStudent(student.code)
                                      : await studentCubit
                                          .reactivateStudent(student.code);
                                  if (!mounted) return;
                                  CoreUtils.showTopSnackBar(
                                    context: context,
                                    message: message,
                                    isSuccess: true,
                                  );
                                  Navigator.of(context).maybePop();
                                } catch (e) {
                                  if (!mounted) return;
                                  final msg =
                                      ApiErrorHandler.extractErrorMessage(e);
                                  CoreUtils.showTopSnackBar(
                                    context: context,
                                    message: msg,
                                    isError: true,
                                  );
                                }
                              },
                            ),
                            if (index != students.length - 1)
                              const SizedBox(height: 10),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ];
        
        if (actionPanel != null) {
          stackChildren.add(actionPanel);
        }

        return GlobalScaffold(
          body: Stack(
            children: stackChildren,
          ),
          showCustomNavigationBar: true,
        );
      },
    );
  }
}