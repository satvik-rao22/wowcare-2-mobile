import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/school_status_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_error_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_stat_bar_card.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';

/// Colours for the breakdown bar segments that have no exact theme constant.
const Color _signedOutColor = Color(0xFF8BB4EF);
const Color _notMarkedColor = Color(0xFFEBC398);

/// One labelled segment of a breakdown bar (name + count + colour).
class _Seg {
  const _Seg(this.name, this.count, this.color);

  final String name;
  final int count;
  final Color color;
}

/// Converts raw count segments into [ProgressItemHelper]s for
/// [CustomStatBarCard]. The bar `value` is the count expressed as a percentage
/// of [total] (so the segments fill the bar exactly), while the legend label
/// keeps the real count, e.g. "Signed-in (15)".
List<ProgressItemHelper> _percentItems({
  required int total,
  required List<_Seg> raw,
}) {
  return raw
      .map(
        (s) => ProgressItemHelper(
          label: '${s.name} (${s.count})',
          value: total == 0 ? 0 : s.count / total * 100,
          color: s.color,
        ),
      )
      .toList();
}

/// "Today's School Status" dashboard card.
///
/// Integrated with [SchoolStatusCubit] to fetch, cache, and display live
/// school status metrics (enrollment counts, capacity, classrooms, FTE, and attendance breakdowns).
class EnrollmentCard extends StatefulWidget {
  const EnrollmentCard({super.key, this.isDashboard = false});

  /// Kept for API compatibility with the dashboard feed.
  final bool isDashboard;

  @override
  State<EnrollmentCard> createState() => _EnrollmentCardState();
}

