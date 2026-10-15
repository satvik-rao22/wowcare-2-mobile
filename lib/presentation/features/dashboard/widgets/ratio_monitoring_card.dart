import 'dart:async';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/presentation/features/dashboard/model/dashboard_route_args.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/classroom/entities/ratio_monitoring_classroom.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';
import 'package:wowcare/domain/features/communication/usecases/get_or_create_classroom_chat_usecase.dart';
import 'package:wowcare/presentation/features/communication/view_model/unread_badge_cubit.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/ratio_monitoring_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/dashboard_card_header.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/dashboard_collapsible.dart';
import 'package:wowcare/presentation/features/classroom/view/screens/classroom_screen.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart';
import 'package:wowcare/shared/common/widgets/profile_avatar.dart';

import 'dashboard_error_chip.dart';

// ---------------------------------------------------------------------------
// RatioMonitoringCard
// ---------------------------------------------------------------------------

/// Dashboard card with live classroom student-to-staff ratios: shimmer on
/// first open, silent refresh on return from background, shimmer again on
/// pull-to-refresh.
class RatioMonitoringCard extends StatefulWidget {
  const RatioMonitoringCard({super.key, this.isDashboard = true});

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
  DateTime _selectedDate = AppTime.now();
  bool _showAllClassrooms = false;
  bool _minimized = false;

  // ── lifecycle tracking ─────────────────────────────────────────────────────

  // Minimum time between two silent refreshes (prevents rapid consecutive hits).
  static const _refreshCooldown = Duration(seconds: 30);

  /// Resolved once in [didChangeDependencies] and passed to [BlocBuilder]
  /// explicitly: a `context.read` inside a LayoutBuilder can run before the
  /// inherited chain is ready.
  RatioMonitoringCubit? _cubit;

  // ── Notes (CLASSROOM_CHAT) unread badges ──────────────────────────────────
  // One Firestore subscription per classroom, resolved for every classroom
  // (not just the visible page) because the unread-first sort needs them all.
  final Map<String, int> _notesUnreadCounts = {};
  final Set<String> _notesUnreadResolving = {};
  final Map<String, StreamSubscription<int>> _notesUnreadSubscriptions = {};

  // Backoff delays for [_resolveNotesUnreadCount]'s retry-on-failure —
  // mirrors UnreadBadgeCubit's own _retryDelays for the identical class of
  // problem (a transient Firestore/REST hiccup must not permanently blank a
  // badge).
  static const _notesUnreadRetryDelays = [2, 4, 8];

  /// Current known unread-notes count for [classroomCode] — 0 until
  /// resolution completes or if the classroom has no Notes chat yet. Kicks
  /// off resolution (deduped) on first request.
  int _notesUnreadCountFor(String classroomCode) {
    if (classroomCode.isNotEmpty &&
        !_notesUnreadCounts.containsKey(classroomCode) &&
        !_notesUnreadResolving.contains(classroomCode)) {
      _notesUnreadResolving.add(classroomCode);
      unawaited(_resolveNotesUnreadCount(classroomCode));
    }
    return _notesUnreadCounts[classroomCode] ?? 0;
  }

