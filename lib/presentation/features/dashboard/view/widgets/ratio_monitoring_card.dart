import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

// ---------------------------------------------------------------------------
// Local mock model — replaces RoomDataEntity; no external imports needed.
// ---------------------------------------------------------------------------

/// Minimal classroom data shape used by [RatioMonitoringCard].
class _MockRoom {
  const _MockRoom({
    required this.name,
    required this.checkedInStudent,
    required this.checkedInStaff,
    required this.isRatioGood,
  });

  final String name;
  final int checkedInStudent;
  final int checkedInStaff;

  /// `true` when the current student : staff ratio meets the required ratio.
  final bool isRatioGood;
}

// ---------------------------------------------------------------------------
// Realistic hardcoded mock data — 9 classrooms so "Show More / Show Less"
// toggle is exercised (initial display limit = 7).
// ---------------------------------------------------------------------------
const List<_MockRoom> _mockClassrooms = [
  _MockRoom(name: 'Infant - A', checkedInStudent: 4, checkedInStaff: 2, isRatioGood: true),
  _MockRoom(name: 'Infant - B', checkedInStudent: 5, checkedInStaff: 2, isRatioGood: false),
  _MockRoom(name: 'Toddler - Blue', checkedInStudent: 9, checkedInStaff: 2, isRatioGood: true),
  _MockRoom(name: 'Toddler - Green', checkedInStudent: 10, checkedInStaff: 2, isRatioGood: false),
  _MockRoom(name: 'Preschool - AM', checkedInStudent: 14, checkedInStaff: 2, isRatioGood: true),
  _MockRoom(name: 'Preschool - PM', checkedInStudent: 12, checkedInStaff: 2, isRatioGood: true),
  _MockRoom(name: 'Pre-K Stars', checkedInStudent: 16, checkedInStaff: 2, isRatioGood: true),
  _MockRoom(name: 'School Age', checkedInStudent: 18, checkedInStaff: 2, isRatioGood: false),
  _MockRoom(name: 'Mixed Age', checkedInStudent: 8, checkedInStaff: 2, isRatioGood: true),
];

// ---------------------------------------------------------------------------
// RatioMonitoringCard
// ---------------------------------------------------------------------------

/// Dashboard card that displays classroom student-to-staff ratios.
///
/// UI-only widget — all data is hardcoded mock data.
/// Collapse/expand and "Show More / Show Less" are the only live states.
class RatioMonitoringCard extends StatefulWidget {
  const RatioMonitoringCard({
    super.key,
    this.isDashboard = true,
  });

  /// When `true` the card limits visible classrooms to [_initialDisplayCount]
  /// and shows a "Show More" toggle; pass `false` for a full-page view.
  final bool isDashboard;

  @override
  State<RatioMonitoringCard> createState() => _RatioMonitoringCardState();
}

class _RatioMonitoringCardState extends State<RatioMonitoringCard> {
  static const double cellHeightRow = 50;
  static const int _initialDisplayCount = 7;

  /// Date shown in the header navigator (static display, navigation commented
  /// out in source).
  final DateTime _selectedRatioMonitoringDate = DateTime.now();

  bool _showAllClassrooms = false;
  bool _minimized = false;

  // ---------------------------------------------------------------------------
  // Header date navigator
  // ---------------------------------------------------------------------------

  Widget _buildRatioMonitoringDateNavigator() {
    final formattedDate =
        DateFormat('EEE, MMM d').format(_selectedRatioMonitoringDate);

    // Arrow buttons were commented out in the source — kept as comments.
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
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
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
  // Table empty row (shown when classrooms list is empty)
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
  // Data row helpers
  // ---------------------------------------------------------------------------

  TableRow _buildDataRow(_MockRoom room) {
    return TableRow(
      children: [
        // ── Classroom cell ──────────────────────────────────────────────────
        GestureDetector(
          onTap: () {}, // Navigation removed; kept for visual affordance.
          child: Container(
            height: cellHeightRow,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Shared profile widget; UI-only, so profile/attendance API
                  // lookups are disabled — it renders initials from [name].
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
          onTap: () {}, // Navigation to student attendance removed.
          child: Container(
            height: cellHeightRow,
            color: const Color.fromRGBO(234, 240, 253, 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
              child: Text(
                room.checkedInStudent.toString(),
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
          onTap: () {}, // Navigation to staff attendance removed.
          child: Container(
            height: cellHeightRow,
            color: const Color.fromRGBO(234, 251, 255, 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
              child: Text(
                room.checkedInStaff.toString(),
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
    final classrooms = _mockClassrooms;

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
          // ── Card header ───────────────────────────────────────────────────
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

          // ── Card body (hidden when minimized) ─────────────────────────────
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

                // ── Show More / Show Less toggle ──────────────────────────
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
                        color: AppColors.primaryColor.withValues(alpha: 0.03),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _showAllClassrooms ? 'Show Less' : 'Show More',
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
  }
}
