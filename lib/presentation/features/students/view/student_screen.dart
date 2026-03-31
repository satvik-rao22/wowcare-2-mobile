import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/student/datasources/student_remote_datasource.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/domain/features/student/usecases/get_guardian_name_code_map_for_school_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_counts_usecase.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/student/cubit/student_cubit.dart';
import 'package:wowcare/presentation/features/students/view/student_filter_screen.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen.dart';
import 'package:wowcare/presentation/features/students/view/edit_student_profile_details_screen.dart';
import 'package:wowcare/presentation/features/students/widgets/student_action_panel.dart';
import 'package:wowcare/shared/common/widgets/activity_status_panel.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_stat_bar_card.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
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
  bool _showInactive = false;
  List<bool> _selectedDemo = [];
  bool _selectAll = false;
  StudentPanelType _currentPanel = StudentPanelType.none;
  Map<String, List<String>> _currentFilters = {'Status': ['Active']};
  Map<String, String> _tagNameToCode = <String, String>{};
  Map<String, String> _guardianNameToCode = <String, String>{};
  int _activeCount = 0;
  int _upcomingCount = 0;

  @override
  void initState(){
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Load students from API via cubit after first frame to ensure BlocProvider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final cubit = context.read<StudentCubit>();
        cubit.loadInitial();
        // NOTE: Do not call tags API for now (as requested).
        _loadGuardianNameCodeMap();
        _loadStudentCounts();
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
    // Trigger search API on each keystroke without dropping rapid updates.
    context.read<StudentCubit>().refresh(ignoreRefreshingGuard: true);
  }

  Future<void> _loadGuardianNameCodeMap() async {
    try {
      final storageService = serviceLocator<StorageService>();
      final schoolCode =
          await storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) return;

      final useCase =
          serviceLocator<GetGuardianNameCodeMapForSchoolUseCase>();
      final map = await useCase(schoolCode: schoolCode);
      if (!mounted) return;

      setState(() {
        _guardianNameToCode = map;
      });
    } catch (_) {
      // Non-critical for filters; ignore errors.
    }
  }

  Future<void> _loadStudentCounts() async {
    try {
      final storageService = serviceLocator<StorageService>();
      final schoolCode =
          await storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) return;

      final useCase = serviceLocator<GetStudentCountsUseCase>();
      final counts = await useCase(schoolCode: schoolCode);
      if (!mounted) return;

      setState(() {
        _activeCount = counts['activeCount'] ?? 0;
        _upcomingCount = counts['upcomingCount'] ?? 0;
      });
    } catch (_) {
      // Non-critical for UI; keep defaults.
    }
  }

  Future<void> _refreshAllStudentApis() async {
    final studentCubit = context.read<StudentCubit>();
    await Future.wait([
      studentCubit.refreshWithCacheReset(),
      _loadGuardianNameCodeMap(),
      _loadStudentCounts(),
    ]);
  }

  Future<void> _openEditStudentDetails(String studentCode) async {
    try {
      final dataSource = serviceLocator<StudentRemoteDataSource>();
      final profile = await dataSource.getStudentProfile(studentCode);
      if (!mounted) return;

      // --- Map fields exactly like StudentAboutTabCard.onEdit ---

      // Map status from API format (ACTIVE) to display format (Active)
      String statusDisplay = 'Active';
      final upperStatus = profile.status.toUpperCase();
      if (upperStatus == 'ACTIVE' || profile.status == 'A') {
        statusDisplay = 'Active';
      } else if (upperStatus == 'INACTIVE' || profile.status == 'I') {
        statusDisplay = 'Inactive';
      } else if (upperStatus == 'UPCOMING' || profile.status == 'Upcoming') {
        statusDisplay = 'Upcoming';
      } else if (upperStatus == 'WAITLIST') {
        statusDisplay = 'Waitlist';
      } else if (upperStatus == 'GRADUATED') {
        statusDisplay = 'Graduated';
      }

      // Parse birth date
      DateTime? birthDate;
      if (profile.dob != null && profile.dob!.isNotEmpty) {
        try {
          birthDate = DateTime.parse(profile.dob!);
        } catch (_) {
          birthDate = null;
        }
      }

      // Extract address fields
      final address = profile.address;
      final street = address?['street']?.toString() ?? '';
      final city = address?['city']?.toString() ?? '';
      final state = address?['state']?.toString() ?? '';
      final country = address?['country']?.toString() ?? '';
      final zipCode =
          address?['zipCode']?.toString() ?? address?['postalCode']?.toString() ?? '';

      // Extract tags as display names from profile.tags[]
      final tags = <String>[];
      for (final raw in profile.tags) {
        if (raw is Map<String, dynamic>) {
          final name = (raw['name'] ?? '').toString().trim();
          if (name.isNotEmpty) tags.add(name);
        }
      }

      // Extract siblings as codes for edit screen (API returns list of objects).
      final siblings = <String>[];
      if (profile.siblings.isNotEmpty) {
        for (final s in profile.siblings) {
          if (s is Map<String, dynamic>) {
            final code = (s['code'] ?? '').toString().trim();
            if (code.isNotEmpty) {
              siblings.add(code);
            }
          }
        }
      }

      // Extract legal custodians using same display logic as guardian names API.
      final legalCustodians = <String>[];
      if (profile.legalCustodians.isNotEmpty) {
        for (final custodian in profile.legalCustodians) {
          if (custodian is String) {
            if (custodian.trim().isNotEmpty) {
              legalCustodians.add(custodian.trim());
            }
          } else if (custodian is Map<String, dynamic>) {
            final first = (custodian['firstName'] ?? '').toString().trim();
            final last = (custodian['lastName'] ?? '').toString().trim();
            final email = (custodian['email'] ?? '').toString().trim();
            final code = (custodian['code'] ?? '').toString().trim();

            String display;
            if (first.isEmpty && last.isEmpty) {
              display = email.isNotEmpty ? email : code;
            } else {
              display = '$first $last'.trim();
            }

            if (display.isNotEmpty) {
              legalCustodians.add(display);
            }
          }
        }
      }

      ClassroomCubit? classroomCubit;
      try {
        classroomCubit = context.read<ClassroomCubit>();
      } catch (_) {
        classroomCubit = null;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            final screen = EditStudentProfileDetailsScreen(
              studentCode: profile.code,
              initialFirstName: profile.firstName,
              initialLastName: profile.lastName,
              initialStatus: statusDisplay,
              initialClassroom: profile.classroom ?? '',
              initialBirthDate: birthDate,
              initialNotes: profile.notes ?? '',
              initialFTE: profile.fte ?? '',
              initialStreet: street,
              initialCity: city,
              initialState: state,
              initialCountry: country,
              initialZipCode: zipCode,
              initialTags: tags,
              initialSiblings: siblings,
              initialLegalCustodians: legalCustodians,
              initialSubsidy: profile.subsidy,
            );

            // Preserve already-loaded classrooms when available; otherwise load fresh.
            if (classroomCubit != null) {
              return BlocProvider.value(value: classroomCubit, child: screen);
            }
            return BlocProvider(
              create: (_) =>
                  serviceLocator<ClassroomCubit>()..loadActiveClassrooms(),
              child: screen,
            );
          },
        ),
      ).then((result) async {
        // If student was edited, refresh + reset list cache.
        if (!mounted) return;
        if (result == true) {
          await _refreshAllStudentApis();
        }
      });
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    }
  }

  Future<void> _applyFiltersToCubit() async {
    final statusFilter = _currentFilters['Status']?.isNotEmpty == true
        ? _currentFilters['Status']!.first
        : null;

    // Map selected classroom names to codes for the API
    final classroomState = context.read<ClassroomCubit>().state;
    final nameToCode = {
      for (final c in classroomState.classrooms) c.name: c.code,
    };

    final selectedClassroomNames =
        _currentFilters['Classroom'] ?? const <String>[];
    final classroomCodes = selectedClassroomNames
        .map((name) => nameToCode[name])
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toList();

    final selectedTagNames =
        _currentFilters['Tags'] ?? const <String>[];
    final tagCodes = selectedTagNames
        .map((name) => _tagNameToCode[name])
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toList();

    final selectedGuardianNames =
        _currentFilters['Parents'] ?? const <String>[];
    final guardianCodes = selectedGuardianNames
        .map((name) => _guardianNameToCode[name])
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toList();

    context.read<StudentCubit>().updateFilters(
      status: statusFilter,
      classroomCodes: classroomCodes.isEmpty ? null : classroomCodes,
      tagCodes: tagCodes.isEmpty ? null : tagCodes,
      guardianCodes: guardianCodes.isEmpty ? null : guardianCodes,
    );
    await context.read<StudentCubit>().refreshWithCacheReset();
  }

  // Convert Student entity to map format for compatibility with existing UI
  Map<String, dynamic> _studentToMap(Student student) {
    return {
      'name': student.fullName,
      'Classroom': student.classroom,
      'Tags': student.tags,
      // Use schedule derived from regularSchedules if available; otherwise empty.
      'schedule': student.schedule,
      'scheduleByDay': student.scheduleByDay,
      // Keep raw DOB; card widget is responsible for display formatting
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

  Future<void> _clearAllFilters() async {
    setState(() {
      _currentFilters.clear();
      _showInactive = false;
    });
    await _applyFiltersToCubit();
  }

  String _statusChipLabel() {
    final statusList = _currentFilters['Status'];
    if (statusList != null && statusList.isNotEmpty) {
      return statusList.first;
    }
    return _showInactive ? 'Inactive' : 'Active';
  }

  void _syncShowInactiveFromStatus(String? status) {
    final upper = (status ?? '').trim().toUpperCase();
    _showInactive = upper == 'INACTIVE';
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
                              builder: (_) => BlocProvider.value(
                                value: context.read<ClassroomCubit>(),
                                child: StudentProfileScreen(
                                  name: studentMap['name'] as String? ?? "Unknown Student",
                                  sibling: studentMap['sibling'] as Map<String, dynamic>,
                                  schedule: (studentMap['schedule'] as List<dynamic>?)
                                          ?.map((e) => e.toString())
                                          .toList() ??
                                      <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                                  classroom: studentMap['Classroom'] as String? ?? "Unknown Class",
                                  tags: (studentMap['Tags'] as List<dynamic>?)
                                      ?.map((e) => e.toString())
                                      .toList() ??
                                      [],
                                  studentCode: studentMap['code'] as String?,
                                ),
                              ),
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
                // Keep these in sync on refresh as well (but DO NOT call tags API).
                _loadGuardianNameCodeMap(),
                _loadStudentCounts(),
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
                            final studentCode = (result['studentCode'] as String?) ?? '';
                            // New student added successfully → reset cache + refresh list
                            await _refreshAllStudentApis();
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
                                    if (studentCode.isNotEmpty) {
                                      _openEditStudentDetails(studentCode);
                                    }
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
                      final double active = _activeCount.toDouble();
                      final double upcoming = _upcomingCount.toDouble();
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
                          onLegendTap: (String label, String? filterValue) async {
                            setState(() {
                              final current = _currentFilters['Status'];
                              if (current != null && current.length == 1 && current.first == filterValue){
                                _currentFilters.remove('Status');
                              } else {
                                _currentFilters['Status'] = [filterValue!];
                              }
                              _syncShowInactiveFromStatus(
                                _currentFilters['Status']?.isNotEmpty == true
                                    ? _currentFilters['Status']!.first
                                    : null,
                              );
                            });
                            await _applyFiltersToCubit();
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
                                hintText: 'Search Student',
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
                                      builder: (_) => BlocProvider.value(
                                        value: context.read<ClassroomCubit>(),
                                        child: StudentFilterScreen(
                                          initialFilters: _currentFilters,
                                        ),
                                      ),
                                    ),
                                  );
                                  if (!mounted) return;
                                  if (result is Map) {
                                    final normalized = <String, List<String>>{};
                                    result.forEach((key, value) {
                                      final k = key.toString();
                                      if (value is List) {
                                        normalized[k] = value.map((e) => e.toString()).toList();
                                      } else if (value != null) {
                                        normalized[k] = [value.toString()];
                                      }
                                    });

                                    setState(() {
                                      _currentFilters = normalized;
                                    });
                                    await _applyFiltersToCubit();
                                  }
                                },
                                borderRadius: BorderRadius.circular(100),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Padding(
                                  padding: const EdgeInsets.all(8),
                                      child: SvgPicture.asset(
                                        MediaRes.filterIcon,
                                        height: 20,
                                      ),
                                    ),
                                    Builder(
                                      builder: (context) {
                                        final statusList =
                                            _currentFilters['Status'] ?? const <String>[];
                                        final classroomList =
                                            _currentFilters['Classroom'] ?? const <String>[];
                                        final tagsList =
                                            _currentFilters['Tags'] ?? const <String>[];
                                        final parentsList =
                                            _currentFilters['Parents'] ?? const <String>[];
                                        final attendanceList =
                                            _currentFilters['Attendance'] ?? const <String>[];

                                        final String status =
                                            statusList.isNotEmpty ? statusList.first : '';
                                        final statusUpper = status.trim().toUpperCase();

                                        // Treat empty or ACTIVE as default (no badge contribution).
                                        final bool hasNonDefaultStatus =
                                            statusUpper.isNotEmpty &&
                                                statusUpper != 'ACTIVE';
                                        final bool hasClassroomFilter =
                                            classroomList.isNotEmpty;
                                        final bool hasTagsFilter = tagsList.isNotEmpty;
                                        final bool hasParentsFilter =
                                            parentsList.isNotEmpty;
                                        final bool hasAttendanceFilter =
                                            attendanceList.isNotEmpty;

                                        final int badgeCount =
                                            (hasNonDefaultStatus ? 1 : 0) +
                                                (hasClassroomFilter ? 1 : 0) +
                                                (hasTagsFilter ? 1 : 0) +
                                                (hasParentsFilter ? 1 : 0) +
                                                (hasAttendanceFilter ? 1 : 0);

                                        if (badgeCount == 0) {
                                          return const SizedBox.shrink();
                                        }

                                        return Positioned(
                                          right: 2,
                                          top: 2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color.fromRGBO(179, 38, 30, 1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              badgeCount > 99 ? '99+' : '$badgeCount',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
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
                                CustomClearAllChip(
                                  onTap: null,
                                  label: _statusChipLabel(),
                                ),
                                const SizedBox(width: 8),
                                CustomClearAllChip(onTap: () => _clearAllFilters()),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Show inactive',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff573353),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CustomToggle(
                                  label: '',
                                  isToggled: _showInactive,
                                  onToggle: (v) async {
                                    setState(() {
                                      _showInactive = v;
                                      _currentFilters['Status'] =
                                          [v ? 'Inactive' : 'Active'];
                                    });
                                    await _applyFiltersToCubit();

                                    if (!mounted) return;
                                    final err = context
                                        .read<StudentCubit>()
                                        .state
                                        .errorMessage;
                                    if (err != null && err.isNotEmpty) {
                                      CoreUtils.logApiError(err);
                                    } else {
                                      CoreUtils.showTopSnackBar(
                                        context: context,
                                        message: v
                                            ? 'Showing inactive students'
                                            : 'Showing active students',
                                        isSuccess: true,
                                      );
                                    }
                                  },
                                ),
                              ],
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
                              studentCode: studentMap['code'] as String,
                              name: studentMap['name'] as String,
                              classroom: studentMap['Classroom'] as String,
                              tags: studentMap['Tags'] as List<String>,
                              sibling:
                                  studentMap['sibling'] as Map<String, dynamic>,
                              schedule: studentMap['schedule'] as List<String>,
                              scheduleByDay: studentMap['scheduleByDay'] as Map<String, String>? ?? const <String, String>{},
                              birthDate: studentMap['birthDate'] as String,
                              movementDate:
                                  studentMap['movementDate'] as String,
                              status: studentMap['Status'] as String,
                              isActive: isActive,
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
                              onEdit: () => _openEditStudentDetails(student.code),
                              onPrimaryAction: () async {
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
                                  await _refreshAllStudentApis();
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
                              onDeleteAction: () async {
                                try {
                                  final message =
                                      await studentCubit.deleteStudent(student.code);
                                  if (!mounted) return;
                                  CoreUtils.showTopSnackBar(
                                    context: context,
                                    message: message,
                                    isSuccess: true,
                                  );
                                  await _refreshAllStudentApis();
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