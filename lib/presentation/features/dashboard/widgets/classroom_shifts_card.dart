import 'dart:async';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/classroom_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/dashboard_card_toggle.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/dashboard_error_chip.dart';
import 'package:wowcare/presentation/features/scheduling/model/scheduling_models.dart';
import 'package:wowcare/presentation/features/scheduling/utils/scheduling_block_status_style.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/day_classroom_section.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/staff_schedule_tile.dart';

import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/presentation/features/scheduling/view/scheduling_screen.dart';

// date formatter used for the scheduling deep-link
final _ymd = DateFormat('yyyy-MM-dd');

/// Dashboard card that mirrors the visual structure of [_ClassroomListCard]
/// from the scheduling screen.
///
/// Collapsed row  : classroom logo + name + chevron | ratio icon
/// Expanded rows  : one [StaffRowLeft] + [StaffTimeRangePill] per staff member
///                  (solid border = published, dotted border = draft)
class ClassroomShiftsCard extends StatefulWidget {
  const ClassroomShiftsCard({super.key, this.onRedirect});

  /// Optional callback invoked when the redirect arrow is tapped.
  /// Defaults to navigating to [SchedulingScreen].
  final VoidCallback? onRedirect;

  @override
  State<ClassroomShiftsCard> createState() => _ClassroomShiftsCardState();
}

class _ClassroomShiftsCardState extends State<ClassroomShiftsCard> {
  static const int _initialDisplayCount = 6;

  DateTime _selectedDate = AppTime.now();
  bool _showAllClassrooms = false;
  bool _minimized = false;

  /// Global expand/collapse — mirrors [_SchedulingScreenContentState._expandAll].
  bool _expandAll = false;

  /// Per-row override; cleared when [_expandAll] flips so all rows follow it.
  final Map<String, bool> _rowExpanded = {};

  /// Mandate 7: this was `MediaQuery.of(context).size.width > 600 ? 16 : 14` —
  /// a FIFTH live definition of "tablet" in the app, disagreeing with
  /// `ResponsiveHelper`'s 768 that 122 other files use, and reading through
  /// `.of` so the getter re-resolved on every keyboard open. The 600 boundary
  /// is preserved exactly: `AppBreakpoints.compactMaxWidth` is also 600, so
  /// `compact` is `< 600` and `medium` starts at 600 — identical rendering.
  double get _bodyFontSize => context.responsive(compact: 14, medium: 16);

