import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom_details.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_classroom_by_code_usecase.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/student/cubit/student_cubit.dart';
import 'package:wowcare/presentation/features/students/view/student_screen.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/classrooom/views/widgets/classroom_dropdown.dart';
// import 'package:wowcare/presentation/features/dashboard/view/widgets/events_card.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/cache_manager.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_stat_bar_card.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_expected_summary.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_attendance_expected_summary_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_attendance_expected_summary_usecase.dart';

class ClassroomInfoScreen extends StatefulWidget {
  const ClassroomInfoScreen({super.key});

  static const String routeName = '/classroom-info-screen';

  @override
  State<ClassroomInfoScreen> createState() => _ClassroomInfoScreenState();
}

class _ClassroomInfoScreenState extends State<ClassroomInfoScreen> {
  Classroom? _selectedRoom;
  ClassroomDetails? _details;
  /// True while classroom details, enrolled counts, and attendance summaries
  /// for the current selection are still loading (after [classroomCode] is known).
  bool _isAllClassroomApisLoading = false;
  String? _detailsError;
  final GetClassroomByCodeUseCase _getClassroomByCodeUseCase =
      serviceLocator<GetClassroomByCodeUseCase>();
  final GetStudentAttendanceExpectedSummaryUseCase
      _getStudentAttendanceExpectedSummaryUseCase =
      serviceLocator<GetStudentAttendanceExpectedSummaryUseCase>();
  final GetStaffAttendanceExpectedSummaryUseCase
      _getStaffAttendanceExpectedSummaryUseCase =
      serviceLocator<GetStaffAttendanceExpectedSummaryUseCase>();
  StudentAttendanceExpectedSummary? _studentSummary;
  StudentAttendanceExpectedSummary? _staffSummary;
  String? _summaryError;

  late final CacheManager _cacheManager;
  late final StorageService _storage;
  int _enrolledCount = 0;
  int _enrolledActiveCount = 0;
  int _enrolledUpcomingCount = 0;
  String? _enrolledFetchInFlightFor;
  String? _cachedSelectedClassroomCode;
  String? _cachedSelectedClassroomName;