  /// Resolves [classroomCode]'s Notes conversation and watches its unread
  /// count into [_notesUnreadCounts]. Retries with backoff on failure so one
  /// bad call does not hide the badge for the session.
  Future<void> _resolveNotesUnreadCount(
    String classroomCode, {
    int attempt = 0,
  }) async {
    if (attempt == 0) {
      // Never touch serviceLocator/setState mid-build.
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!mounted) return;
    try {
      final conv = await serviceLocator<GetOrCreateClassroomChatUseCase>()
          .findExisting(classroomCode);
      final code = conv?.code ?? '';
      if (!mounted) return;
      if (code.isEmpty) {
        // No Notes chat exists for this classroom yet — nothing to watch,
        // not a failure, so no retry. Record a known 0 so this classroom
        // doesn't keep re-triggering resolution on every build.
        setState(() => _notesUnreadCounts[classroomCode] = 0);
        return;
      }
      _notesUnreadSubscriptions[classroomCode]?.cancel();
      _notesUnreadSubscriptions[classroomCode] =
          serviceLocator<ConversationEntityRepository>()
              .watchUnreadCountForConversation(code)
              .listen((count) {
                if (!mounted) return;
                setState(() => _notesUnreadCounts[classroomCode] = count);
              });
    } catch (_) {
      if (!mounted) return;
      if (attempt < _notesUnreadRetryDelays.length) {
        Future.delayed(Duration(seconds: _notesUnreadRetryDelays[attempt]), () {
          if (mounted) {
            unawaited(
              _resolveNotesUnreadCount(classroomCode, attempt: attempt + 1),
            );
          }
        });
      } else {
        // Out of retries — allow a later rebuild (pull-to-refresh, date
        // change, returning to this tab) to try again from scratch rather
        // than staying permanently stuck.
        _notesUnreadResolving.remove(classroomCode);
      }
    }
  }

  /// Opens [room]'s classroom screen on the Notes tab (index 2). Fires
  /// [ClassroomScreenNav.openClassroomTab] as well as `context.go`: a
  /// kept-alive ClassroomScreen only gets `didUpdateWidget`, which alone
  /// proved unreliable for switching tabs.
  void _navigateToClassroomNotes(
    BuildContext context,
    RatioMonitoringClassroom room,
  ) {
    ClassroomScreenNav.openClassroomTab(classroomCode: room.code, tabIndex: 2);
    context.go('${ClassroomScreen.routeName}?classroomCode=${room.code}&tab=2');
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _selectedDate = SchoolZoneDateTime.schoolCalendarTodayOnly(
      SchoolTimezoneResolver.lastKnownTimeZone,
    );
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
    for (final sub in _notesUnreadSubscriptions.values) {
      sub.cancel();
    }
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
        AppTime.nowUtc().difference(lastFetch) < _refreshCooldown) {
      return;
    }

