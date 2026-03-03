import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/views/filter_screen.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_card.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_summary.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_filters.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_absent_card.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_shimmer.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/cubit/student_attendance_daily_cubit.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_daily.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/data/features/attendance/datasources/attendance_remote_datasource.dart';
import 'package:wowcare/data/features/attendance/repositories/attendance_repository_impl.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_attendance_daily_usecase.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_edit_attendance_form.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';

class StudentAttendanceDailyViewScreen extends StatefulWidget {
  const StudentAttendanceDailyViewScreen({
    super.key,
    this.incomingFilter,
    this.contentOnly = false,
    this.classroomFilter,
    this.staffAllowedClassrooms,
    this.staffAllowedClassroomIds,
  });

  final String? incomingFilter;
  final bool contentOnly;
  final FilterData? classroomFilter;
  final List<String>? staffAllowedClassrooms;
  final List<int>? staffAllowedClassroomIds;

  @override
  State<StudentAttendanceDailyViewScreen> createState() => _StudentAttendanceDailyViewScreenState();
}

class _StudentAttendanceDailyViewScreenState extends State<StudentAttendanceDailyViewScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _showAbsentOnly = false;
  String? _statusLegendFilter;
  FilterData? _studentFilters;
  int? _expandedStudentIndex;
  
  // Filter state
  List<String> _selectedClassrooms = [];
  List<String> _selectedTags = [];
  String? _sortColumn;
  bool _sortAscending = true;

  // Summary data (dummy data for now - will be replaced with API later)
  int enrolled = 120;
  int active = 100;
  int upcoming = 20;
  int expected = 95;
  int present = 85;
  int absent = 10;
  int signedOut = 5;
  int notMarked = 5;

  // Dummy absent students (will be replaced with API later)
  final List<StudentAbsentCardData> _absentStudents = [];

  late final StudentAttendanceDailyCubit _cubit;

  @override
  void initState() {
    super.initState();
    // Note: after adding new GetIt registrations, Flutter hot-reload does NOT rerun `main()`
    // (and therefore doesn't rerun `configureDependencies()`), so the cubit may not be
    // registered in the current process yet. This fallback prevents a runtime crash.
    if (serviceLocator.isRegistered<StudentAttendanceDailyCubit>()) {
      _cubit = serviceLocator<StudentAttendanceDailyCubit>();
    } else {
      final apiClient = serviceLocator<ApiClient>();
      final storageService = serviceLocator<StorageService>();

      final remote = AttendanceRemoteDataSourceImpl(apiClient.client);
      final repo = AttendanceRepositoryImpl(remote, storageService);

      _cubit = StudentAttendanceDailyCubit(
        getStudentAttendanceDailyUseCase: GetStudentAttendanceDailyUseCase(repo),
        repository: repo,
      );
    }
    _searchController.addListener(_onSearchChanged);
    
    // Handle incoming filter
    if (widget.incomingFilter != null) {
      _statusLegendFilter = widget.incomingFilter;
      if (widget.incomingFilter == 'Absent') {
        _showAbsentOnly = true;
      }
    }

    // Handle classroom filter
    if (widget.classroomFilter != null) {
      _studentFilters = widget.classroomFilter;
      // Extract classroom codes from filter if needed
      // _selectedClassrooms = widget.classroomFilter?.selectedValues ?? [];
    }

    // Load initial data
    _loadAttendanceData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onSearchChanged() {
    _loadAttendanceData();
  }

  void _loadAttendanceData({bool reset = false}) {
    if (reset) {
      _cubit.refresh(
        attendanceDate: _selectedDate,
        classroomCodes: _selectedClassrooms.isNotEmpty ? _selectedClassrooms : null,
        tagCodes: _selectedTags.isNotEmpty ? _selectedTags : null,
        search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      );
    } else {
      _cubit.loadInitial(
        attendanceDate: _selectedDate,
        classroomCodes: _selectedClassrooms.isNotEmpty ? _selectedClassrooms : null,
        tagCodes: _selectedTags.isNotEmpty ? _selectedTags : null,
        search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      );
    }
  }

  // Convert entity to card data
  StudentAttendanceCardData _entityToCardData(StudentAttendanceDailyItem item, int index) {
    return StudentAttendanceCardData(
      id: '${item.studentName}_${item.classroomCode}_$index',
      studentName: item.studentName,
      studentPhotoUuid: null, // API doesn't provide this
      roomName: item.classroomName,
      expectedToday: item.isExpectedToday,
      hasSignIn: item.hasSignIn,
      signInTime: item.formattedSignInTime,
      signOutTime: item.formattedSignOutTime,
      signInBy: null, // API doesn't provide this
      signOutBy: null, // API doesn't provide this
      signInMethod: null, // API doesn't provide this
      signOutMethod: null, // API doesn't provide this
      tags: item.tagNames.isNotEmpty ? item.tagNames : null,
      studentId: index, // Use index as placeholder
      roomId: index, // Use index as placeholder
      schoolId: 1, // Use placeholder
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contentOnly) {
      return BlocProvider.value(
        value: _cubit,
        child: _buildContent(),
      );
    }

    return BlocProvider.value(
      value: _cubit,
      child: GlobalScaffold(
        hasBackButton: true,
        showCustomNavigationBar: true,
        body: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final responsive = ResponsiveHelper(context);
    final contentPadding = ResponsiveSizing.contentPadding(context);
    
    return BlocBuilder<StudentAttendanceDailyCubit, StudentAttendanceDailyState>(
      builder: (context, state) {
        return CustomRefreshIndicator(
          onRefresh: () async {
            _loadAttendanceData(reset: true);
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // Only trigger on actual scroll updates
              if (notification is ScrollUpdateNotification) {
                if (notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 200) {
                  if (!state.isLoading &&
                      !state.isLoadingMore &&
                      state.hasMore) {
                    _cubit.loadNextPage();
                  }
                }
              }
              return false;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: contentPadding.left,
                vertical: responsive.verticalSpacing / 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: responsive.verticalSpacing),
                  // Summary cards (only show for admin/director - for now show for all)
                  StudentAttendanceSummary(
                    enrolled: enrolled,
                    active: active,
                    upcoming: upcoming,
                    expected: expected,
                    present: present,
                    absent: absent,
                    signedOut: signedOut,
                    notMarked: notMarked,
                    isLoading: state.isLoading || state.isRefreshing,
                    onLegendTap: (status) {
                      setState(() {
                        if (_statusLegendFilter == status) {
                          _statusLegendFilter = null;
                        } else {
                          _statusLegendFilter = status;
                          if (status == 'Absent') {
                            _showAbsentOnly = true;
                          } else {
                            _showAbsentOnly = false;
                          }
                        }
                      });
                      _loadAttendanceData();
                    },
                  ),
                  SizedBox(height: responsive.verticalSpacing),
                  // Filters row
                  StudentAttendanceFilters(
                    searchController: _searchController,
                    selectedDate: _selectedDate,
                    showAbsentOnly: _showAbsentOnly,
                    selectedClassrooms: _selectedClassrooms,
                    selectedTags: _selectedTags,
                    availableClassrooms: ['Room 1', 'Room 2', 'Room 3', 'Room 4', 'Room 5'],
                    availableTags: ['Full Day', 'Half Day', '5 Days', 'Photo Permission'],
                    hasActiveFilters: _statusLegendFilter != null || 
                        _studentFilters != null || 
                        _selectedClassrooms.isNotEmpty || 
                        _selectedTags.isNotEmpty,
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                      _loadAttendanceData(reset: true);
                    },
                    onToggleChanged: (value) {
                      setState(() {
                        _showAbsentOnly = value;
                        if (value) {
                          _statusLegendFilter = null;
                        }
                      });
                      _loadAttendanceData();
                    },
                    onClassroomsChanged: (classrooms) {
                      setState(() {
                        _selectedClassrooms = classrooms;
                      });
                      _loadAttendanceData(reset: true);
                    },
                    onTagsChanged: (tags) {
                      setState(() {
                        _selectedTags = tags;
                      });
                      _loadAttendanceData(reset: true);
                    },
                    onFilterTap: () {
                      _navigateToFilterScreen();
                    },
                    onClearAll: () {
                      setState(() {
                        _statusLegendFilter = null;
                        _studentFilters = null;
                        _selectedClassrooms = [];
                        _selectedTags = [];
                      });
                      _loadAttendanceData(reset: true);
                    },
                  ),
                  SizedBox(height: responsive.verticalSpacing),
                  // Error handling
                  if (state.errorMessage != null)
                    CustomSectionCard(
                      margin: EdgeInsets.only(bottom: responsive.verticalSpacing),
                      padding: EdgeInsets.all(responsive.horizontalSpacing),
                      backgroundColor: AppColors.errorColor.withOpacity(0.1),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: AppColors.errorColor, size: 24),
                          SizedBox(width: responsive.horizontalSpacing / 2),
                          Expanded(
                            child: AppText.body(
                              state.errorMessage ?? 'Unable to load attendance. Retry.',
                              style: TextStyle(color: AppColors.errorColor),
                            ),
                          ),
                          SizedBox(width: responsive.horizontalSpacing / 2),
                          TextButton(
                            onPressed: () {
                              _loadAttendanceData(reset: true);
                            },
                            child: AppText.body('Retry'),
                          ),
                        ],
                      ),
                    ),
                  // Content based on toggle state
                  if (_showAbsentOnly) ...[
                    // Show absent students (API not integrated yet)
                    if (state.isLoading && _absentStudents.isEmpty)
                      ...List.generate(6, (index) => const StudentAbsentCardShimmer())
                    else if (_absentStudents.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(responsive.verticalSpacing),
                          child: AppText.body(
                            'No absent students found for the selected date',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ..._absentStudents.asMap().entries.map((entry) {
                        final index = entry.key;
                        final student = entry.value;
                        return StudentAbsentCard(
                          student: student,
                          index: index,
                          isExpanded: _expandedStudentIndex == index,
                          onTap: () {
                            setState(() {
                              if (_expandedStudentIndex == index) {
                                _expandedStudentIndex = null;
                              } else {
                                _expandedStudentIndex = index;
                              }
                            });
                          },
                          onView: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentAttendanceProfile(
                                  studentId: student.studentId,
                                  studentName: student.name,
                                  studentPhotoUuid: student.photoUuid,
                                  roomName: student.roomName,
                                  isSignedIn: false,
                                  isAbsent: true,
                                  isExpectedToday: student.expectedToday,
                                  isPresentToday: false,
                                  profileStatus: 'A',
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                  ] else ...[
                    // Show regular attendance data from API
                    if (state.isLoading && state.items.isEmpty)
                      ...List.generate(6, (index) => const StudentAttendanceCardShimmer())
                    else if (state.items.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(responsive.verticalSpacing),
                          child: AppText.body(
                            'No attendance records found for the selected date',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ..._getFilteredStudents(state.items).asMap().entries.map((entry) {
                        final index = entry.key;
                        final student = entry.value;
                        return StudentAttendanceCard(
                          student: student,
                          index: index,
                          isExpanded: _expandedStudentIndex == index,
                          onTap: () {
                            setState(() {
                              if (_expandedStudentIndex == index) {
                                _expandedStudentIndex = null;
                              } else {
                                _expandedStudentIndex = index;
                              }
                            });
                          },
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentEditAttendanceForm(
                                  studentAttendance: student,
                                  attendanceDate: _selectedDate,
                                ),
                              ),
                            );
                          },
                          onDelete: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) {
                                return DeleteConfirmationBottomSheet(
                                  name: student.studentName,
                                  type: 'attendance',
                                  onDelete: () {
                                    Navigator.of(ctx).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Attendance deleted'),
                                      ),
                                    );
                                  },
                                  onCancel: () {
                                    Navigator.of(ctx).pop();
                                  },
                                );
                              },
                            );
                          },
                          onView: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentAttendanceProfile(
                                  studentId: student.studentId,
                                  studentName: student.studentName,
                                  studentPhotoUuid: student.studentPhotoUuid,
                                  roomName: student.roomName,
                                  isSignedIn: student.hasSignIn,
                                  isAbsent: !student.hasSignIn && student.expectedToday,
                                  isExpectedToday: student.expectedToday,
                                  isPresentToday: student.hasSignIn,
                                  profileStatus: 'A',
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    // Loading more indicator
                    if (state.isLoadingMore)
                      Padding(
                        padding: EdgeInsets.all(responsive.verticalSpacing),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<StudentAttendanceCardData> _getFilteredStudents(List<StudentAttendanceDailyItem> items) {
    // Convert entities to card data
    var filtered = items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return _entityToCardData(item, index);
    }).toList();

    // Note: Search, classroom, and tag filters are handled by API
    // These filters below are for client-side filtering if needed (e.g., legend filters)

    // Apply legend filter
    if (_statusLegendFilter != null) {
      if (_statusLegendFilter == 'Present') {
        filtered = filtered
            .where((student) =>
                student.expectedToday && student.hasSignIn)
            .toList();
      } else if (_statusLegendFilter == 'Absent') {
        filtered = filtered
            .where((student) =>
                student.expectedToday && !student.hasSignIn)
            .toList();
      } else if (_statusLegendFilter == 'Signed Out') {
        filtered = filtered
            .where((student) =>
                student.signOutTime != null && student.signOutTime!.isNotEmpty)
            .toList();
      } else if (_statusLegendFilter == 'Not Marked') {
        filtered = filtered
            .where((student) =>
                !student.hasSignIn && student.signInTime == null)
            .toList();
      }
    }

    // Apply sorting
    if (_sortColumn != null) {
      filtered.sort((a, b) {
        int comparison = 0;
        switch (_sortColumn) {
          case 'name':
            comparison = a.studentName.compareTo(b.studentName);
            break;
          case 'classroom':
            comparison = a.roomName.compareTo(b.roomName);
            break;
          case 'expected':
            comparison = a.expectedToday.toString().compareTo(b.expectedToday.toString());
            break;
          case 'signIn':
            comparison = (a.signInTime ?? '').compareTo(b.signInTime ?? '');
            break;
          case 'signOut':
            comparison = (a.signOutTime ?? '').compareTo(b.signOutTime ?? '');
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
    }

    return filtered;
  }

  void _navigateToFilterScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilterScreen(
          title: 'Filter Students',
          sections: [
            FilerSection(
              label: 'Classroom',
              hintText: 'Select classroom',
              items: ['Room 1', 'Room 2', 'Room 3', 'Room 4', 'Room 5'],
              initialSelected: _selectedClassrooms,
              isMultiSelectDropDown: true,
            ),
            FilerSection(
              label: 'Tags',
              hintText: 'Select tags',
              items: ['Full Day', 'Half Day', '5 Days', 'Photo Permission'],
              initialSelected: _selectedTags,
              isMultiSelectDropDown: true,
            ),
          ],
          onApply: (appliedFilters) {
            setState(() {
              _selectedClassrooms = appliedFilters['Classroom'] ?? [];
              _selectedTags = appliedFilters['Tags'] ?? [];
            });
            _loadAttendanceData(reset: true);
          },
        ),
      ),
    );
  }

}
