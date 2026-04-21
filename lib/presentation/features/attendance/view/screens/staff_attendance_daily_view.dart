import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_summary.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_card.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_absent_card.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_shimmer.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_profile.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/presentation/features/attendance/cubit/staff_attendance_daily_cubit.dart';
import 'package:wowcare/presentation/features/attendance/cubit/staff_attendance_absent_toggle_cubit.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_edit_attendance_form.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/attendance_attended_duration.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_attendance_daily.dart';
import 'package:wowcare/domain/features/staff/usecases/get_staff_count_usecase.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_classroom_by_code_usecase.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_attendance_absent.dart'
    show StaffAttendanceAbsentItem;
import 'package:wowcare/presentation/features/attendance/view/daily_attendance_parent_refresh.dart';
import 'package:wowcare/presentation/features/staff/view/staff_screen.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';

class StaffAttendanceDailyViewScreen extends StatefulWidget {
  const StaffAttendanceDailyViewScreen({
    super.key,
    this.incomingFilter,
    this.contentOnly = false,
    this.classroomFilter,
  });

  final String? incomingFilter;
  final bool contentOnly;
  final FilterData? classroomFilter;

  @override
  State<StaffAttendanceDailyViewScreen> createState() => _StaffAttendanceDailyViewScreenState();
}