  @override
  void initState() {
    super.initState();
    _storage = serviceLocator<StorageService>();
    _cacheManager = CacheManager(_storage);
    _loadLastSelectedClassroomFromCache();
    // Selected room may be passed as a route argument
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Classroom) {
        setState(() {
          _selectedRoom = args;
        });
        _saveLastSelectedClassroomToCache(args.code, args.name);
        _loadDetails(args.code);
      }
    });
  }

  String get _lastSelectedClassroomCacheKey => CacheManager.buildCacheKey(
        feature: 'classroom',
        resource: 'profile_selected',
        identifier: 'last',
      );

  Future<void> _loadLastSelectedClassroomFromCache() async {
    final cached = await _cacheManager.loadCache(_lastSelectedClassroomCacheKey);
    if (cached == null || !mounted) return;
    final code = (cached['classroomCode'] ?? '').toString().trim();
    final name = (cached['classroomName'] ?? '').toString().trim();
    if (code.isEmpty && name.isEmpty) return;
    setState(() {
      _cachedSelectedClassroomCode = code.isEmpty ? null : code;
      _cachedSelectedClassroomName = name.isEmpty ? null : name;
    });
  }

  Future<void> _saveLastSelectedClassroomToCache(
    String classroomCode,
    String classroomName,
  ) async {
    final code = classroomCode.trim();
    final name = classroomName.trim();
    if (code.isEmpty && name.isEmpty) return;
    await _cacheManager.saveCache(_lastSelectedClassroomCacheKey, {
      'classroomCode': code,
      'classroomName': name,
    });
  }

  String _displayClassroomName({
    required List<Classroom> classrooms,
  }) {
    final fromSelected = _selectedRoom?.name.trim() ?? '';
    if (fromSelected.isNotEmpty) return fromSelected;
    final cachedName = (_cachedSelectedClassroomName ?? '').trim();
    if (cachedName.isNotEmpty) return cachedName;
    if (classrooms.isNotEmpty) return classrooms.first.name;
    return 'Classroom';
  }

  Widget _buildRoomDetailsLoadingCard(String classroomName) {
    return Card(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(
          width: 1.5,
          color: Color.fromARGB(255, 232, 234, 234),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        tileColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        leading: DocumentImageWidget(
          fileUuid: '',
          name: classroomName,
          size: 60,
          fontSize: 24,
        ),
        title: Text(
          classroomName.trim().isEmpty ? 'Classroom' : classroomName.trim(),
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerLoader(
                height: 14,
                width: 220,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ShimmerLoader(
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShimmerLoader(
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _enrolledCountCacheKey(String classroomCode) {
    return CacheManager.buildCacheKey(
      feature: 'classroom',
      resource: 'enrolled_count',
      identifier: classroomCode.trim(),
    );
  }

  Future<void> _hydrateEnrolledCountFromCache(String classroomCode) async {
    final cached = await _cacheManager.loadCache(_enrolledCountCacheKey(classroomCode));
    if (cached == null || !mounted) return;
    final data = cached['data'];
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    setState(() {
      _enrolledActiveCount = (map['activeCount'] as num?)?.toInt() ?? 0;
      _enrolledUpcomingCount = (map['upcomingCount'] as num?)?.toInt() ?? 0;
      _enrolledCount = (map['enrolledCount'] as num?)?.toInt() ?? 0;
    });
  }

  Future<void> _refreshEnrolledCount(String classroomCode) async {
    final code = classroomCode.trim();
    if (code.isEmpty) return;

    final orgCode = (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final schoolCode = (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();

    final path = '/api/v1/student-classroom/enrolled-count/$code';
    final endpoint = ApiPaths.url(path);
    final dio = serviceLocator<ApiClient>().client;

    final response = await dio.get<dynamic>(
      endpoint,
      options: Options(
        headers: <String, dynamic>{
          'accept': 'application/json',
          if (orgCode.isNotEmpty) ...{
            'X-Organization-Code': orgCode,
            'x-organization-code': orgCode,
            'organizationCode': orgCode,
          },
          if (schoolCode.isNotEmpty) ...{
            'X-School-Code': schoolCode,
            'x-school-code': schoolCode,
            'schoolCode': schoolCode,
          },
        },
      ),
    );

    final body = response.data;
    if (body is! Map<String, dynamic>) return;
    final data = body['data'];
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);

    final active = (map['activeCount'] as num?)?.toInt() ?? 0;
    final upcoming = (map['upcomingCount'] as num?)?.toInt() ?? 0;
    final enrolled = (map['enrolledCount'] as num?)?.toInt() ?? 0;

    await _cacheManager.saveCache(_enrolledCountCacheKey(code), {
      'data': {
        'activeCount': active,
        'upcomingCount': upcoming,
        'enrolledCount': enrolled,
      },
    });

    if (!mounted) return;
    final currentSelection = (_selectedRoom?.code ?? '').trim();
    if (currentSelection.isNotEmpty && currentSelection != code) {
      return;
    }
    setState(() {
      _enrolledActiveCount = active;
      _enrolledUpcomingCount = upcoming;
      _enrolledCount = enrolled;
    });
  }

  Future<void> _ensureEnrolledCountLoaded(
    String classroomCode, {
    bool forceRefresh = false,
  }) async {
    final code = classroomCode.trim();
    if (code.isEmpty) return;

    await _hydrateEnrolledCountFromCache(code);

    if (!forceRefresh) {
      final valid =
          await _cacheManager.isCacheValid(_enrolledCountCacheKey(code));
      if (valid) return;
    }

    if (_enrolledFetchInFlightFor == code) return;
    _enrolledFetchInFlightFor = code;
    try {
      await _refreshEnrolledCount(code);
    } catch (_) {
      // Keep hydrated / last known values.
    } finally {
      if (_enrolledFetchInFlightFor == code) {
        _enrolledFetchInFlightFor = null;
      }
    }
  }

  Future<void> _loadSummaries(String classroomCode) async {
    final code = classroomCode.trim();
    if (code.isEmpty) return;

    setState(() {
      _summaryError = null;
    });
    try {
      final student = await _getStudentAttendanceExpectedSummaryUseCase(
        classroomCode: code,
      );
      final staff = await _getStaffAttendanceExpectedSummaryUseCase(
        classroomCode: code,
      );
      if (!mounted) return;
      setState(() {
        _studentSummary = student;
        _staffSummary = staff;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _summaryError = e.toString();
      });
    }
  }

  Future<void> _loadDetails(
    String code, {
    bool refreshEnrolledCounts = false,
  }) async {
    setState(() {
      _details = null;
      _isAllClassroomApisLoading = true;
      _detailsError = null;
      _studentSummary = null;
      _staffSummary = null;
      _summaryError = null;
    });
    try {
      final details = await _getClassroomByCodeUseCase(code: code);
      if (!mounted) return;
      setState(() {
        _details = details;
      });
      await Future.wait<void>([
        _ensureEnrolledCountLoaded(
          code,
          forceRefresh: refreshEnrolledCounts,
        ),
        _loadSummaries(code),
      ]);
      if (!mounted) return;
      setState(() {
        _isAllClassroomApisLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _details = null;
        _isAllClassroomApisLoading = false;
        _detailsError = e.toString();
      });
    }
  }

  Widget _buildRoomDetailsCard(ClassroomDetails details) {
    final isRatioGood = (details.status.toUpperCase() == 'ACTIVE');

    return Card(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(
          width: 1.5,
          color: Color.fromARGB(255, 232, 234, 234),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        tileColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        leading: DocumentImageWidget(
          fileUuid: '',
          name: details.name,
          size: 60,
          fontSize: 24,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              details.name,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Icon(
                  isRatioGood ? Icons.thumb_up : Icons.thumb_down,
                  color: isRatioGood ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                // Uncomment the next line if you want to show the edit icon for admins or directors or when the functionality is implemented
                // if (context.isAdminOrDirector) const Icon(Icons.edit_outlined),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                details.minAgeYear + details.minAgeMonths + details.maxAgeYear + details.maxAgeMonths > 0
                    ? '${details.minAgeYear}-${details.maxAgeYear} Years'
                    : 'No Age Limit',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  color: Color(0xff573353),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text.rich(
                    TextSpan(
                      text: 'Capacity: ',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: Color(0xff573353),
                      ),
                      children: [
                        TextSpan(
                          text: '${details.capacity}',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.bold,
                            color: Color(0xff573353),
                          ),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  )),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text.rich(
                    TextSpan(
                      text: 'Ratio: ',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: Color(0xff573353),
                      ),
                      children: [
                        TextSpan(
                          text: '${details.studentsPerTeacher}:1',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.bold,
                            color: Color(0xff573353),
                          ),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ClassroomCubit>(
      create: (_) => serviceLocator<ClassroomCubit>()..loadActiveClassrooms(),
      child: BlocBuilder<ClassroomCubit, ClassroomState>(
        builder: (context, state) {
          final classrooms = state.classrooms;
          if (classrooms.isNotEmpty && _selectedRoom == null) {
            final cachedCode = (_cachedSelectedClassroomCode ?? '').trim();
            final match = cachedCode.isEmpty
                ? null
                : classrooms.where((c) => c.code.trim() == cachedCode).toList();
            _selectedRoom = match != null && match.isNotEmpty
                ? match.first
                : classrooms.first;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadDetails(_selectedRoom!.code);
            });
          }

          final dropdownItems = classrooms.map((e) => e.name).toList();
          final isInitialLoading = state.isLoading && classrooms.isEmpty;
          final showAllCardsShimmer = isInitialLoading ||
              (_detailsError == null &&
                  _selectedRoom != null &&
                  (_isAllClassroomApisLoading || _details == null));

          return GlobalScaffold(
            bodyPadding: EdgeInsets.zero,
            body: CustomRefreshIndicator(
              onRefresh: () async {
                await context.read<ClassroomCubit>().loadActiveClassrooms(force: true);
                if (_selectedRoom != null) {
                  await _loadDetails(
                    _selectedRoom!.code,
                    refreshEnrolledCounts: true,
                  );
                }
              },
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: ClassroomDropdown(
                                items: dropdownItems.isEmpty
                                    ? const ['Loading...']
                                    : dropdownItems,
                                value: dropdownItems.isEmpty
                                    ? 'Loading...'
                                    : (_selectedRoom?.name ??
                                        dropdownItems.first),
                                onChanged: (value) {
                                  if (dropdownItems.isEmpty) return;
                                  final selected = classrooms
                                      .firstWhere((c) => c.name == value);
                                  setState(() {
                                    _selectedRoom = selected;
                                  });
                                  _saveLastSelectedClassroomToCache(
                                    selected.code,
                                    selected.name,
                                  );
                                  _loadDetails(selected.code);
                                },
                              ),
                            ),
                            IconButton(
                              tooltip: 'Back',
                              onPressed: () => Navigator.pop(context),
                              icon: SvgPicture.asset(
                                MediaRes.infoButtonIcon,
                                height: 32,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (showAllCardsShimmer)
                          Column(
                            children: [
                              _buildRoomDetailsLoadingCard(
                                _displayClassroomName(classrooms: classrooms),
                              ),
                              const SizedBox(height: 16),
                              const SummaryCardShimmer(),
                              const SizedBox(height: 16),
                              const SummaryCardShimmer(),
                              const SizedBox(height: 16),
                              const SummaryCardShimmer(),
                            ],
                          )
                        else if (_detailsError != null)
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              'Failed to load classroom details',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.red),
                            ),
                          )
                        else if (_details != null) ...[
                          if (_summaryError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Failed to load summary cards',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.red),
                              ),
                            ),
                          _buildRoomDetailsCard(_details!),
                          const SizedBox(height: 16),
                          CustomStatBarCard(
                            title: 'Enrolled\nStudents',
                            number: '$_enrolledCount',
                            items: [
                              ProgressItemHelper(
                                label: 'Active ($_enrolledActiveCount)',
                                value: _enrolledActiveCount.toDouble(),
                                color: AppColors.lightBlueProgressBar,
                                filterValue: 'ACTIVE',
                              ),
                              ProgressItemHelper(
                                label: 'Upcoming ($_enrolledUpcomingCount)',
                                value: _enrolledUpcomingCount.toDouble(),
                                color: AppColors.mustardProgressBar,
                                filterValue: 'UPCOMING',
                              ),
                            ],
                            onLegendTap: (_, filterValue) {
                              final v = (filterValue ?? '').trim().toUpperCase();
                              if (v != 'ACTIVE' && v != 'UPCOMING') return;
                              _openStudentListForClassroomStatus(v);
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildExpectedAttendanceSummaryCard(
                            title: 'Expected\nStudents',
                            summary: _studentSummary,
                            forStaff: false,
                          ),
                          const SizedBox(height: 16),
                          _buildExpectedAttendanceSummaryCard(
                            title: 'Expected\nStaff',
                            summary: _staffSummary,
                            forStaff: true,
                          ),
                        ],
                        // Events section (temporarily disabled)
                        // Card(
                        //   elevation: 0,
                        //   color: Colors.white,
                        //   surfaceTintColor: Colors.white,
                        //   shape: RoundedRectangleBorder(
                        //     side: const BorderSide(
                        //       width: 1.5,
                        //       color: Color.fromARGB(255, 232, 234, 234),
                        //     ),
                        //     borderRadius: BorderRadius.circular(12),
                        //   ),
                        //   child: Padding(
                        //     padding: const EdgeInsets.all(16),
                        //     child: Column(
                        //       crossAxisAlignment: CrossAxisAlignment.start,
                        //       children: [
                        //         Text(
                        //           'Events',
                        //           style: TextStyle(
                        //             fontFamily: 'Manrope',
                        //             fontSize: 20,
                        //             fontWeight: FontWeight.bold,
                        //             color: const Color(0xff573353),
                        //           ),
                        //         ),
                        //         const SizedBox(height: 16),
                        //         Row(
                        //           mainAxisAlignment:
                        //               MainAxisAlignment.spaceBetween,
                        //           children: const [
                        //             Icon(Icons.chevron_left,
                        //                 color: Colors.grey),
                        //             Text(
                        //               'Nov 2025',
                        //               style: TextStyle(
                        //                 fontFamily: 'Manrope',
                        //                 color: Color(0xff573353),
                        //               ),
                        //             ),
                        //             Icon(Icons.chevron_right,
                        //                 color: Colors.grey),
                        //           ],
                        //         ),
                        //         const SizedBox(height: 16),
                        //         const EventsCard(),
                        //         const SizedBox(height: 16),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
            ),
            hasBackButton: true,
          );
        },
      ),
    );
  }

  FilterData? _classroomAttendanceFilter() {
    final code = (_selectedRoom?.code ?? '').trim();
    if (code.isEmpty) return null;
    return FilterData(
      classroomIds: const <int>[],
      classrooms: [code],
      statuses: const <String>[],
      tags: const <String>[],
    );
  }

  void _openStudentListForClassroomStatus(String statusUpper) {
    final room = _selectedRoom;
    final code = (_selectedRoom?.code ?? '').trim();
    if (room == null || code.isEmpty) return;

    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<StudentCubit>(
              create: (_) => serviceLocator<StudentCubit>()..loadInitial(),
            ),
            BlocProvider<ClassroomCubit>(
              create: (_) => serviceLocator<ClassroomCubit>()
                ..loadActiveClassrooms(
                  onlyTypeClassroom: false,
                  applyAttendanceStaffScope: true,
                ),
            ),
          ],
          child: StudentScreen(
            incomingStatusFilter: statusUpper,
            incomingClassroomSelections: [
              room.name.trim(),
              room.code.trim(),
            ],
          ),
        ),
      ),
    );
  }

  void _openAttendanceForClassroom({
    required bool staff,
    required String incomingFilter,
  }) {
    final filter = _classroomAttendanceFilter();
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) {
          if (staff) {
            return StaffAttendanceTabbedView(
              initialTabIndex: 0,
              dailyIncomingFilter: incomingFilter,
              classroomFilter: filter,
            );
          }
          return StudentAttendanceTabbedView(
            initialTabIndex: 0,
            dailyIncomingFilter: incomingFilter,
            classroomFilter: filter,
          );
        },
      ),
    );
  }

  /// Same stat bar styling as student/staff daily attendance expected cards.
  Widget _buildExpectedAttendanceSummaryCard({
    required String title,
    required StudentAttendanceExpectedSummary? summary,
    required bool forStaff,
  }) {
    final expected = summary?.expected ?? 0;
    final present = summary?.present ?? 0;
    final absent = summary?.absent ?? 0;
    final signedOut = summary?.signOut ?? 0;
    final notMarked = summary?.notMarked ?? 0;

    return CustomStatBarCard(
      title: title,
      number: expected.toString(),
      normalizeBarByItemSum: true,
      items: [
        ProgressItemHelper(
          label: 'Signed-In ($present)',
          value: present.toDouble(),
          color: AppColors.lightGreenProgressBar,
          filterValue: 'Signed-In',
        ),
        ProgressItemHelper(
          label: 'Absent ($absent)',
          value: absent.toDouble(),
          color: AppColors.redProgressBar,
          filterValue: 'Absent',
        ),
        ProgressItemHelper(
          label: 'Signed Out ($signedOut)',
          value: signedOut.toDouble(),
          color: AppColors.lightBlueProgressBar,
          filterValue: 'Signed Out',
        ),
        ProgressItemHelper(
          label: 'Not Marked ($notMarked)',
          value: notMarked.toDouble(),
          color: AppColors.mustardProgressBar,
          filterValue: 'Not Marked',
        ),
      ],
      onLegendTap: (_, filterValue) {
        final v = (filterValue ?? '').trim();
        if (v.isEmpty) return;
        _openAttendanceForClassroom(staff: forStaff, incomingFilter: v);
      },
    );
  }
}

class ClassroomInfoShimmer extends StatelessWidget {
  const ClassroomInfoShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 200,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Room Details Card
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),

              // Enrolled Students Card
              _buildMetricsShimmerCard(),
              const SizedBox(height: 16),

              // Expected Students Card
              _buildMetricsShimmerCard(),
              const SizedBox(height: 16),

              // Expected Staff Card
              _buildMetricsShimmerCard(),
              const SizedBox(height: 16),

              // Events Card
              Container(
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Events Title
                      Container(
                        width: 80,
                        height: 24,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),

                      // Calendar Week Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                            7,
                            (index) => Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                )),
                      ),
                      const SizedBox(height: 24),

                      // Event Items
                      ...List.generate(
                          3,
                          (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Row(
                                  children: [
                                    // Date Container
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Event Details
                                    Expanded(
                                      child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsShimmerCard() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Title and Number
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 32,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 40,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(width: 24),
            // Progress Bar and Labels
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 80,
                        height: 12,
                        color: Colors.white,
                      ),
                      Container(
                        width: 80,
                        height: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