class _EnrollmentCardState extends State<EnrollmentCard> {
  bool _minimized = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = serviceLocator<StorageService>();
    final schoolCode = await storage.getString(StorageKeys.schoolCode);
    if (schoolCode != null && schoolCode.isNotEmpty && mounted) {
      try {
        await context.read<SchoolStatusCubit>().loadSchoolStatus(
          schoolCode: schoolCode,
          isSilent: true,
        );
      } catch (e) {
        // Safe fallback in case the Cubit is not provided in some context
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SchoolStatusCubit, SchoolStatusState>(
      builder: (context, state) {
        final isLoading =
            state.isInitial || (state.isLoading && state.schoolCode.isEmpty);
        if (isLoading) {
          return const _EnrollmentCardShimmer();
        }

        // On error, fall through to the normal card layout below — it
        // renders whatever values are in state (zeros on a first-load
        // failure) instead of replacing the card with an error banner.
        return DashboardCardErrorOverlay(
          show: state.isError,
          onRetry: _loadData,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.cardBorderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardCardHeader(
                  title: "Today's School Status",
                  minimized: _minimized,
                  onToggle: () => setState(() => _minimized = !_minimized),
                ),

                if (!_minimized) ...[
                  const SizedBox(height: 16),

                  // ── Capacity summary — three stat columns ─────────────────────
                  // classroomClassrooms excludes admin/non-teaching rooms.
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _StatColumn(
                            value: state.classroomClassrooms.toString(),
                            label: 'Total \n Classrooms',
                          ),
                        ),
                        // VerticalDivider(
                        //   width: 1,
                        //   color: AppColors.primaryColor.withValues(alpha: 0.1),
                        // ),
                        Expanded(
                          child: _StatColumn(
                            value: state.capacity.toString(),
                            label: 'Total \n Capacity',
                          ),
                        ),
                        // VerticalDivider(
                        //   width: 1,
                        //   color: AppColors.primaryColor.withValues(alpha: 0.1),
                        // ),
                        Expanded(
                          child: _StatColumn(
                            value: '${state.schoolFte.toStringAsFixed(0)}%',
                            label: 'Full time \n Equivalent',
                            showTrend: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),

                  // ── Breakdown bars (shared CustomStatBarCard) ─────────────────
                  CustomStatBarCard(
                    title: 'Enrolled Students',
                    number: state.enrolledCount.toString(),
                    fullWidthBar: true,
                    embedded: true,
                    titleFontSize: 14,
                    onHeaderTap: () {
                      // context.push(ClassroomOverviewScreen.routeName);
                    },
                    onLegendTap: (label, filterValue) {
                      final normalized = label.trim().toLowerCase();
                      String filter = 'ACTIVE';
                      if (normalized.startsWith('active')) {
                        filter = 'ACTIVE';
                      } else if (normalized.startsWith('upcoming')) {
                        filter = 'UPCOMING';
                      }
                      debugPrint(
                        '[EnrollmentCard] Navigating to Student Attendance: '
                        'filter=$filter, route=${StudentAttendanceTabbedView.routeName}',
                      );
                      context.push(
                        StudentAttendanceTabbedView.routeName,
                        extra: {'filter': filter, 'hasBackButton': true},
                      );
                    },
                    items: _percentItems(
                      total: state.enrolledCount,
                      raw: [
                        _Seg(
                          'Active',
                          state.activeCount,
                          AppColors.lightBlueProgressBar,
                        ),
                        _Seg(
                          'Upcoming',
                          state.upcomingCount,
                          AppColors.mustardProgressBar,
                        ),
                      ],
                    ),
                  ),
                  Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),
                  CustomStatBarCard(
                    title: 'Expected Students',
                    number: state.studentExpected.toString(),
                    fullWidthBar: true,
                    embedded: true,
                    titleFontSize: 14,
                    onHeaderTap: () {
                      // context.push(
                      // StudentAttendanceTabbedView.routeName,
                      // extra: {'filter': 'Expected'},
                      // );
                    },
                    onLegendTap: (label, filterValue) {
                      final normalized = label.trim().toLowerCase();
                      String filter = 'Expected';
                      if (normalized.startsWith('signed-in')) {
                        filter = 'Present';
                      } else if (normalized.startsWith('signed-out')) {
                        filter = 'Signed Out';
                      } else if (normalized.startsWith('absent')) {
                        filter = 'Absent';
                      } else if (normalized.startsWith('not')) {
                        filter = 'Not Marked';
                      }
                      debugPrint(
                        '[EnrollmentCard] Navigating to Student Attendance: '
                        'filter=$filter, label=$label, route=${StudentAttendanceTabbedView.routeName}',
                      );
                      context.push(
                        StudentAttendanceTabbedView.routeName,
                        extra: {'filter': filter, 'hasBackButton': true},
                      );
                    },
                    items: _percentItems(
                      total: state.studentExpected,
                      raw: [
                        _Seg(
                          'Signed-in',
                          state.studentPresent,
                          AppColors.colorBox,
                        ),
                        _Seg(
                          'Absent',
                          state.studentAbsent,
                          AppColors.colorBox2,
                        ),
                        _Seg(
                          'Signed-out',
                          state.studentSignOut,
                          _signedOutColor,
                        ),
                        _Seg(
                          'Not Marked',
                          state.studentNotMarked,
                          _notMarkedColor,
                        ),
                      ],
                    ),
                  ),
                  Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),
                  CustomStatBarCard(
                    title: 'Expected Staff',
                    number: state.staffExpected.toString(),
                    fullWidthBar: true,
                    embedded: true,
                    titleFontSize: 14,
                    onHeaderTap: () {
                      // context.push(
                      //   StaffAttendanceTabbedView.routeName,
                      //   extra: {'filter': 'Expected'},
                      // );
                    },
                    onLegendTap: (label, filterValue) {
                      final normalized = label.trim().toLowerCase();
                      String filter = 'Expected';
                      if (normalized.startsWith('signed-in')) {
                        filter = 'Present';
                      } else if (normalized.startsWith('signed-out')) {
                        filter = 'Signed Out';
                      } else if (normalized.startsWith('absent')) {
                        filter = 'Absent';
                      } else if (normalized.startsWith('not')) {
                        filter = 'Not Marked';
                      }
                      context.push(
                        StaffAttendanceTabbedView.routeName,
                        extra: {'filter': filter, 'hasBackButton': true},
                      );
                    },
                    items: _percentItems(
                      total: state.staffExpected,
                      raw: [
                        _Seg(
                          'Signed-in',
                          state.staffPresent,
                          AppColors.colorBox,
                        ),
                        _Seg('Absent', state.staffAbsent, AppColors.colorBox2),
                        _Seg('Signed-out', state.staffSignOut, _signedOutColor),
                        _Seg(
                          'Not Marked',
                          state.staffNotMarked,
                          _notMarkedColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A single capacity stat (big value + wrapping label) in the summary row.
/// When [showTrend] is set, a small "5% vs last month" line is shown beneath
/// the label.
class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.value,
    required this.label,
    this.showTrend = false,
  });

  final String value;
  final String label;
  final bool showTrend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.themeColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        // No ellipsis — the label wraps so it stays fully readable.
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (showTrend) ...[
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.trending_up, size: 12, color: AppColors.successColor),
              SizedBox(width: 3),
              Flexible(
                child: Text(
                  '0% vs last month',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.successColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A premium, production-grade shimmer loader matching the exact visual structure
/// and spacing of the EnrollmentCard to ensure zero layout shift.
class _EnrollmentCardShimmer extends StatelessWidget {
  const _EnrollmentCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 20,
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 20,
                  width: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Three stat columns
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _StatColumnShimmer(label: 'Total Classrooms')),
                Expanded(child: _StatColumnShimmer(label: 'Total Capacity')),
                Expanded(
                  child: _StatColumnShimmer(
                    label: 'Full time Equivalent',
                    showTrend: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),
            const SizedBox(height: 16),

            // Three CustomStatBarCard progress shimmers matching legend rows
            const _StatBarShimmer(
              title: 'Enrolled Students',
              legendRowsCount: 1,
            ),
            Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),
            const _StatBarShimmer(
              title: 'Expected Students',
              legendRowsCount: 2,
            ),
            Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),
            const _StatBarShimmer(title: 'Expected Staff', legendRowsCount: 2),
          ],
        ),
      ),
    );
  }
}

/// Stat column shimmer mirroring spacing and height of real column.
class _StatColumnShimmer extends StatelessWidget {
  const _StatColumnShimmer({required this.label, this.showTrend = false});

  final String label;
  final bool showTrend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 24,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.transparent, // Layout identical to real text
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (showTrend) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 12,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Stat bar shimmer mirroring the progress bar and exact legend lines count.
class _StatBarShimmer extends StatelessWidget {
  const _StatBarShimmer({required this.title, required this.legendRowsCount});

  final String title;
  final int legendRowsCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.transparent,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              height: 22,
              width: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Container(
            height: 20,
            width: double.infinity,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: List.generate(
            legendRowsCount,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        height: 14,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        height: 14,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
