import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/classroom/entities/ratio_monitoring_classroom.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/ratio_monitoring_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

// ---------------------------------------------------------------------------
// RatioMonitoringCard
// ---------------------------------------------------------------------------

/// Dashboard card that displays live classroom student-to-staff ratios.
///
/// Lifecycle:
/// - **First open**: shows shimmer → classroom rows appear with 0 counts
///   once the classroom list loads → counts update when attendance data arrives.
/// - **App returns from background** (`WidgetsBindingObserver`): silently
///   refreshes attendance data; existing rows stay visible throughout.
/// - **Pull-to-refresh**: triggered by parent `AdminDashboard`; shimmer shown.
class RatioMonitoringCard extends StatefulWidget {
  const RatioMonitoringCard({
    super.key,
    this.isDashboard = true,
  });

  final bool isDashboard;

  @override
  State<RatioMonitoringCard> createState() => _RatioMonitoringCardState();
}

class _RatioMonitoringCardState extends State<RatioMonitoringCard>
    with WidgetsBindingObserver {
  // ── constants ──────────────────────────────────────────────────────────────
  static const double _cellH = 50;
  static const int _initialDisplayCount = 7;

  // ── UI state ───────────────────────────────────────────────────────────────
  DateTime _selectedDate = DateTime.now();
  bool _showAllClassrooms = false;
  bool _minimized = false;

  // ── lifecycle tracking ─────────────────────────────────────────────────────

  // Minimum time between two silent refreshes (prevents rapid consecutive hits).
  static const _refreshCooldown = Duration(seconds: 30);

  /// Cached cubit reference — resolved once in [didChangeDependencies] and
  /// passed explicitly to [BlocBuilder] so that BlocBuilder never needs to
  /// call context.read<RatioMonitoringCubit>() in its own initState (which
  /// can fail when the widget is first inflated inside a LayoutBuilder during
  /// the layout phase before the InheritedWidget chain is fully resolved).
  RatioMonitoringCubit? _cubit;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Trigger initial load. The cubit's _isFetching guard prevents duplication
    // if AdminDashboard also calls loadRatioMonitoring.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Resolve the cubit safely — didChangeDependencies is guaranteed to run
    // with a fully mounted context where all InheritedWidgets are accessible.
    _cubit = context.read<RatioMonitoringCubit>();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── App lifecycle ──────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _silentRefresh();
    }
  }

  // ---------------------------------------------------------------------------
  // Data loading helpers
  // ---------------------------------------------------------------------------

  Future<void> _load({DateTime? date}) async {
    final cubit = _cubit;
    if (cubit == null) return;
    final schoolCode = await _resolveSchoolCode();
    if (schoolCode == null || !mounted) return;
    cubit.loadRatioMonitoring(
      schoolCode: schoolCode,
      isSilent: true,
      date: date ?? _selectedDate,
    );
  }

  void _silentRefresh() {
    if (!mounted) return;
    final cubit = _cubit;
    if (cubit == null) return;

    // Cooldown: avoid hammering the API on rapid lifecycle events.
    final lastFetch = cubit.lastFetchAt;
    if (lastFetch != null &&
        DateTime.now().difference(lastFetch) < _refreshCooldown) {
      return;
    }

    unawaited(_resolveSchoolCode().then((schoolCode) {
      if (schoolCode == null || !mounted) return;
      cubit.loadRatioMonitoring(
        schoolCode: schoolCode,
        isSilent: true,
        date: _selectedDate,
      );
    }));
  }

  Future<String?> _resolveSchoolCode() async {
    final storage = serviceLocator<StorageService>();
    final code = await storage.getString(StorageKeys.schoolCode);
    return (code != null && code.isNotEmpty) ? code : null;
  }

  // ---------------------------------------------------------------------------
  // Header date navigator
  // ---------------------------------------------------------------------------

  /// Date selection is disabled — the ratio-monitoring summary API only
  /// reflects the current day regardless of the `date` query param, so the
  /// picker is replaced with a static "today" label instead of an
  /// interactive control that silently does nothing.
  Widget _buildDateNavigator() {
    return Text(
      DateFormat('EEE, MMM d').format(_selectedDate),
      style: const TextStyle(
        color: AppColors.primaryColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Table header
  // ---------------------------------------------------------------------------

  TableRow _buildHeaderRow() {
    return TableRow(
      children: [
        _buildHeaderCell(
          mainText: 'Classroom',
          subText: '',
          bg: const Color.fromRGBO(249, 245, 250, 1),
        ),
        _buildHeaderCell(
          mainText: 'Students',
          subText: 'Present',
          bg: const Color.fromRGBO(234, 240, 253, 1),
        ),
        _buildHeaderCell(
          mainText: 'Staff',
          subText: 'Present',
          bg: const Color.fromRGBO(234, 251, 255, 1),
        ),
        _buildHeaderCell(
          mainText: 'Ratio',
          subText: 'Current',
          bg: const Color.fromRGBO(255, 245, 234, 1),
        ),
      ],
    );
  }

  Widget _buildHeaderCell({
    required String mainText,
    required String subText,
    required Color bg,
  }) {
    return Container(
      height: 90,
      decoration: BoxDecoration(color: bg),
      child: Column(
        children: [
          Expanded(child: const SizedBox.shrink()),
          if (subText.isNotEmpty) ...[
            Text(
              mainText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                color: Color.fromRGBO(87, 51, 83, 1),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              subText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ] else
            Text(
              mainText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Table rows
  // ---------------------------------------------------------------------------

  TableRow _buildEmptyRow() {
    return TableRow(
      children: List.generate(4, (_) => SizedBox(height: _cellH)),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  /// Navigates to the **Student** daily attendance tab pre-filtered to [room].
  ///
  /// Uses [FilterData.classrooms] as classroom codes — the daily view reads
  /// them with `_resolveSelectedClassroomCodes` (line 416 of the daily view).
  void _navigateToStudentAttendance(
      BuildContext context, RatioMonitoringClassroom room) {
    final filter = FilterData(
      classroomIds: const [],
      classrooms: [room.code],
      statuses: const [],
      tags: const [],
    );
    unawaited(context.push(
      StudentAttendanceTabbedView.routeName,
      extra: <String, dynamic>{
        'initialTabIndex': 0,
        'classroomFilter': filter,
      },
    ));
  }

  /// Navigates to the **Staff** daily attendance tab pre-filtered to [room].
  void _navigateToStaffAttendance(
      BuildContext context, RatioMonitoringClassroom room) {
    final filter = FilterData(
      classroomIds: const [],
      classrooms: [room.code],
      statuses: const [],
      tags: const [],
    );
    unawaited(context.push(
      StaffAttendanceTabbedView.routeName,
      extra: <String, dynamic>{
        'initialTabIndex': 0,
        'classroomFilter': filter,
      },
    ));
  }

  /// Builds a data row for [room].
  ///
  /// Always renders — even when [room.studentPresent] and [room.staffPresent]
  /// are both 0 (attendance data not yet available or not present for this
  /// classroom). A zero means "no one signed in", not "missing classroom".
  TableRow _buildDataRow(RatioMonitoringClassroom room) {
    return TableRow(
      children: [
        // ── Classroom name ──────────────────────────────────────────────────
        GestureDetector(
          onTap: () {},
          child: Container(
            height: _cellH,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  DocumentImageWidget(
                    fileUuid: '',
                    name: room.name,
                    size: 30,
                    fontSize: 12,
                    disableProfileLookupFallback: true,
                    disableAttendanceStatusLookup: true,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      room.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: Color.fromRGBO(87, 51, 83, 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Students present — tapping navigates to student daily attendance
        //    pre-filtered to this classroom.
        GestureDetector(
          onTap: () => _navigateToStudentAttendance(context, room),
          child: Container(
            height: _cellH,
            color: const Color.fromRGBO(234, 240, 253, 1),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
              child: Text(
                room.studentPresent.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Color.fromRGBO(87, 51, 83, 1),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),

        // ── Staff present — tapping navigates to staff daily attendance
        //    pre-filtered to this classroom.
        GestureDetector(
          onTap: () => _navigateToStaffAttendance(context, room),
          child: Container(
            height: _cellH,
            color: const Color.fromRGBO(234, 251, 255, 1),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
              child: Text(
                room.staffPresent.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Color.fromRGBO(87, 51, 83, 1),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),

        // ── Ratio indicator (thumb up / down) ───────────────────────────────
        Container(
          height: _cellH,
          color: const Color.fromRGBO(255, 245, 234, 1),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
            child: Center(
              child: SvgPicture.asset(
                room.isRatioGood ? MediaRes.thumbUp : MediaRes.thumbDown,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RatioMonitoringCubit, RatioMonitoringState>(
      bloc: _cubit,
      builder: (context, state) {
        // Show shimmer ONLY on the very first load (no classroom data at all).
        // If we already have classroom rows — even with 0 counts — keep them
        // visible while attendance data silently updates in background.
        final showShimmer =
            state.isInitial ||
            (state.isLoading && state.classrooms.isEmpty);

        if (showShimmer) {
          return const _RatioMonitoringCardShimmer();
        }

        final classrooms = [...state.classrooms]
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        final displayed = (_showAllClassrooms || !widget.isDashboard)
            ? classrooms
            : classrooms.take(_initialDisplayCount).toList();
        final hasMore = classrooms.length > _initialDisplayCount;

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorderColor),
            borderRadius: BorderRadius.circular(12),
            color: AppColors.cardColor,
          ),
          child: Column(
            children: [
              // ── Card header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                child: DashboardCardHeader(
                  title: 'Ratio Monitoring',
                  minimized: _minimized,
                  onToggle: () =>
                      setState(() => _minimized = !_minimized),
                  trailing: _buildDateNavigator(),
                ),
              ),

              // ── Body (hidden when minimized) ───────────────────────────────
              if (!_minimized) ...[
                Column(
                  children: [
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1.1),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1),
                      },
                      border: TableBorder.symmetric(
                        inside: BorderSide(
                          color: AppColors.primaryColor
                              .withValues(alpha: 0.05),
                        ),
                      ),
                      children: [
                        _buildHeaderRow(),
                        if (displayed.isEmpty)
                          _buildEmptyRow()
                        else
                          ...displayed.map(_buildDataRow),
                      ],
                    ),

                    // ── Show More / Show Less ──────────────────────────────
                    if (hasMore && widget.isDashboard)
                      InkWell(
                        onTap: () => setState(
                          () => _showAllClassrooms = !_showAllClassrooms,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor
                                .withValues(alpha: 0.03),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _showAllClassrooms
                                    ? 'Show Less'
                                    : 'Show More',
                                style: const TextStyle(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _showAllClassrooms
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: AppColors.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer — matches exact card dimensions; shown only on first load.
// ---------------------------------------------------------------------------

class _RatioMonitoringCardShimmer extends StatelessWidget {
  const _RatioMonitoringCardShimmer();

  static const double _rowH = 50;
  static const int _shimmerRows = 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorderColor),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.cardColor,
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 20,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 20,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            // Column headers
            Container(
              height: 90,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            // Data rows
            ...List.generate(
              _shimmerRows,
              (_) => Container(
                height: _rowH,
                margin: const EdgeInsets.only(top: 1),
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
