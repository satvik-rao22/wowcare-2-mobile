import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_card.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_summary.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_absent_card.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_shimmer.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/cubit/student_attendance_daily_cubit.dart';
import 'package:wowcare/presentation/features/attendance/cubit/student_attendance_absent_toggle_cubit.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_daily.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_absent_form.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/attendance/datasources/attendance_remote_datasource.dart';
import 'package:wowcare/data/features/attendance/repositories/attendance_repository_impl.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_attendance_daily_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_attendance_expected_summary_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_attendance_absent_toggle_view_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_edit_attendance_form.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart'
    show FilterData;
import 'package:wowcare/presentation/features/students/view/student_filter_screen.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  // UI selections are NAME-based (because StudentFilterScreen is name-driven).
  // Before calling APIs we resolve name -> code.
  List<String> _selectedClassroomNames = [];
  List<String> _selectedTagNames = [];
  String? _sortColumn;
  bool _sortAscending = true;
  Map<String, String> _tagNameToCode = <String, String>{};
  bool _isLoadingTagMap = false;
  bool _isClassroomDataReady = false;

  // Summary data (dummy data for now - will be replaced with API later)
  int enrolled = 120;
  int active = 100;
  int upcoming = 20;
  int expected = 0;
  int present = 0;
  int absent = 0;
  int signedOut = 0;
  int notMarked = 0;

  late final StudentAttendanceDailyCubit _cubit;
  late final StudentAttendanceAbsentToggleCubit _absentToggleCubit;
  late final ClassroomCubit _classroomCubit;

  @override
  void initState() {
    super.initState();
    // Note: after adding new GetIt registrations, Flutter hot-reload does NOT rerun `main()`
    // (and therefore doesn't rerun `configureDependencies()`), so the cubit may not be
    // registered in the current process yet. This fallback prevents a runtime crash.
    if (serviceLocator.isRegistered<StudentAttendanceDailyCubit>()) {
      _cubit = serviceLocator<StudentAttendanceDailyCubit>();
    } else {
      final remote = AttendanceRemoteDataSourceImpl(
        serviceLocator<ApiClient>().client,
      );
      final repo = AttendanceRepositoryImpl(
        remote,
        serviceLocator(),
      );

      _cubit = StudentAttendanceDailyCubit(
        getStudentAttendanceDailyUseCase: GetStudentAttendanceDailyUseCase(repo),
        getStudentAttendanceExpectedSummaryUseCase:
            GetStudentAttendanceExpectedSummaryUseCase(repo),
        repository: repo,
      );
    }

    if (serviceLocator.isRegistered<StudentAttendanceAbsentToggleCubit>()) {
      _absentToggleCubit = serviceLocator<StudentAttendanceAbsentToggleCubit>();
    } else {
      final repo = serviceLocator.isRegistered<AttendanceRepositoryImpl>()
          ? serviceLocator<AttendanceRepositoryImpl>()
          : (() {
              final remote = AttendanceRemoteDataSourceImpl(
                serviceLocator<ApiClient>().client,
              );
              return AttendanceRepositoryImpl(
                remote,
                serviceLocator(),
              );
            })();

      _absentToggleCubit = StudentAttendanceAbsentToggleCubit(
        getStudentAttendanceAbsentToggleViewUseCase:
            GetStudentAttendanceAbsentToggleViewUseCase(repo),
      );
    }

    // ClassroomCubit is required by StudentFilterScreen to populate "Classroom".
    if (serviceLocator.isRegistered<ClassroomCubit>()) {
      _classroomCubit = serviceLocator<ClassroomCubit>();
    } else {
      _classroomCubit = ClassroomCubit(
        getActiveClassroomsUseCase: serviceLocator(),
        storageService: serviceLocator(),
      );
    }
    // Load classroom data and tag mapping
    _loadClassroomData();
    _loadTagNameCodeMap();
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

    // Load initial data using cache-aware cubit methods.
    _loadAttendanceData();
  }

  Future<void> _loadClassroomData() async {
    _classroomCubit.loadActiveClassrooms();
    
    // Check if data is already available
    if (!_classroomCubit.state.isLoading && _classroomCubit.state.classrooms.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _isClassroomDataReady = true;
      });
      return;
    }
    
    // Wait for classroom data to be available (max 10 seconds)
    int attempts = 0;
    while (_classroomCubit.state.isLoading && attempts < 100) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    
    if (!mounted) return;
    setState(() {
      _isClassroomDataReady = !_classroomCubit.state.isLoading && 
                              _classroomCubit.state.classrooms.isNotEmpty;
    });
  }

  Future<void> _loadTagNameCodeMap() async {
    if (_isLoadingTagMap) return;
    setState(() {
      _isLoadingTagMap = true;
    });
    
    try {
      final storageService = serviceLocator<StorageService>();
      final schoolCode =
          await storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoadingTagMap = false;
        });
        return;
      }

      final useCase = serviceLocator<GetTagNameCodeMapForSchoolUseCase>();
      final map = await useCase(schoolCode: schoolCode);
      if (!mounted) return;
      setState(() {
        _tagNameToCode = map;
        _isLoadingTagMap = false;
      });
    } catch (e) {
      // Non-critical for filters; log but don't block UI
      debugPrint('Failed to load tag name-to-code map: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingTagMap = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _cubit.close();
    _absentToggleCubit.close();
    _classroomCubit.close();
    super.dispose();
  }

  void _onSearchChanged() {
    // Search should use cache-first behaviour via loadInitial.
    _loadAttendanceData(reset: false);
  }

  List<String>? _resolveSelectedClassroomCodes() {
    if (_selectedClassroomNames.isEmpty) return null;
    
    // Ensure classroom data is loaded
    if (_classroomCubit.state.classrooms.isEmpty) {
      debugPrint('Warning: No classroom data available for code resolution');
      return null;
    }
    
    final nameToCode = <String, String>{
      for (final c in _classroomCubit.state.classrooms) c.name: c.code,
    };
    final codes = _selectedClassroomNames
        .map((n) => nameToCode[n])
        .whereType<String>()
        .toList();
    
    // Log if some names couldn't be resolved
    if (codes.length < _selectedClassroomNames.length) {
      final unresolved = _selectedClassroomNames
          .where((n) => !nameToCode.containsKey(n))
          .toList();
      debugPrint('Warning: Could not resolve classroom codes for: $unresolved');
    }
    
    return codes.isEmpty ? null : codes;
  }

  List<String>? _resolveSelectedTagCodes() {
    if (_selectedTagNames.isEmpty) return null;
    
    // Ensure tag mapping is loaded
    if (_tagNameToCode.isEmpty && !_isLoadingTagMap) {
      debugPrint('Warning: Tag name-to-code map is empty. Attempting to reload...');
      _loadTagNameCodeMap();
      return null; // Return null for now, will retry after map loads
    }
    
    final codes = _selectedTagNames
        .map((n) => _tagNameToCode[n])
        .whereType<String>()
        .toList();
    
    // Log if some names couldn't be resolved
    if (codes.length < _selectedTagNames.length) {
      final unresolved = _selectedTagNames
          .where((n) => !_tagNameToCode.containsKey(n))
          .toList();
      debugPrint('Warning: Could not resolve tag codes for: $unresolved');
    }
    
    return codes.isEmpty ? null : codes;
  }

  void _loadAttendanceData({bool reset = false}) {
    final classroomCodes = _resolveSelectedClassroomCodes();
    final tagCodes = _resolveSelectedTagCodes();
    final search = _searchController.text.trim().isNotEmpty
        ? _searchController.text.trim()
        : null;

    // Debug logging for filter application
    debugPrint('[StudentAttendanceDaily] Loading attendance data:');
    debugPrint('  - Date: $_selectedDate');
    debugPrint('  - Classroom Names: $_selectedClassroomNames');
    debugPrint('  - Classroom Codes: $classroomCodes');
    debugPrint('  - Tag Names: $_selectedTagNames');
    debugPrint('  - Tag Codes: $tagCodes');
    debugPrint('  - Search: $search');
    debugPrint('  - Show Absent Only: $_showAbsentOnly');
    debugPrint('  - Reset: $reset');

    if (_showAbsentOnly) {
      if (reset) {
        _absentToggleCubit.refresh(
          absenceDate: _selectedDate,
          classroomCodes: classroomCodes,
          tagCodes: tagCodes,
          search: search,
        );
      } else {
        _absentToggleCubit.loadInitial(
          absenceDate: _selectedDate,
          classroomCodes: classroomCodes,
          tagCodes: tagCodes,
          search: search,
        );
      }
      return;
    }

    if (reset) {
      _cubit.refresh(
        attendanceDate: _selectedDate,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        search: search,
      );
    } else {
      _cubit.loadInitial(
        attendanceDate: _selectedDate,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        search: search,
      );
    }
  }

  StudentAbsentCardData _absentEntityToCard(
    StudentAttendanceAbsentFormItem item,
    int index,
  ) {
    final roomName = item.classroomName.isNotEmpty
        ? item.classroomName
        : item.classroomCode;

    final absenceDate = item.absenceDate.isNotEmpty
        ? item.absenceDate
        : DateTime.now().toIso8601String();

    final absentTime = item.markedAbsentTime?.formattedHms ?? '';

    return StudentAbsentCardData(
      id: item.studentCode,
      name: item.studentName,
      photoUuid: null,
      roomName: roomName,
      absentTime: absentTime,
      absentBy: item.markedAbsentByName ?? '',
      note: item.absenceNote,
      studentId: index,
      roomId: 0,
      schoolId: 0,
      startDate: absenceDate,
      endDate: absenceDate,
      hasSignIn: false,
      expectedToday: true,
      signInTime: null,
      signOutTime: null,
    );
  }

  // Convert entity to card data
  StudentAttendanceCardData _entityToCardData(StudentAttendanceDailyItem item, int index) {
    return StudentAttendanceCardData(
      id: '${item.studentName}_${item.classroomCode}_$index',
      attendanceRecordCode: item.attendanceRecordCode,
      studentCode: item.studentCode,
      studentName: item.studentName,
      studentPhotoUuid: null, // API doesn't provide this
      roomName: item.classroomName,
      classroomCode: item.classroomCode,
      expectedToday: item.isExpectedToday,
      hasSignIn: item.hasSignIn,
      signInTime: item.formattedSignInTime,
      signOutTime: item.formattedSignOutTime,
      signInBy: null, // API doesn't provide this for daily view
      signOutBy: null, // API doesn't provide this for daily view
      // Map backend method codes (GPS, PIN, QR, APP, etc.) to UI enum.
      signInMethod: _mapMethodStringToEnum(item.signedInMethod),
      signOutMethod: _mapMethodStringToEnum(item.signedOutMethod),
      tags: item.tagNames.isNotEmpty ? item.tagNames : null,
      studentId: index, // Use index as placeholder
      roomId: index, // Use index as placeholder
      schoolId: 1, // Use placeholder
    );
  }

  SignMethod? _mapMethodStringToEnum(String? method) {
    if (method == null) return null;
    final normalized = method.trim().toUpperCase();
    switch (normalized) {
      case 'GPS':
        return SignMethod.gps;
      case 'PIN':
        // PIN entry is effectively via kiosk device.
        return SignMethod.kiosk;
      case 'QR':
        return SignMethod.qr;
      case 'APP':
        return SignMethod.direct;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contentOnly) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _cubit),
          BlocProvider.value(value: _absentToggleCubit),
          BlocProvider.value(value: _classroomCubit),
        ],
        child: _buildContent(),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider.value(value: _absentToggleCubit),
        BlocProvider.value(value: _classroomCubit),
      ],
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
    
    return BlocBuilder<StudentAttendanceAbsentToggleCubit,
        StudentAttendanceAbsentToggleState>(
      builder: (context, absentState) {
        return BlocBuilder<StudentAttendanceDailyCubit,
            StudentAttendanceDailyState>(
          builder: (context, state) {
            final isAbsentMode = _showAbsentOnly;
            final isLoading = isAbsentMode ? absentState.isLoading : state.isLoading;
            final isLoadingMore =
                isAbsentMode ? absentState.isLoadingMore : state.isLoadingMore;
            final hasMore = isAbsentMode ? absentState.hasMore : state.hasMore;
            final errorMessage =
                isAbsentMode ? absentState.errorMessage : state.errorMessage;

            final absentCards = absentState.items
                .asMap()
                .entries
                .map((e) => _absentEntityToCard(e.value, e.key))
                .toList();

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
                  if (!isLoading && !isLoadingMore && hasMore) {
                    if (isAbsentMode) {
                      _absentToggleCubit.loadNextPage();
                    } else {
                      _cubit.loadNextPage();
                    }
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
                    expected: state.expectedCount ?? expected,
                    present: state.presentCount ?? present,
                    absent: state.absentCount ?? absent,
                    signedOut: state.signedOutCount ?? signedOut,
                    notMarked: state.notMarkedCount ?? notMarked,
                    isLoading: state.isLoading ||
                        state.isRefreshing ||
                        state.isSummaryLoading,
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
                  // Filters row styled similar to StaffScreen: search, filter, date, clear all, show absent toggle
                  _buildFilterCard(responsive),
                  SizedBox(height: responsive.verticalSpacing),
                  // Error handling
                  if (errorMessage != null)
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
                              errorMessage,
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
                    if ((absentState.isLoading || absentState.isRefreshing) &&
                        absentCards.isEmpty)
                      ...List.generate(
                          6, (index) => const StudentAbsentCardShimmer())
                    else if (absentCards.isEmpty)
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
                      ...absentCards.asMap().entries.map((entry) {
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
                                  studentCode: student.id,
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
                    if (absentState.isLoadingMore)
                      Padding(
                        padding: EdgeInsets.all(responsive.verticalSpacing),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
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
                          onEdit: () async {
                            final updated = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentEditAttendanceForm(
                                  studentAttendance: student,
                                  attendanceDate: _selectedDate,
                                ),
                              ),
                            );
                            if (updated == true) {
                              _loadAttendanceData(reset: true);
                            }
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
                                  onDelete: () async {
                                    Navigator.of(ctx).pop();

                                    if (student.attendanceRecordCode == null ||
                                        student.attendanceRecordCode!.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Unable to delete: missing attendance record code.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    try {
                                      final storageService =
                                          serviceLocator<StorageService>();
                                      final staffCode = (await storageService
                                                  .getString(
                                                StorageKeys.staffCode,
                                              ) ??
                                              '')
                                          .trim();
                                      if (staffCode.isEmpty) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Unable to resolve staffCode. Please re-login.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final apiClient =
                                          serviceLocator<ApiClient>().client;
                                      final endpoint = ApiPaths.urlWithBase(
                                        ApiPaths.studentAttendanceRecords(
                                          student.attendanceRecordCode!,
                                        ),
                                        ApiConstants.attendanceBaseUrl,
                                      );

                                      await apiClient.delete<dynamic>(
                                        endpoint,
                                        queryParameters: {
                                          'staffCode': staffCode,
                                        },
                                      );

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Attendance deleted'),
                                        ),
                                      );

                                      _loadAttendanceData(reset: true);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to delete attendance: $e',
                                          ),
                                        ),
                                      );
                                    }
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
                                  studentCode: student.studentCode ?? '',
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

  Widget _buildFilterCard(ResponsiveHelper responsive) {
    final hasActiveFilters = _statusLegendFilter != null ||
        _studentFilters != null ||
        _selectedClassroomNames.isNotEmpty ||
        _selectedTagNames.isNotEmpty ||
        _searchController.text.trim().isNotEmpty;

    return Container(
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
                  onTap: _navigateToFilterScreen,
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
                      if (hasActiveFilters)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color.fromRGBO(179, 38, 30, 1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomDateTimeField(
                  hasLabel: false,
                  isRangePicker: false,
                  isTime: false,
                  fetchInitialTime: false,
                  initialDate: _selectedDate,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                    // Date changes should still respect cache where available.
                    _loadAttendanceData(reset: false);
                  },
                ),
              ),
              const SizedBox(width: 8),
              CustomClearAllChip(
                onTap: hasActiveFilters
                    ? () {
                        setState(() {
                          _searchController.clear();
                          _statusLegendFilter = null;
                          _studentFilters = null;
                          _selectedClassroomNames = [];
                          _selectedTagNames = [];
                          _showAbsentOnly = false;
                        });
                        _loadAttendanceData(reset: false);
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: CustomToggle(
              label: 'Show Absent',
              isToggled: _showAbsentOnly,
              onToggle: (value) {
                setState(() {
                  _showAbsentOnly = value;
                  if (value) {
                    _statusLegendFilter = 'Absent';
                  } else if (_statusLegendFilter == 'Absent') {
                    _statusLegendFilter = null;
                  }
                });
                  _loadAttendanceData(reset: false);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToFilterScreen() async {
    // Ensure classroom data is loaded before opening filter screen
    if (!_isClassroomDataReady || _classroomCubit.state.classrooms.isEmpty) {
      // Show loading indicator and wait for data
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      try {
        // Reload classroom data if needed
        if (_classroomCubit.state.classrooms.isEmpty) {
          _classroomCubit.loadActiveClassrooms(force: true);
        }
        
        // Wait for classroom data to load (max 10 seconds)
        int attempts = 0;
        while (_classroomCubit.state.isLoading && attempts < 100) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
        }
        
        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading dialog
        
        // Check if we have data now
        if (_classroomCubit.state.classrooms.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load classroom data. Please try again.'),
            ),
          );
          return;
        }
        
        setState(() {
          _isClassroomDataReady = true;
        });
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load classroom data: $e'),
          ),
        );
        return;
      }
    }
    
    // Ensure tag mapping is loaded
    if (_tagNameToCode.isEmpty && !_isLoadingTagMap) {
      await _loadTagNameCodeMap();
    }
    
    // Wait for tag map if still loading
    if (_isLoadingTagMap) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Wait for tag map to finish loading (max 5 seconds)
      int attempts = 0;
      while (_isLoadingTagMap && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
    }
    
    final result = await Navigator.push<Map<String, List<String>>>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _classroomCubit,
          child: StudentFilterScreen(
            initialFilters: {
              'Classroom': List<String>.from(_selectedClassroomNames),
              'Tags': List<String>.from(_selectedTagNames),
            },
            sections: const [
              StudentFilterSection.classroom,
              StudentFilterSection.tags,
            ],
          ),
        ),
      ),
    );

    if (!mounted || result == null) return;
    
    setState(() {
      _selectedClassroomNames = List<String>.from(result['Classroom'] ?? const []);
      _selectedTagNames = List<String>.from(result['Tags'] ?? const []);
    });
    
    // Reload attendance data with new filters
    _loadAttendanceData(reset: true);
  }

}