class _StaffAttendanceDailyViewScreenState extends State<StaffAttendanceDailyViewScreen>
    implements DailyAttendanceParentRefresh {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  bool _showAbsentOnly = false;
  String? _statusLegendFilter;
  String? _signInAtFilter;
  String? _signOutAtFilter;
  bool? _isExpectedNotMarkedFilter;
  FilterData? _staffFilters;

  // Total staff summary: same API as StaffScreen "Total Staff" (headline = active + upcoming).
  int totalStaff = 0;
  int active = 0;
  int upcoming = 0;
  int expected = 0;
  int present = 0;
  int absent = 0;
  int signedOut = 0;
  int notMarked = 0;

  // Staff data lists
  final List<StaffAttendanceCardData> _staffMembers = [];
  int? _expandedStaffIndex;
  int? _expandedAbsentIndex;

  late final StaffAttendanceDailyCubit _cubit;
  late final StaffAttendanceAbsentToggleCubit _absentToggleCubit;
  late final ClassroomCubit _classroomCubit;
  String? _loggedInUserName;
  final GetClassroomByCodeUseCase _getClassroomByCode =
      serviceLocator<GetClassroomByCodeUseCase>();
  final Map<String, String> _absentToggleClassroomNameByCode = {};
  final Set<String> _absentToggleClassroomFetchInFlight = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    // Handle incoming filter
    if (widget.incomingFilter != null) {
      _statusLegendFilter =
          widget.incomingFilter == 'Present' ? 'Signed-In' : widget.incomingFilter;
      _applyLegendApiFilters(_statusLegendFilter);
    }

    // Handle classroom filter
    if (widget.classroomFilter != null) {
      _staffFilters = widget.classroomFilter;
    }

    _cubit = serviceLocator<StaffAttendanceDailyCubit>();
    _absentToggleCubit = serviceLocator<StaffAttendanceAbsentToggleCubit>();
    _classroomCubit = serviceLocator<ClassroomCubit>();
    _loadClassroomData();
    _loadLoggedInUserName();

    // Load initial data from API
    _loadAttendanceData(context, reset: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadStaffCounts();
    });
  }

  @override
  void refreshAfterReturningFromAttendanceFlow() {
    if (!mounted) return;
    _loadAttendanceData(context, reset: true);
    unawaited(_loadStaffCounts());
  }

  Future<void> _loadStaffCounts() async {
    try {
      final storage = serviceLocator<StorageService>();
      final organizationCode =
          await storage.getString(StorageKeys.organizationCode) ?? '';
      final schoolCode =
          await storage.getString(StorageKeys.schoolCode) ?? '';
      if (organizationCode.isEmpty || schoolCode.isEmpty) return;

      final useCase = serviceLocator<GetStaffCountUseCase>();
      final staffCount = await useCase(
        organizationCode: organizationCode,
        schoolCode: schoolCode,
      );
      if (!mounted) return;

      setState(() {
        active = staffCount.active;
        upcoming = staffCount.upcoming;
        totalStaff = active + upcoming;
      });
    } catch (_) {
      // Non-fatal; list still works (same as StaffCubit count failures).
    }
  }

  Future<void> _loadClassroomData() async {
    // Transfers can involve non-CLASSROOM locations; load all types to maximize
    // classroomCode → name resolution across the app.
    _classroomCubit.loadActiveClassrooms(
      onlyTypeClassroom: false,
      applyAttendanceStaffScope: true,
    );

    if (!_classroomCubit.state.isLoading &&
        _classroomCubit.state.classrooms.isNotEmpty) {
      if (mounted) setState(() {});
      return;
    }

    int attempts = 0;
    while (_classroomCubit.state.isLoading && attempts < 100) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadLoggedInUserName() async {
    try {
      final storage = serviceLocator<StorageService>();
      final displayName =
          (await storage.getString(StorageKeys.displayName) ?? '').trim();
      final username =
          (await storage.getString(StorageKeys.username) ?? '').trim();
      final fallback = displayName.isNotEmpty
          ? displayName
          : (username.isNotEmpty ? username : '');
      if (!mounted || fallback.isEmpty) return;
      setState(() {
        _loggedInUserName = fallback;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _absentToggleCubit.close();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _loadAttendanceData(context, reset: true);
  }

  // Method to load attendance data from backend
  void _loadAttendanceData(BuildContext context, {bool reset = false}) {
    final classroomCodes = _staffFilters?.classrooms;
    // For now, designation is filtered on the frontend only (no backend API filter),
    // so we do NOT send designation/tagCodes to the attendance APIs.
    final List<String>? tagCodes = null;
    final search = _searchQuery.isEmpty ? null : _searchQuery;

    if (_showAbsentOnly) {
      debugPrint(
        '[StaffDaily] Loading ABSENT toggle list | date=$_selectedDate | '
        'classrooms=$classroomCodes | tags=$tagCodes | search=$search | reset=$reset',
      );
      if (reset) {
        // Match student implementation: reset → refresh first page
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

    debugPrint(
      '[StaffDaily] Loading DAILY list (non-absent) | date=$_selectedDate | '
      'classrooms=$classroomCodes | tags=$tagCodes | signInAtFilter=$_signInAtFilter | '
      'signOutAtFilter=$_signOutAtFilter | search=$search | reset=$reset',
    );

    if (reset) {
      _cubit.loadInitial(
        attendanceDate: _selectedDate,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        signInAtFilter: _signInAtFilter,
        signOutAtFilter: _signOutAtFilter,
        isExpectedNotMarked: _isExpectedNotMarkedFilter,
        search: search,
      );
    } else {
      _cubit.refresh(
        attendanceDate: _selectedDate,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        signInAtFilter: _signInAtFilter,
        signOutAtFilter: _signOutAtFilter,
        isExpectedNotMarked: _isExpectedNotMarkedFilter,
        search: search,
      );
    }
  }

  void _applyLegendApiFilters(String? legendStatus) {
    final normalized = legendStatus == 'Present' ? 'Signed-In' : legendStatus;
    switch (normalized) {
      case 'Signed-In':
        _signInAtFilter = 'NOT_NULL';
        _signOutAtFilter = 'NULL';
        _isExpectedNotMarkedFilter = null;
        _showAbsentOnly = false;
        break;
      case 'Signed Out':
        _signInAtFilter = 'NULL';
        _signOutAtFilter = 'NOT_NULL';
        _isExpectedNotMarkedFilter = null;
        _showAbsentOnly = false;
        break;
      case 'Not Marked':
        _signInAtFilter = 'NULL';
        _signOutAtFilter = 'NULL';
        _isExpectedNotMarkedFilter = true;
        _showAbsentOnly = false;
        break;
      case 'Absent':
        _signInAtFilter = 'NULL';
        _signOutAtFilter = 'IGNORE';
        _isExpectedNotMarkedFilter = null;
        _showAbsentOnly = false;
        break;
      default:
        _signInAtFilter = null;
        _signOutAtFilter = null;
        _isExpectedNotMarkedFilter = null;
    }
  }

  bool _hasActiveFilters() {
    if (_staffFilters == null) return false;
    return _staffFilters!.classrooms.isNotEmpty ||
        _staffFilters!.statuses.isNotEmpty ||
        _staffFilters!.tags.isNotEmpty;
  }

  List<StaffAttendanceCardData> _getFilteredStaff() {
    // Start with the full list from state.
    var filtered = List<StaffAttendanceCardData>.from(_staffMembers);

    // Apply designation filter (frontend-only) when provided via StaffFilterScreen.
    final designationFilters = _staffFilters?.tags ?? const <String>[];
    if (designationFilters.isNotEmpty) {
      final selectedDesignation = designationFilters.first.trim().toUpperCase();
      if (selectedDesignation.isNotEmpty) {
        filtered = filtered.where((staff) {
          final name = staff.designationName?.trim().toUpperCase() ?? '';
          return name == selectedDesignation;
        }).toList();
      }
    }

    return filtered;
  }

  String? _formatDesignation(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.trim().replaceAll('_', ' ').toLowerCase();
    if (cleaned.isEmpty) return null;
    // Title-case each word
    final words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final formatted = words
        .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''))
        .join(' ');
    return formatted;
  }

  String? _resolveClassroomNameByCode(String? code) {
    final target = (code ?? '').trim();
    if (target.isEmpty) return null;
    final classrooms = _classroomCubit.state.classrooms;
    if (classrooms.isEmpty) return null;
    for (final c in classrooms) {
      if (c.code.trim() == target) {
        final name = c.name.trim();
        return name.isNotEmpty ? name : target;
      }
    }
    return null;
  }

  String _classroomDisplay({
    required String classroomCode,
    required String classroomName,
  }) {
    final apiName = classroomName.trim();
    final code = classroomCode.trim();

    // Some backend rows incorrectly return classroomName as the code (e.g. "CLS_...").
    // Treat that as "missing name" so we can resolve via cubit / fallback fetch.
    final apiNameLooksLikeCode =
        apiName.isNotEmpty && (apiName == code || apiName.startsWith('CLS_'));
    if (apiName.isNotEmpty && !apiNameLooksLikeCode) return apiName;

    if (code.isEmpty) return '';

    final fromCubit = _resolveClassroomNameByCode(code);
    if (fromCubit != null && fromCubit.trim().isNotEmpty) return fromCubit.trim();

    final cached = _absentToggleClassroomNameByCode[code]?.trim();
    if (cached != null && cached.isNotEmpty) return cached;

    // Fallback: fetch by code once and update UI when it arrives.
    if (!_absentToggleClassroomFetchInFlight.contains(code)) {
      _absentToggleClassroomFetchInFlight.add(code);
      unawaited(_fetchStaffAbsentToggleClassroomName(code));
    }
    return code;
  }

  String _staffAbsentToggleClassroomDisplay(StaffAttendanceAbsentItem item) {
    final apiName = item.classroomName.trim();
    final code = item.classroomCode.trim();
    final apiNameLooksLikeCode =
        apiName.isNotEmpty && (apiName == code || apiName.startsWith('CLS_'));
    if (apiName.isNotEmpty && !apiNameLooksLikeCode) return apiName;
    if (code.isEmpty) return '';
    final fromCubit = _resolveClassroomNameByCode(code);
    if (fromCubit != null) return fromCubit;
    final cached = _absentToggleClassroomNameByCode[code]?.trim();
    if (cached != null && cached.isNotEmpty) return cached;
    return code;
  }

  void _prefetchStaffAbsentToggleClassroomNames(
    List<StaffAttendanceAbsentItem> items,
  ) {
    for (final item in items) {
      final code = item.classroomCode.trim();
      if (code.isEmpty) continue;
      if (item.classroomName.trim().isNotEmpty) continue;
      if (_resolveClassroomNameByCode(code) != null) continue;
      if (_absentToggleClassroomNameByCode.containsKey(code)) continue;
      if (_absentToggleClassroomFetchInFlight.contains(code)) continue;
      _absentToggleClassroomFetchInFlight.add(code);
      unawaited(_fetchStaffAbsentToggleClassroomName(code));
    }
  }

  Future<void> _fetchStaffAbsentToggleClassroomName(String code) async {
    try {
      final details = await _getClassroomByCode(code: code);
      if (!mounted) return;
      final name = details.name.trim();
      if (name.isNotEmpty) {
        setState(() {
          _absentToggleClassroomNameByCode[code] = name;
        });
      }
    } catch (_) {
      // Keep showing classroom code when lookup fails.
    } finally {
      _absentToggleClassroomFetchInFlight.remove(code);
    }
  }

  void _clearAllFiltersAndSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedDate = DateTime.now();
      _showAbsentOnly = false;
      _statusLegendFilter = null;
      _signInAtFilter = null;
      _signOutAtFilter = null;
      _isExpectedNotMarkedFilter = null;
      _staffFilters = null;
    });
    _loadAttendanceData(context, reset: true);
  }

  void _openStaffListWithIncomingFilter(String status) {
    final normalized = status.trim().toUpperCase();
    if (normalized != 'ACTIVE' && normalized != 'UPCOMING') return;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<StaffCubit>(
              create: (_) => serviceLocator<StaffCubit>()..loadInitial(),
            ),
            BlocProvider<ClassroomCubit>(
              create: (_) => serviceLocator<ClassroomCubit>()
                ..loadActiveClassrooms(
                  onlyTypeClassroom: false,
                ),
            ),
          ],
          child: StaffScreen(incomingStatusFilter: normalized),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contentOnly) {
      return _buildContent();
    }

    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: true,
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    final responsive = ResponsiveHelper(context);
    final contentPadding = ResponsiveSizing.contentPadding(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<StaffAttendanceDailyCubit>.value(value: _cubit),
        BlocProvider<StaffAttendanceAbsentToggleCubit>.value(
          value: _absentToggleCubit,
        ),
      ],
      child: BlocListener<StaffAttendanceAbsentToggleCubit,
          StaffAttendanceAbsentToggleState>(
        listenWhen: (prev, curr) => prev.items != curr.items,
        listener: (context, state) {
          _prefetchStaffAbsentToggleClassroomNames(state.items);
        },
        child: BlocBuilder<StaffAttendanceAbsentToggleCubit,
            StaffAttendanceAbsentToggleState>(
          builder: (context, absentState) {
            return BlocBuilder<StaffAttendanceDailyCubit,
                StaffAttendanceDailyState>(
              builder: (context, state) {
              final isAbsentMode = _showAbsentOnly;
              final isLoading = isAbsentMode
                  ? absentState.isLoading
                  : (state.isLoading || state.isSummaryLoading);
              final isLoadingMore =
                  isAbsentMode ? absentState.isLoadingMore : state.isLoadingMore;
              final hasMore =
                  isAbsentMode ? absentState.hasMore : state.hasMore;

              return CustomRefreshIndicator(
                onRefresh: () async {
                  await _loadStaffCounts();
                  _loadAttendanceData(context, reset: false);
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification &&
                        notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent - 200) {
                      if (!isLoading && !isLoadingMore && hasMore) {
                        if (isAbsentMode) {
                          _absentToggleCubit.loadNextPage();
                        } else {
                          _cubit.loadNextPage();
                        }
                      }
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: contentPadding.left,
                      vertical: responsive.verticalSpacing / 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // Summary Cards — expected stats from attendance API; staff totals from GetStaffCountUseCase
                        StaffAttendanceSummary(
                          totalStaff: totalStaff,
                          active: active,
                          upcoming: upcoming,
                          expected: state.expectedCount ?? expected,
                          present: state.presentCount ?? present,
                          absent: state.absentCount ?? absent,
                          signedOut: state.signedOutCount ?? signedOut,
                          notMarked: state.notMarkedCount ?? notMarked,
                          isLoading: (state.isLoading ||
                                  state.isSummaryLoading) &&
                              !_showAbsentOnly,
                          onLegendTap: (status) {
                            final normalized = status.trim().toUpperCase();
                            if (normalized == 'ACTIVE' ||
                                normalized == 'UPCOMING') {
                              _openStaffListWithIncomingFilter(normalized);
                              return;
                            }
                            setState(() {
                              final normalized =
                                  status == 'Present' ? 'Signed-In' : status;
                              final currentLegend = _statusLegendFilter == 'Present'
                                  ? 'Signed-In'
                                  : _statusLegendFilter;
                              if (currentLegend == normalized) {
                                _statusLegendFilter = null;
                                _applyLegendApiFilters(null);
                              } else {
                                _statusLegendFilter = normalized;
                                _applyLegendApiFilters(normalized);
                              }
                            });
                            _loadAttendanceData(context, reset: false);
                          },
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        // Filters: keep the same date-field UI (CustomDateTimeField) but layout like StaffScreen
                        _buildFilterCard(
                          responsive,
                          hasActiveFilters: _hasActiveFilters() ||
                              _signInAtFilter != null ||
                              _signOutAtFilter != null ||
                              _statusLegendFilter != null ||
                              _searchController.text.trim().isNotEmpty,
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        // Content area
                        if (isLoading)
                          Column(
                            children: List.generate(
                              6,
                              (index) => _showAbsentOnly
                                  ? const StaffAbsentCardShimmer()
                                  : const StaffAttendanceCardShimmer(),
                            ),
                          )
                        else if (_showAbsentOnly)
                          _buildAbsentStaffList(absentState)
                        else
                          _buildStaffListFromState(state),
                      ],
                    ),
                  ),
                ),
              );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterCard(
    ResponsiveHelper responsive, {
    required bool hasActiveFilters,
  }) {
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
                  hintText: 'Search Staff',
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final result =
                        await Navigator.push<Map<String, dynamic>?>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: _classroomCubit,
                          child: StaffFilterScreen(
                            initialFilters: _staffFilters,
                            selectedDate: _selectedDate,
                            sections: const [
                              StaffFilterSection.classroom,
                              StaffFilterSection.designation,
                            ],
                          ),
                        ),
                      ),
                    );

                    if (!mounted || result == null) return;

                    final String? status =
                        (result['status'] as String?)?.trim();
                    final String? designation =
                        (result['designation'] as String?)?.trim();
                    final List<String> classCodes =
                        (result['classCodes'] as List?)?.cast<String>() ??
                            const <String>[];
                    final String? sortBy =
                        (result['sortBy'] as String?)?.trim();

                    setState(() {
                      _staffFilters = FilterData(
                        classroomIds: const <int>[],
                        classrooms: classCodes,
                        statuses: status == null || status.isEmpty
                            ? const <String>[]
                            : <String>[status],
                        // NOTE: StaffFilterScreen uses "designation" for this field.
                        // We keep it in `tags` because the existing daily view already
                        // treats `tags` as the second API filter list.
                        tags: designation == null || designation.isEmpty
                            ? const <String>[]
                            : <String>[designation],
                        sortBy: sortBy,
                      );
                    });

                    _loadAttendanceData(context, reset: true);
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
          SizedBox(height: responsive.verticalSpacing / 2),
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
                    _loadAttendanceData(context, reset: true);
                  },
                ),
              ),
              const SizedBox(width: 8),
              CustomClearAllChip(
                onTap: hasActiveFilters ? _clearAllFiltersAndSearch : null,
              ),
            ],
          ),
          SizedBox(height: responsive.verticalSpacing / 2),
          Align(
            alignment: Alignment.centerRight,
            child: CustomToggle(
              label: 'Show Absent',
              isToggled: _showAbsentOnly,
              onToggle: (value) {
                setState(() {
                  _showAbsentOnly = value;
                  if (value) {
                    // When toggling to Absent, clear legend filters so only absent view applies.
                    _statusLegendFilter = 'Absent';
                    _signInAtFilter = null;
                    _signOutAtFilter = null;
                    _isExpectedNotMarkedFilter = null;
                  } else if (_statusLegendFilter == 'Absent') {
                    _statusLegendFilter = null;
                  }
                });
                debugPrint('[StaffDaily] Show Absent toggled: $_showAbsentOnly');
                _loadAttendanceData(context, reset: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffListFromState(StaffAttendanceDailyState state) {
    _staffMembers.clear();

    for (final item in state.items) {
      // Compute effective sign-in/sign-out display for transfer sequences.
      String? effectiveSignIn;
      String? effectiveSignOut;
      StaffAttendanceTime? effectiveSignInClock;
      StaffAttendanceTime? effectiveSignOutClock;
      bool transferSignIn = false;
      bool transferSignOut = false;
      final int seq = item.sequenceNumber ?? 1;
      final int totalSeq = item.totalSequenceCount ?? 1;

      if (totalSeq <= 1) {
        effectiveSignIn = item.formattedSignInTime;
        effectiveSignOut = item.formattedSignOutTime;
        effectiveSignInClock = item.signedInTime;
        effectiveSignOutClock = item.signedOutTime;
      } else {
        final isFirst = seq == 1;
        final isLast = seq == totalSeq;

        if (isFirst && !isLast) {
          effectiveSignIn = item.formattedSignInTime;
          effectiveSignOut = item.nextActionTime?.formattedTime;
          effectiveSignInClock = item.signedInTime;
          effectiveSignOutClock = item.nextActionTime;
          transferSignOut = effectiveSignOut != null;
        } else if (!isFirst && !isLast) {
          effectiveSignIn = item.transferTime?.formattedTime;
          effectiveSignOut = item.nextActionTime?.formattedTime;
          effectiveSignInClock = item.transferTime;
          effectiveSignOutClock = item.nextActionTime;
          transferSignIn = effectiveSignIn != null;
          transferSignOut = effectiveSignOut != null;
        } else if (isLast) {
          effectiveSignIn =
              isFirst ? item.formattedSignInTime : item.transferTime?.formattedTime;
          effectiveSignOut = item.formattedSignOutTime;
          effectiveSignInClock =
              isFirst ? item.signedInTime : item.transferTime;
          effectiveSignOutClock = item.signedOutTime;
          transferSignIn = !isFirst && effectiveSignIn != null;
        }
      }

      final day = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final startMoment =
          dateAtStaffAttendanceClock(day, effectiveSignInClock);
      final endMoment = dateAtStaffAttendanceClock(day, effectiveSignOutClock);
      final attendedTimeDisplay =
          attendedLabelFromMoments(startMoment, endMoment);

      final String? rawDesignation =
          item.designation.isNotEmpty ? item.designation.first : null;
      final String? formattedDesignation = _formatDesignation(rawDesignation);

      final String effectiveClassroomCode =
          (item.isTransfer == true &&
                  (item.toClassroomCode ?? '').trim().isNotEmpty)
              ? item.toClassroomCode!.trim()
              : item.classroomCode.trim();

      _staffMembers.add(
        StaffAttendanceCardData(
          attendanceRecordCode: item.attendanceRecordCode,
          id: item.staffCode,
          staffName: item.staffName,
          staffPhotoUuid: null,
          designationName: formattedDesignation,
          roomName: _classroomDisplay(
            // Transfer rows may populate `toClassroom*` instead of `classroom*`.
            classroomCode: effectiveClassroomCode.isNotEmpty
                ? effectiveClassroomCode
                : item.classroomCode,
            classroomName: (item.isTransfer == true &&
                    (item.toClassroomName ?? '').trim().isNotEmpty)
                ? item.toClassroomName!
                : item.classroomName,
          ),
          classroomCode:
              effectiveClassroomCode.isNotEmpty ? effectiveClassroomCode : null,
          expectedToday: item.isExpectedToday,
          hasSignIn: item.hasSignIn,
          signInTime: effectiveSignIn ?? item.formattedSignInTime,
          signOutTime: effectiveSignOut ?? item.formattedSignOutTime,
          signInBy: _normalizeByName(item.signedInBy),
          signOutBy: _normalizeByName(item.signedOutBy) ??
              (transferSignOut ? _loggedInUserName : null),
          // Map backend method codes (GPS, PIN, QR, APP, etc.) to UI enum.
          signInMethod: _mapMethodStringToEnum(item.signedInMethod),
          signOutMethod: _mapMethodStringToEnum(item.signedOutMethod),
          staffId: 0,
          roomId: 0,
          schoolId: 0,
          sequenceNumber: item.sequenceNumber,
          totalSequenceCount: item.totalSequenceCount,
          isTransferSignIn: transferSignIn,
          isTransferSignOut: transferSignOut,
          attendedTimeDisplay: attendedTimeDisplay,
        ),
      );
    }

    final filtered = _getFilteredStaff();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              AppText.body(
                'No staff attendance records found for the selected date',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: filtered.asMap().entries.map((entry) {
        final index = entry.key;
        final staff = entry.value;
        return StaffAttendanceCard(
          staff: staff,
          index: index,
          isExpanded: _expandedStaffIndex == index,
          onTap: () {
            setState(() {
              _expandedStaffIndex = _expandedStaffIndex == index ? null : index;
            });
          },
          onEdit: () async {
            await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => StaffEditAttendanceForm(
                  staffAttendance: staff,
                  attendanceDate: _selectedDate,
                ),
              ),
            );
            if (mounted) {
              refreshAfterReturningFromAttendanceFlow();
            }
          },
          onDelete: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) {
                return DeleteConfirmationBottomSheet(
                  name: staff.staffName,
                  type: 'attendance',
                  onDelete: () async {
                    Navigator.of(ctx).pop();
                    if (staff.attendanceRecordCode == null ||
                        staff.attendanceRecordCode!.isEmpty) {
                      CoreUtils.showTopSnackBarFromSnackBar(
                        context: context,
                        snackBar: const SnackBar(
                          content: Text(
                            'Unable to delete: missing attendance record code.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      final normalizedAttendanceCode =
                          _resolveStaffDeleteAttendanceRecordCode(
                        card: staff,
                        allItems: state.items,
                      );
                      if (normalizedAttendanceCode == null ||
                          normalizedAttendanceCode.isEmpty) {
                        CoreUtils.showTopSnackBarFromSnackBar(
                          context: context,
                          snackBar: const SnackBar(
                            content: Text(
                              'Unable to delete: invalid attendance record code.',
                            ),
                          ),
                        );
                        return;
                      }

                      final storageService = serviceLocator<StorageService>();
                      final staffCode =
                          (await storageService.getString(
                                    StorageKeys.staffCode,
                                  ) ??
                                  '')
                              .trim();
                      if (staffCode.isEmpty) {
                        if (!context.mounted) return;
                        CoreUtils.showTopSnackBarFromSnackBar(
                          context: context,
                          snackBar: const SnackBar(
                            content: Text(
                              'Unable to resolve staffCode. Please re-login.',
                            ),
                          ),
                        );
                        return;
                      }

                      await serviceLocator<AttendanceRepository>()
                          .deleteStaffAttendanceRecord(
                        attendanceRecordCode: normalizedAttendanceCode,
                        staffCode: staffCode,
                      );

                      if (!context.mounted) return;
                      CoreUtils.showTopSnackBarFromSnackBar(
                        context: context,
                        snackBar: const SnackBar(
                          content: Text('Attendance deleted'),
                        ),
                      );
                      _loadAttendanceData(context, reset: true);
                    } catch (e) {
                      if (!context.mounted) return;
                      final message = ApiErrorHandler.extractErrorMessage(e);
                      CoreUtils.showTopSnackBarFromSnackBar(
                        context: context,
                        snackBar: SnackBar(
                          content: Text(message),
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
            Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => StaffAttendanceProfile(
                  staffCode: staff.id,
                  staffId: staff.staffId,
                  staffName: staff.staffName,
                  staffPhotoUuid: staff.staffPhotoUuid,
                  designationName: staff.designationName,
                  roomName: staff.roomName,
                  isSignedIn: staff.hasSignIn,
                  isAbsent: false,
                  isExpectedToday: staff.expectedToday,
                  isPresentToday: staff.hasSignIn,
                  profileStatus: 'A',
                ),
              ),
            ).then((_) {
              if (mounted) {
                refreshAfterReturningFromAttendanceFlow();
              }
            });
          },
        );
      }).toList(),
    );
  }

  String? _normalizeByName(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  SignMethod? _mapMethodStringToEnum(String? method) {
    if (method == null) return null;
    final normalized = method.trim().toUpperCase();
    switch (normalized) {
      case 'GPS':
        return SignMethod.gps;
      case 'PIN':
      case 'KIOSK':
        // PIN entry is effectively via kiosk device.
        return SignMethod.kiosk;
      case 'QR':
        return SignMethod.qr;
      case 'APP':
        return SignMethod.direct;
      case 'WEB':
        return SignMethod.web;
      default:
        return null;
    }
  }

  StaffAbsentMarkMethod? _mapAbsentMethodStringToEnum(String? method) {
    if (method == null) return null;
    switch (method.trim().toUpperCase()) {
      case 'GPS':
        return StaffAbsentMarkMethod.gps;
      case 'PIN':
      case 'KIOSK':
        return StaffAbsentMarkMethod.kiosk;
      case 'QR':
        return StaffAbsentMarkMethod.qr;
      case 'APP':
        return StaffAbsentMarkMethod.app;
      case 'WEB':
        return StaffAbsentMarkMethod.web;
      default:
        return null;
    }
  }

  /// Staff daily edit/delete APIs expect rowCode from daily list item `code`.
  String? _resolveStaffDeleteAttendanceRecordCode({
    required StaffAttendanceCardData card,
    required List<StaffAttendanceDailyItem> allItems,
  }) {
    final fromCard = card.attendanceRecordCode?.trim();
    if (fromCard == null || fromCard.isEmpty) return null;
    return fromCard;
  }

  Widget _buildAbsentStaffList(
    StaffAttendanceAbsentToggleState absentState,
  ) {
    if (absentState.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              AppText.body(
                'No absent staff found for the selected date',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final items = absentState.items;

    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final it = entry.value;
        final roomName = _staffAbsentToggleClassroomDisplay(it);
        final absenceDate = it.absenceDate;
        final absentTime = it.markedAbsentTime?.formatted12h ?? '';
        final staff = StaffAbsentCardData(
          id: it.staffCode,
          staffCode: it.staffCode,
          name: it.staffName,
          photoUuid: null,
          roomName: roomName,
          absentTime: absentTime,
          absentBy: it.markedAbsentByName,
          note: it.absenceNote,
          staffId: index,
          roomId: 0,
          schoolId: 0,
          startDate: absenceDate,
          endDate: absenceDate,
          hasSignIn: false,
          expectedToday: true,
          signInTime: null,
          signOutTime: null,
          markAbsentMethod: _mapAbsentMethodStringToEnum(it.markAbsentMethod),
        );
        return StaffAbsentCard(
          staff: staff,
          index: index,
          isExpanded: _expandedAbsentIndex == index,
          onTap: () {
            setState(() {
              _expandedAbsentIndex = _expandedAbsentIndex == index ? null : index;
            });
          },
          onView: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => StaffAttendanceProfile(
                  staffCode: staff.id,
                  staffId: staff.staffId,
                  staffName: staff.name,
                  staffPhotoUuid: staff.photoUuid,
                  roomName: staff.roomName,
                  isSignedIn: staff.hasSignIn,
                  isAbsent: true,
                  isExpectedToday: staff.expectedToday,
                  isPresentToday: false,
                  profileStatus: 'A',
                ),
              ),
            ).then((_) {
              if (mounted) {
                refreshAfterReturningFromAttendanceFlow();
              }
            });
          },
        );
      }).toList(),
    );
  }
}