  /// Guards against re-issuing the full load sequence on every
  /// `didChangeDependencies` firing (ancestor rebuilds, navigation, etc.).
  /// The dashboard coordinator already calls `ClassroomShiftsCubit.load()`
  /// on first open and on pull-to-refresh; this is only a fallback for the
  /// case where the cubit hasn't been loaded yet by the time this card mounts.
  bool _hasRequestedLoad = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = SchoolZoneDateTime.schoolCalendarTodayOnly(
      SchoolTimezoneResolver.lastKnownTimeZone,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasRequestedLoad) return;
    final cubit = context.read<ClassroomShiftsCubit>();
    if (cubit.state.status != ClassroomShiftsStatus.initial) return;
    _hasRequestedLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(cubit.load(_selectedDate));
      }
    });
  }

  void _changeDate(int days) {
    final newDate = _selectedDate.add(Duration(days: days));
    setState(() => _selectedDate = newDate);
    unawaited(context.read<ClassroomShiftsCubit>().load(newDate));
  }

  void _toggleExpandAll() {
    setState(() {
      _expandAll = !_expandAll;
      _rowExpanded.clear();
    });
  }

  void _toggleRow(String code) {
    setState(() {
      _rowExpanded[code] = !(_rowExpanded[code] ?? _expandAll);
    });
  }

  bool _isExpanded(String code) => _rowExpanded[code] ?? _expandAll;

  Widget _buildDateNavigator() {
    final label = DateFormat('EEE, MMM d').format(_selectedDate);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavArrow(icon: Icons.arrow_back_ios_new, onTap: () => _changeDate(-1)),
        const SizedBox(width: 2),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: AppColors.primaryColor,
                fontSize: _bodyFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        _NavArrow(icon: Icons.arrow_forward_ios, onTap: () => _changeDate(1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClassroomShiftsCubit, ClassroomShiftsState>(
      builder: (context, state) {
        final showShimmer =
            state.status == ClassroomShiftsStatus.initial ||
            (state.isLoading && state.entries.isEmpty);

        if (showShimmer) return const _ClassroomShiftsCardShimmer();

        final entries = state.entries;
        final displayEntries = _showAllClassrooms
            ? entries
            : entries.take(_initialDisplayCount).toList();
        final hasMoreToShow = entries.length > _initialDisplayCount;

        return DashboardCardErrorOverlay(
          show: state.isError,
          onRetry: () =>
              context.read<ClassroomShiftsCubit>().load(_selectedDate),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorderColor),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.whiteColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Card header ─────────────────────────────────────────────────
                Row(
                  children: [
                    const Text(
                      'Classroom Shifts',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (widget.onRedirect != null) {
                          widget.onRedirect!();
                        } else {
                          context.go(SchedulingScreen.routeName);
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: SvgPicture.asset(
                        MediaRes.redirectArrowGradientIcon,
                        width: 16,
                        height: 16,
                      ),
                    ),

                    const Spacer(),
                    if (state.isLoading && entries.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    DashboardCardToggle(
                      minimized: _minimized,
                      onTap: () => setState(() => _minimized = !_minimized),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Body ────────────────────────────────────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _minimized
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Legend
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _ClassroomShiftsLegendItem(
                                  status: ClassroomRatioStatus.underRatio,
                                  label: 'Not In Ratio',
                                  fontSize: _bodyFontSize,
                                ),
                                const SizedBox(width: 16),
                                _ClassroomShiftsLegendItem(
                                  status: ClassroomRatioStatus.inRatio,
                                  label: 'In Ratio',
                                  fontSize: _bodyFontSize,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // ── Scheduling-screen identical inner container ─────
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.whiteColor,
                                border: Border.all(
                                  color: const Color(0x33162831),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Header row: "Expand/Collapse All" | date
                                    SchedulingTableRow(
                                      onTap: entries.isNotEmpty
                                          ? _toggleExpandAll
                                          : null,
                                      dividerColor:
                                          kSchedulingHeaderBorderColor,
                                      backgroundColor:
                                          kSchedulingHeaderBackground,
                                      left: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 14,
                                        ),
                                        child: Text(
                                          _expandAll
                                              ? 'Collapse All'
                                              : 'Expand All',
                                          style: TextStyle(
                                            fontFamily: AppFonts.body,
                                            fontSize: _bodyFontSize,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryColor,
                                          ),
                                        ),
                                      ),
                                      right: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        child: _buildDateNavigator(),
                                      ),
                                    ),

                                    // Classroom rows
                                    if (displayEntries.isEmpty &&
                                        !state.isLoading)
                                      SchedulingTableRow(
                                        isLast: true,
                                        left: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 16,
                                          ),
                                          child: Text(
                                            'No classrooms found',
                                            style: TextStyle(
                                              fontSize: _bodyFontSize,
                                              color: MaterialHues.grey500,
                                            ),
                                          ),
                                        ),
                                        right: const SizedBox.shrink(),
                                      )
                                    else
                                      for (
                                        int i = 0;
                                        i < displayEntries.length;
                                        i++
                                      )
                                        _ClassroomSection(
                                          entry: displayEntries[i],
                                          isExpanded: _isExpanded(
                                            displayEntries[i].classroomCode,
                                          ),
                                          onTap: () => _toggleRow(
                                            displayEntries[i].classroomCode,
                                          ),
                                          isLast:
                                              i == displayEntries.length - 1 &&
                                              !hasMoreToShow,
                                          onClassroomNameTap: () => context.go(
                                            '${SchedulingScreen.routeName}'
                                            '?view=day'
                                            '&highlightCode=${displayEntries[i].classroomCode}'
                                            '&date=${_ymd.format(SchoolZoneDateTime.schoolCalendarTodayOnly(SchoolTimezoneResolver.lastKnownTimeZone))}',
                                          ),
                                        ),
                                  ],
                                ),
                              ),
                            ),

                            // On error, the card silently keeps showing
                            // whatever rows are in state (empty table if none)
                            // instead of surfacing an error line.

                            // Show More / Show Less
                            if (!state.isLoading && hasMoreToShow)
                              InkWell(
                                onTap: () => setState(
                                  () =>
                                      _showAllClassrooms = !_showAllClassrooms,
                                ),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
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
// _ClassroomSection
//
// Mirrors [DayClassroomSection._buildWeekView] exactly:
//   • Header row : [ClassroomRowLeft] + animated chevron  |  ratio status icon
//   • Staff rows  : [StaffRowLeft]                        |  [StaffTimeRangePill]
//
// [StaffTimeRangePill] uses a solid border for published shifts and a dotted
// border (via [_DashedRRectPainter] inside the widget) for drafts — the same
// visual treatment as the scheduling screen.
// ---------------------------------------------------------------------------

class _ClassroomSection extends StatelessWidget {
  const _ClassroomSection({
    required this.entry,
    required this.isExpanded,
    required this.onTap,
    required this.isLast,
    this.onClassroomNameTap,
  });

  final ClassroomShiftEntry entry;
  final bool isExpanded;
  final VoidCallback onTap;
  final bool isLast;
  final VoidCallback? onClassroomNameTap;

  @override
  Widget build(BuildContext context) {
    final hasStaff = entry.staff.isNotEmpty;
    final headerIsLast = isLast && (!isExpanded || !hasStaff);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Classroom header row ─────────────────────────────────────────────
        SchedulingTableRow(
          onTap: hasStaff ? onTap : null,
          isLast: headerIsLast,
          left: Row(
            children: [
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: onClassroomNameTap,
                    behavior: HitTestBehavior.opaque,
                    child: ClassroomRowLeft(
                      classroomCode: entry.classroomCode,
                      classroomName: entry.name,
                    ),
                  ),
                ),
              ),
              if (hasStaff)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          right: SchedulingBlockStatusStyle.weekViewIconForClassroomStatus(
            entry.ratioStatus,
            size: 20,
          ),
        ),

        // ── Staff rows (animated, same as scheduling screen) ─────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: isExpanded && hasStaff
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < entry.staff.length; i++)
                      SchedulingTableRow(
                        isLast: isLast && i == entry.staff.length - 1,
                        left: StaffRowLeft(entry: entry.staff[i]),
                        right: StaffTimeRangePill(
                          startTime: entry.staff[i].startTime,
                          endTime: entry.staff[i].endTime,
                          isPublished: entry.staff[i].isPublished,
                        ),
                      ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Legend item
// ---------------------------------------------------------------------------

class _ClassroomShiftsLegendItem extends StatelessWidget {
  const _ClassroomShiftsLegendItem({
    required this.status,
    required this.label,
    required this.fontSize,
  });

  final ClassroomRatioStatus status;
  final String label;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SchedulingBlockStatusStyle.weekViewIconForClassroomStatus(
          status,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: fontSize)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _NavArrow — compact prev/next in the header right cell
// ---------------------------------------------------------------------------

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(icon, size: 14, color: AppColors.primaryColor),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-card shimmer — first load only
// ---------------------------------------------------------------------------

class _ClassroomShiftsCardShimmer extends StatelessWidget {
  const _ClassroomShiftsCardShimmer();

  static const int _shimmerRows = 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorderColor),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.whiteColor,
      ),
      child: Shimmer.fromColors(
        baseColor: MaterialHues.grey300,
        highlightColor: MaterialHues.grey100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 20,
                  width: 160,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 20,
                  width: 24,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 14,
                  width: 90,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  height: 14,
                  width: 70,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Inner table
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor.withValues(alpha: 0.8),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                  ),
                  ...List.generate(
                    _shimmerRows,
                    (_) => Container(
                      height: 80,
                      margin: const EdgeInsets.only(top: 1),
                      color: AppColors.whiteColor.withValues(alpha: 0.5),
                    ),
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