    unawaited(
      _resolveSchoolCode().then((schoolCode) {
        if (schoolCode == null || !mounted) return;
        cubit.loadRatioMonitoring(
          schoolCode: schoolCode,
          isSilent: true,
          date: _selectedDate,
        );
      }),
    );
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
          bg: AppPalette.surfaceSelected,
        ),
        _buildHeaderCell(
          mainText: 'Students',
          subText: 'Present',
          bg: AppPalette.domainStudentSoft,
        ),
        _buildHeaderCell(
          mainText: 'Staff',
          subText: 'Present',
          bg: AppPalette.domainStaffSoft,
        ),
        _buildHeaderCell(
          mainText: 'Ratio',
          subText: 'Current',
          bg: AppPalette.statusWarningSoft,
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
                color: AppColors.primaryColor,
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
                color: MaterialHues.grey800,
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
                color: MaterialHues.grey800,
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
    BuildContext context,
    RatioMonitoringClassroom room,
  ) {
    final filter = FilterData(
      classroomIds: const [],
      classrooms: [room.code],
      statuses: const [],
      tags: const [],
    );
    unawaited(
      context.push(
        StudentAttendanceTabbedView.routeName,
        extra: AttendanceTabbedViewArgs(
          initialTabIndex: 0,
          classroomFilter: filter,
        ),
      ),
    );
  }

  /// Navigates to the **Staff** daily attendance tab pre-filtered to [room].
  void _navigateToStaffAttendance(
    BuildContext context,
    RatioMonitoringClassroom room,
  ) {
    final filter = FilterData(
      classroomIds: const [],
      classrooms: [room.code],
      statuses: const [],
      tags: const [],
    );
    unawaited(
      context.push(
        StaffAttendanceTabbedView.routeName,
        extra: AttendanceTabbedViewArgs(
          initialTabIndex: 0,
          classroomFilter: filter,
        ),
      ),
    );
  }

  /// Builds a data row for [room]. Always renders: zero present means
  /// "no one signed in", not "missing classroom".
  TableRow _buildDataRow(RatioMonitoringClassroom room) {
    return TableRow(
      key: ValueKey(room.code),
      children: [
        // ── Classroom name ──────────────────────────────────────────────────
        // The whole cell (avatar + name) is one tap target to the Notes tab.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _navigateToClassroomNotes(context, room),
          child: Container(
            height: _cellH,
            color: AppColors.whiteColor,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              // Firestore-sourced Notes (CLASSROOM_CHAT) unread count for
              // this one classroom — already resolved (or resolving) for
              // every classroom in the table by [build]'s sort step, so
              // this is a plain lookup, not a fresh subscription per row.
              child: Builder(
                builder: (context) {
                  final unread = _notesUnreadCountFor(room.code);
                  return Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ProfileAvatar(
                            name: room.name,
                            classroomCode: room.code,
                            lookUpProfilePhoto: false,
                            size: 30,
                            fontSize: 12,
                          ),
                          if (unread > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: MaterialHues.red,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.whiteColor,
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  unread > 99 ? '99+' : unread.toString(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.whiteColor,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8.0),
                      Flexible(
                        child: Text(
                          room.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 6.0),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unread > 99
                                ? AppStrings.unreadCountOverflow
                                : '$unread',
                            style: const TextStyle(
                              color: AppColors.textOnDarkColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
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
            color: AppPalette.domainStudentSoft,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
              child: Text(
                room.studentPresent.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: AppColors.primaryColor,
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
            color: AppPalette.domainStaffSoft,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
              child: Text(
                room.staffPresent.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),

        // ── Ratio indicator (thumb up / down) ───────────────────────────────
        Container(
          height: _cellH,
          color: AppPalette.statusWarningSoft,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
            child: Center(
              child: AppIcon(
                room.isRatioGood ? MediaRes.thumbUp : MediaRes.thumbDown,
                tone: room.isRatioGood ? IconTone.success : IconTone.danger,
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
            state.isInitial || (state.isLoading && state.classrooms.isEmpty);

        if (showShimmer) {
          return const _RatioMonitoringCardShimmer();
        }

        final classrooms = [...state.classrooms];

        // Resolve every classroom's unread count up front, then sort unread
        // first (alphabetical within each bucket), so a classroom past the
        // "Show More" cutoff still gets its badge.
        final notesUnreadByCode = {
          for (final c in classrooms) c.code: _notesUnreadCountFor(c.code),
        };
        classrooms.sort((a, b) {
          final aUnread = (notesUnreadByCode[a.code] ?? 0) > 0;
          final bUnread = (notesUnreadByCode[b.code] ?? 0) > 0;
          if (aUnread != bUnread) return aUnread ? -1 : 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        final displayed = (_showAllClassrooms || !widget.isDashboard)
            ? classrooms
            : classrooms.take(_initialDisplayCount).toList();
        final hasMore = classrooms.length > _initialDisplayCount;

        return DashboardCardErrorOverlay(
          show: state.isError,
          onRetry: _load,
          child: Container(
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
                    onToggle: () => setState(() => _minimized = !_minimized),
                    trailing: _buildDateNavigator(),
                    badgeCount: context
                        .watch<UnreadBadgeCubit>()
                        .state
                        .unreadFor(ConversationType.classroomChat),
                  ),
                ),

                DashboardCollapsible(
                  collapsed: _minimized,
                  child: Column(
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
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.05,
                            ),
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
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.03,
                              ),
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
                ),
              ],
            ),
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
        baseColor: MaterialHues.grey300,
        highlightColor: MaterialHues.grey100,
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
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 20,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            // Column headers
            Container(
              height: 90,
              color: AppColors.whiteColor.withValues(alpha: 0.6),
            ),
            // Data rows
            ...List.generate(
              _shimmerRows,
              (_) => Container(
                height: _rowH,
                margin: const EdgeInsets.only(top: 1),
                color: AppColors.whiteColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
