import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/presentation/features/attendance/widgets/student_attendance_vertical_pop_up.dart';
import 'package:wowcare/shared/common/widgets/custom_cancel_button.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/core/util/attendance_cross_class_resolver.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_custom.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_attendance_custom_usecase.dart';
import 'package:wowcare/presentation/features/attendance/cubit/student_attendance_custom_cubit.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_school_time.dart';
import 'package:wowcare/presentation/features/attendance/view/daily_attendance_parent_refresh.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_classroom_by_code_usecase.dart';

class StudentAttendanceCustomView extends StatefulWidget {
  const StudentAttendanceCustomView({
    super.key,
    this.contentOnly = false,
    this.staffAllowedClassrooms,
    this.staffAllowedClassroomIds,
    this.refreshNotifier,
  });

  final bool contentOnly;
  final List<String>? staffAllowedClassrooms;
  final List<int>? staffAllowedClassroomIds;
  final ValueNotifier<int>? refreshNotifier;

  @override
  State<StudentAttendanceCustomView> createState() =>
      _StudentAttendanceCustomViewState();
}

class _StudentAttendanceCustomViewState
    extends State<StudentAttendanceCustomView>
    implements AttendanceTabRefresh {
  final TextEditingController _customSearchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  List<String> _selectedClassroomNames = <String>[];
  List<String>? _selectedClassroomCodes;
  DateTime? _customRangeStart;
  DateTime? _customRangeEnd;
  int? _customExpandedStudentIndex;
  bool _isClassroomDataReady = false;

  // Optional: show a small spinner on "View" action (UI-only)
  final Map<String, bool> _loadingButtons = <String, bool>{};

  late final StudentAttendanceCustomCubit _cubit;
  late final ClassroomCubit _classroomCubit;
  final GetClassroomByCodeUseCase _getClassroomByCode =
      serviceLocator<GetClassroomByCodeUseCase>();
  final Map<String, String> _classroomNameByCode = {};
  final Set<String> _classroomFetchInFlight = {};

  /// When the school allows teacher cross-class attendance, teachers see every
  /// classroom in the filter (like an admin) instead of just their own.
  bool _allowCrossClass = false;

  @override
  void initState() {
    super.initState();
    // Resolve cubit from DI with safe fallback (for hot-reload scenarios)
    if (serviceLocator.isRegistered<StudentAttendanceCustomCubit>()) {
      _cubit = serviceLocator<StudentAttendanceCustomCubit>();
    } else {
      final repo = serviceLocator<AttendanceRepository>();
      _cubit = StudentAttendanceCustomCubit(
        getStudentAttendanceCustomUseCase: GetStudentAttendanceCustomUseCase(
          repo,
        ),
        repository: repo,
      );
    }

    _customSearchController.addListener(_onSearchChanged);
    widget.refreshNotifier?.addListener(_onRefreshRequested);
    _classroomCubit = serviceLocator<ClassroomCubit>();
    _resolveCrossClassFlag();
    // Classroom filter must be backed by the classroom(all) API (type=CLASSROOM).
    // We also guard for "data not loaded yet" so name->code resolution is reliable.
    _loadClassroomData();
    _initializeDefaultRange();
    // Initial load should use cached data when available.
    _loadAttendanceData(reset: false);
    // Resolve the school timezone, then re-seed the default range to the school
    // month if it differs (handles a device in a different zone on cold start).
    _initSchoolTimezone();
  }

  Future<void> _initSchoolTimezone() async {
    final beforeStart = _customRangeStart;
    final beforeEnd = _customRangeEnd;
    await bootstrapAttendanceSchoolTimezone();
    if (!mounted) return;
    final now = attendanceSchoolToday();
    final schoolStart = DateTime(now.year, now.month, 1);
    final schoolEnd = DateTime(now.year, now.month + 1, 0);
    // Re-seed only if the range is still the initial month default (untouched).
    if (beforeStart == _customRangeStart &&
        beforeEnd == _customRangeEnd &&
        (_customRangeStart != schoolStart || _customRangeEnd != schoolEnd)) {
      setState(() {
        _customRangeStart = schoolStart;
        _customRangeEnd = schoolEnd;
      });
      _loadAttendanceData(reset: true);
    }
  }

  void _onRefreshRequested() => refreshAfterReturningFromAttendanceFlow();

  @override
  void refreshAfterReturningFromAttendanceFlow() {
    if (!mounted) return;
    _loadAttendanceData(reset: true);
  }

  /// Resolves the school's teacher cross-class flag; when enabled, reloads the
  /// classroom filter unscoped so teachers see every classroom.
  Future<void> _resolveCrossClassFlag() async {
    try {
      final enabled =
          await AttendanceCrossClassResolver.isEnabledForCurrentSchool(
        storage: serviceLocator<StorageService>(),
      );
      if (!mounted || !enabled || _allowCrossClass) return;
      setState(() => _allowCrossClass = true);
      _loadClassroomData();
    } catch (_) {
      // Non-critical: default (scoped) behaviour stays in effect.
    }
  }

  Future<void> _loadClassroomData() async {
    final hadClassroomSelection = _selectedClassroomNames.isNotEmpty;
    _classroomCubit.loadActiveClassrooms(
      force: true,
      // The classroom filter must list only real classrooms (type=CLASSROOM) —
      // Office / Admin locations must not appear as filter options. Names for
      // non-CLASSROOM locations referenced by historical/transfer records are
      // still resolved on demand via getClassroomByCode (see _fetchClassroomName).
      onlyTypeClassroom: true,
      // Cross-class teachers see every classroom in the filter, like an admin.
      applyAttendanceStaffScope: !_allowCrossClass,
    );

    // Mark ready immediately if data already exists.
    if (!_classroomCubit.state.isLoading &&
        _classroomCubit.state.classrooms.isNotEmpty) {
      if (!mounted) return;
      setState(() => _isClassroomDataReady = true);
      if (hadClassroomSelection) {
        _syncClassroomFilterCodes();
        if (_selectedClassroomCodes != null) {
          _loadAttendanceData(reset: true);
        }
      }
      return;
    }

    // Poll the cubit's state for a short period (avoid hanging forever).
    int attempts = 0;
    while (_classroomCubit.state.isLoading && attempts < 100) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!mounted) return;
    setState(() {
      _isClassroomDataReady =
          !_classroomCubit.state.isLoading &&
          _classroomCubit.state.classrooms.isNotEmpty;
    });
    if (hadClassroomSelection && _isClassroomDataReady) {
      _syncClassroomFilterCodes();
      if (_selectedClassroomCodes != null) {
        _loadAttendanceData(reset: true);
      }
    }
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_onRefreshRequested);
    _customSearchController.removeListener(_onSearchChanged);
    _customSearchController.dispose();
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  String? _resolveClassroomNameByCode(String? code) {
    if (code == null) return null;
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    for (final c in _classroomCubit.state.classrooms) {
      if (c.code.trim() == trimmed) return c.name;
    }
    final cached = _classroomNameByCode[trimmed]?.trim();
    if (cached != null && cached.isNotEmpty) return cached;
    return null;
  }

  Future<void> _fetchClassroomName(String code) async {
    try {
      final details = await _getClassroomByCode(code: code);
      if (!mounted) return;
      final name = details.name.trim();
      if (name.isNotEmpty) {
        setState(() {
          _classroomNameByCode[code] = name;
        });
      }
    } catch (_) {
      // Keep code when lookup fails.
    } finally {
      _classroomFetchInFlight.remove(code);
    }
  }

  String _classroomDisplay({
    required String classroomCode,
    required String classroomName,
  }) {
    final apiName = classroomName.trim();
    final code = classroomCode.trim();
    final apiNameLooksLikeCode =
        apiName.isNotEmpty && (apiName == code || apiName.startsWith('CLS_'));
    if (apiName.isNotEmpty && !apiNameLooksLikeCode) return apiName;
    if (code.isEmpty) return '';
    final resolved = _resolveClassroomNameByCode(code);
    if (resolved != null && resolved.trim().isNotEmpty) return resolved.trim();
    if (!_classroomFetchInFlight.contains(code)) {
      _classroomFetchInFlight.add(code);
      // ignore: discarded_futures
      _fetchClassroomName(code);
    }
    return code;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contentOnly) {
      return BlocProvider.value(value: _cubit, child: _buildContent());
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

    return BlocListener<ClassroomCubit, ClassroomState>(
      bloc: _classroomCubit,
      listenWhen: (previous, current) =>
          previous.classrooms.isEmpty && current.classrooms.isNotEmpty,
      listener: (_, __) => _reloadIfPendingClassroomFilter(),
      child:
          BlocBuilder<
            StudentAttendanceCustomCubit,
            StudentAttendanceCustomState
          >(
            builder: (context, state) {
              return CustomRefreshIndicator(
                onRefresh: () async {
                  _loadAttendanceData(reset: true);
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
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
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: contentPadding.left,
                      vertical: responsive.verticalSpacing / 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: responsive.verticalSpacing / 4),
                        if (!widget.contentOnly) ...[
                          _buildHeaderTabsRow(),
                          const SizedBox(height: AppSpacing.s10),
                          _buildTabIndicator(selectedTab: 1),
                          SizedBox(height: responsive.verticalSpacing),
                        ],
                        _buildFilterSection(),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildContentSection(
                          state,
                          _getFilteredAttendance(state.items),
                        ),
                        if (state.isLoadingMore)
                          Padding(
                            padding: EdgeInsets.all(responsive.verticalSpacing),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        SizedBox(height: responsive.verticalSpacing),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  void _initializeDefaultRange() {
    final now = attendanceSchoolToday();
    _customRangeStart ??= DateTime(now.year, now.month, 1);
    _customRangeEnd ??= DateTime(now.year, now.month + 1, 0);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _customSearchController.text;
    });
    // For search & filter changes, prefer cache-first behaviour.
    _loadAttendanceData(reset: false);
  }

  void _syncClassroomFilterCodes() {
    _selectedClassroomCodes = resolveClassroomNamesToCodes(
      selectedNamesOrCodes: _selectedClassroomNames,
      classrooms: _classroomCubit.state.classrooms,
    );
  }

  List<String>? _effectiveClassroomCodes() {
    if (_selectedClassroomNames.isEmpty) {
      _selectedClassroomCodes = null;
      return null;
    }
    _syncClassroomFilterCodes();
    return _selectedClassroomCodes;
  }

  void _reloadIfPendingClassroomFilter() {
    if (_selectedClassroomNames.isEmpty) return;
    _syncClassroomFilterCodes();
    if (_selectedClassroomCodes == null) return;
    _loadAttendanceData(reset: true);
  }

  void _loadAttendanceData({bool reset = false}) {
    final fromDate = _customRangeStart ?? attendanceSchoolToday();
    final toDate = _customRangeEnd ?? attendanceSchoolToday();

    final classroomCodes = _effectiveClassroomCodes();
    if (_selectedClassroomNames.isNotEmpty && classroomCodes == null) {
      return;
    }

    final search = _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null;
    final hasActiveFilters =
        classroomCodes != null || (search != null && search.isNotEmpty);

    if (reset || hasActiveFilters) {
      _cubit.refresh(
        fromDate: fromDate,
        toDate: toDate,
        classroomCodes: classroomCodes,
        tagCodes: null,
        search: search,
      );
    } else {
      _cubit.loadInitial(
        fromDate: fromDate,
        toDate: toDate,
        classroomCodes: classroomCodes,
        tagCodes: null,
        search: search,
      );
    }
  }

  List<_CustomAttendanceRow> _getFilteredAttendance(
    List<StudentAttendanceCustomItem> items,
  ) {
    // Classroom and search filters are applied server-side via classroomCodes/search.
    return items
        .asMap()
        .entries
        .map((entry) => _mapEntityToRow(entry.value, entry.key))
        .toList();
  }

  _CustomAttendanceRow _mapEntityToRow(
    StudentAttendanceCustomItem item,
    int index,
  ) {
    final daysAttended = item.attendedDays.toString();
    final totalHours = item.attendedTime.isNotEmpty
        ? item.attendedTime
        : '${item.attendedHours} Hrs ${item.attendedMinutes} Mins';

    final id = item.studentCode.isNotEmpty
        ? item.studentCode
        : '${item.studentName}_${item.classroomCode}_$index';

    return _CustomAttendanceRow(
      id: id,
      studentCode: item.studentCode,
      studentId: index,
      studentName: item.studentName,
      roomName: _classroomDisplay(
        classroomCode: item.classroomCode,
        classroomName: item.classroomName,
      ),
      daysAttended: daysAttended,
      totalHours: totalHours,
      expectedToday: item.isExpectedToday,
      hasSignIn: item.hasSignIn,
      signOutTime: item.signedOutTime,
      studentPhotoUuid: '',
    );
  }

  Widget _buildHeaderTabsRow() {
    // This matches the reference UI layout; navigation is intentionally disabled (UI-only).
    int selectedTab = 1; // 0: Daily, 1: Custom, 2: Absent
    void onTabTap(int index) {}

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildTabButton('Daily', 0, selectedTab, onTabTap),
                const SizedBox(width: AppSpacing.md),
                _buildTabButton('Custom', 1, selectedTab, onTabTap),
                const SizedBox(width: AppSpacing.md),
                _buildTabButton('Absent', 2, selectedTab, onTabTap),
              ],
            ),
          ),
        ),
        StudentAttendanceVerticalPopUp(
          students: const [],
          refreshCallback: () => _loadAttendanceData(reset: true),
        ),
      ],
    );
  }

  Widget _buildTabIndicator({required int selectedTab}) {
    return SizedBox(
      height: AppSpacing.s2,
      child: Stack(
        children: [
          Positioned(
            left: _getTabIndicatorPosition(selectedTab),
            child: Container(
              height: 2,
              width: _getTabIndicatorWidth(selectedTab),
              color: const Color(0xFF3B5BDB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final responsive = ResponsiveHelper(context);
    final spacing = responsive.horizontalSpacing / 2;

    return CustomSectionCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: responsive.isTablet ? 3 : 2,
                child: CustomSearchBar(
                  controller: _customSearchController,
                  hintText: 'Search Students',
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                flex: responsive.isTablet ? 2 : 1,
                child: BlocBuilder<ClassroomCubit, ClassroomState>(
                  bloc: _classroomCubit,
                  builder: (context, state) {
                    final items = state.classrooms.map((c) => c.name).toList();
                    final isLoading = state.isLoading || !_isClassroomDataReady;
                    if (isLoading && items.isEmpty) {
                      return ShimmerLoader(
                        height: 40,
                        borderRadius: AppRadius.allMd,
                      );
                    }
                    return CustomMultiSelectDropdown(
                      hintText: 'Classroom',
                      items: items,
                      selectedItems: _selectedClassroomNames,
                      onChanged: (values) {
                        setState(() {
                          _selectedClassroomNames = List<String>.from(values);
                          _syncClassroomFilterCodes();
                        });
                        if (_selectedClassroomNames.isNotEmpty &&
                            _selectedClassroomCodes == null) {
                          return;
                        }
                        _loadAttendanceData(reset: true);
                      },
                    );
                  },
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
                  isRangePicker: true,
                  // Ensure the picker displays current month's default start–end on open
                  fetchInitialTime: true,
                  onRangeSelected: (start, end) {
                    setState(() {
                      _customRangeStart = start;
                      _customRangeEnd = end;
                    });
                    _loadAttendanceData(reset: true);
                  },
                ),
              ),
              SizedBox(width: spacing),
              CustomClearAllChip(
                onTap: () {
                  setState(() {
                    _customSearchController.clear();
                    _searchQuery = '';
                    _selectedClassroomNames = <String>[];
                    _selectedClassroomCodes = null;
                    final now = attendanceSchoolToday();
                    _customRangeStart = DateTime(now.year, now.month, 1);
                    _customRangeEnd = DateTime(now.year, now.month + 1, 0);
                  });
                  _loadAttendanceData(reset: true);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(
    StudentAttendanceCustomState state,
    List<_CustomAttendanceRow> filtered,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return _buildLoadingShimmer();
    }

    if (state.errorMessage != null) {
      return _buildErrorWidget(state.errorMessage!);
    }

    if (filtered.isEmpty) {
      return _buildEmptyWidget();
    }

    return Column(
      children: [
        ...filtered.asMap().entries.map((entry) {
          return _buildCustomStudentCard(entry.value, entry.key);
        }),
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    final responsive = ResponsiveHelper(context);
    return Column(
      children: List.generate(
        8,
        (index) => AttendanceCardShimmer(
          margin: EdgeInsets.only(bottom: responsive.verticalSpacing / 2),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.errorColor,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            AppText.title(
              'Error loading attendance data',
              style: TextStyle(color: AppColors.errorColor, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText.body(
              message.isNotEmpty ? message : 'Please try again.',
              style: TextStyle(color: AppColors.secondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: () => _loadAttendanceData(reset: true),
              icon: const Icon(Icons.refresh),
              label: AppText.body(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Icon(
              Icons.inbox_outlined,
              color: AppColors.secondaryColor,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            AppText.title(
              'No attendance data found',
              style: TextStyle(color: AppColors.secondaryColor, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText.body(
              'Try adjusting your search criteria or date range',
              style: TextStyle(color: AppColors.secondaryColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(
    String label,
    int index,
    int selectedTab,
    void Function(int) onTap,
  ) {
    final bool isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AppText.body(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          color: isSelected ? const Color(0xFF222B45) : const Color(0xFF8F9BB3),
        ),
      ),
    );
  }

  /// Expanded-card detail row styled exactly like staff_card.dart:
  /// label 13/w400 and value 14/w500, both Manrope in Color(0xff573353).
  Widget _buildCustomDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xff573353),
              height: 16 / 13,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xff573353),
              height: 19 / 14,
            ),
            textAlign: TextAlign.end,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomStudentCard(_CustomAttendanceRow attendance, int index) {
    final responsive = ResponsiveHelper(context);
    final bool isExpanded = _customExpandedStudentIndex == index;

    final studentName = attendance.studentName.isNotEmpty
        ? attendance.studentName
        : 'Unknown Student';
    final roomName = attendance.roomName.isNotEmpty
        ? attendance.roomName
        : 'Unknown Room';
    final daysAttended = attendance.daysAttended.isNotEmpty
        ? attendance.daysAttended
        : '0';
    final totalHours = attendance.totalHours.isNotEmpty
        ? attendance.totalHours
        : '0 Hrs 0 Mins';

    final avatarSize = responsive.isTablet ? 52.0 : 44.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _customExpandedStudentIndex = (_customExpandedStudentIndex == index)
              ? null
              : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: responsive.verticalSpacing / 2),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.s10),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: AppRadius.allLg,
          border: Border.all(color: AppColors.cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    DocumentImageWidget(
                      fileUuid: attendance.studentPhotoUuid,
                      studentCode: attendance.studentCode.isNotEmpty
                          ? attendance.studentCode
                          : attendance.id,
                      size: avatarSize,
                      name: studentName,
                      fontSize: responsive.isTablet ? 18 : 16,
                      disableAttendanceStatusLookup: true,
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.s14),
                // Header matches staff_card.dart: name (left) + classroom (right).
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          studentName,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: responsive.isTablet ? 16 : 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xff573353),
                            height: 19 / 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          roomName,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: responsive.isTablet ? 16 : 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xff573353),
                            height: 19 / 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              SizedBox(height: responsive.verticalSpacing / 2),
              Divider(height: 1, color: AppColors.cardBorderColor),
              const SizedBox(height: AppSpacing.s10),
              _buildCustomDetailRow('Attended Days', daysAttended),
              const SizedBox(height: AppSpacing.s6),
              _buildCustomDetailRow('Attended Time', totalHours),
              SizedBox(height: responsive.verticalSpacing / 1.2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: SizedBox(
                  width: double.infinity,
                  child: _loadingButtons[attendance.id] == true
                      ? Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.cardBorderColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: AppRadius.allSm,
                            border: Border.all(
                              color: AppColors.cardBorderColor,
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: AppSpacing.lg,
                              height: AppSpacing.lg,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        )
                      : CustomCancelButton(
                          cancelButtonLabel: 'View',
                          onPressedCancel: () async {
                            setState(
                              () => _loadingButtons[attendance.id] = true,
                            );
                            await Future.delayed(
                              const Duration(milliseconds: 300),
                            );
                            if (!mounted) return;
                            setState(
                              () => _loadingButtons[attendance.id] = false,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentAttendanceProfile(
                                  studentCode: attendance.studentCode,
                                  studentId: attendance.studentId,
                                  studentName: attendance.studentName,
                                  studentPhotoUuid: attendance.studentPhotoUuid,
                                  roomName: attendance.roomName,
                                  isSignedIn: attendance.hasSignIn,
                                  isAbsent:
                                      !attendance.hasSignIn &&
                                      attendance.expectedToday,
                                  isExpectedToday: attendance.expectedToday,
                                  isPresentToday: attendance.hasSignIn,
                                  profileStatus: 'A',
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Simple positioning methods for tab indicator (matches reference implementation)
  double _getTabIndicatorPosition(int selectedTab) {
    double position = 0;
    for (int i = 0; i < selectedTab; i++) {
      position += _getTabWidth(i) + 13;
    }
    return position;
  }

  double _getTabIndicatorWidth(int selectedTab) {
    return _getTabWidth(selectedTab);
  }

  double _getTabWidth(int tabIndex) {
    switch (tabIndex) {
      case 0: // Daily
        return 45.0;
      case 1: // Custom
        return 55.0;
      case 2: // Absent
        return 50.0;
      default:
        return 45.0;
    }
  }
}

class _CustomAttendanceRow {
  final String id;
  final String studentCode;
  final int studentId;
  final String studentName;
  final String studentPhotoUuid;
  final String roomName;
  final String daysAttended;
  final String totalHours;
  final bool expectedToday;
  final bool hasSignIn;
  final String? signOutTime;

  const _CustomAttendanceRow({
    required this.id,
    required this.studentCode,
    required this.studentId,
    required this.studentName,
    required this.studentPhotoUuid,
    required this.roomName,
    required this.daysAttended,
    required this.totalHours,
    required this.expectedToday,
    required this.hasSignIn,
    required this.signOutTime,
  });
}
