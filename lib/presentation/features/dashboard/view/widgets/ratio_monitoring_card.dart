import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/classroom/entities/ratio_monitoring_classroom.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/ratio_monitoring_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

// ---------------------------------------------------------------------------
// RatioMonitoringCard
// ---------------------------------------------------------------------------

/// Dashboard card that displays live classroom student-to-staff ratios.
///
/// Integrates with [RatioMonitoringCubit] for live data. UI layout is
/// identical to the original design — only the data source changed.
class RatioMonitoringCard extends StatefulWidget {
  const RatioMonitoringCard({
    super.key,
    this.isDashboard = true,
  });

  final bool isDashboard;

  @override
  State<RatioMonitoringCard> createState() => _RatioMonitoringCardState();
}

class _RatioMonitoringCardState extends State<RatioMonitoringCard> {
  static const double cellHeightRow = 50;
  static const int _initialDisplayCount = 7;

  final DateTime _selectedRatioMonitoringDate = DateTime.now();

  bool _showAllClassrooms = false;
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
        await context.read<RatioMonitoringCubit>().loadRatioMonitoring(
              schoolCode: schoolCode,
              isSilent: true,
            );
      } catch (_) {}
    }
  }

  // ---------------------------------------------------------------------------
  // Header date navigator
  // ---------------------------------------------------------------------------

  Widget _buildRatioMonitoringDateNavigator() {
    final formattedDate =
        DateFormat('EEE, MMM d').format(_selectedRatioMonitoringDate);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 2),
        Text(
          formattedDate,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 2),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Table header row
  // ---------------------------------------------------------------------------

  TableRow _buildHeaderRow() {
    return TableRow(
      children: [
        _buildHeaderCell(
          mainText: 'Classroom',
          subText: '',
          backgroundColor: const Color.fromRGBO(249, 245, 250, 1),
        ),
        _buildHeaderCell(
          mainText: 'Students',
          subText: 'Present',
          backgroundColor: const Color.fromRGBO(234, 240, 253, 1),
        ),
        _buildHeaderCell(
          mainText: 'Staff',
          subText: 'Present',
          backgroundColor: const Color.fromRGBO(234, 251, 255, 1),
        ),
        _buildHeaderCell(
          mainText: 'Ratio',
          subText: 'Current',
          backgroundColor: const Color.fromRGBO(255, 245, 234, 1),
        ),
      ],
    );
  }

  Widget _buildHeaderCell({
    required String mainText,
    required String subText,
    required Color backgroundColor,
  }) {
    return Container(
      height: 90,
      decoration: BoxDecoration(color: backgroundColor),
      child: Column(
        children: [
          Expanded(child: Container()),
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
  // Table empty row
  // ---------------------------------------------------------------------------

  TableRow _buildEmptyRow() {
    return TableRow(
      children: [
        SizedBox(height: cellHeightRow),
        SizedBox(height: cellHeightRow),
        SizedBox(height: cellHeightRow),
        SizedBox(height: cellHeightRow),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Data row
  // ---------------------------------------------------------------------------

  TableRow _buildDataRow(RatioMonitoringClassroom room) {
    return TableRow(
      children: [
        // ── Classroom cell ──────────────────────────────────────────────────
        GestureDetector(
          onTap: () {},
          child: Container(
            height: cellHeightRow,
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

        // ── Students Present cell ───────────────────────────────────────────
        GestureDetector(
          onTap: () {},
          child: Container(
            height: cellHeightRow,
            color: const Color.fromRGBO(234, 240, 253, 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
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

        // ── Staff Present cell ──────────────────────────────────────────────
        GestureDetector(
          onTap: () {},
          child: Container(
            height: cellHeightRow,
            color: const Color.fromRGBO(234, 251, 255, 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
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

        // ── Ratio indicator cell ────────────────────────────────────────────
        Container(
          height: cellHeightRow,
          color: const Color.fromRGBO(255, 245, 234, 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
            child: Center(
              child: room.isRatioGood
                  ? SvgPicture.asset(MediaRes.thumbUp)
                  : SvgPicture.asset(MediaRes.thumbDown),
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
      builder: (context, state) {
        // Show shimmer only on first load when there is no cached data.
        // If data is present (silent refresh or error recovery), keep rows visible.
        final showShimmer =
            state.isInitial || (state.isLoading && state.classrooms.isEmpty);

        if (showShimmer) {
          return const _RatioMonitoringCardShimmer();
        }

        final classrooms = state.classrooms;

        final displayedClassrooms =
            (_showAllClassrooms || !widget.isDashboard)
                ? classrooms
                : classrooms.take(_initialDisplayCount).toList();

        final hasMoreToShow = classrooms.length > _initialDisplayCount;

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorderColor),
            borderRadius: BorderRadius.circular(12),
            color: AppColors.cardColor,
          ),
          child: Column(
            children: [
              // ── Card header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                child: DashboardCardHeader(
                  title: 'Ratio Monitoring',
                  minimized: _minimized,
                  onToggle: () {
                    setState(() {
                      _minimized = !_minimized;
                    });
                  },
                  trailing: _buildRatioMonitoringDateNavigator(),
                ),
              ),

              // ── Card body (hidden when minimized) ─────────────────────────
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
                          color: AppColors.primaryColor.withValues(alpha: 0.05),
                        ),
                      ),
                      children: [
                        _buildHeaderRow(),
                        if (displayedClassrooms.isEmpty)
                          _buildEmptyRow()
                        else
                          ...displayedClassrooms.map(_buildDataRow),
                      ],
                    ),

                    // ── Show More / Show Less toggle ──────────────────────
                    if (hasMoreToShow && widget.isDashboard)
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showAllClassrooms = !_showAllClassrooms;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
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
// Shimmer — matches exact card dimensions to prevent layout shift.
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
            // Header row shimmer
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
            // Column header shimmer
            Container(
              height: 90,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            // Data row shimmers
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
