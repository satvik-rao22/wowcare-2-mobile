import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';

// ---------------------------------------------------------------------------
// Local model — mirrors AvailableCount from the reference project.
// ---------------------------------------------------------------------------
class _AvailableCount {
  const _AvailableCount({
    required this.roomId,
    required this.roomName,
    required this.firstShiftCount,
    required this.secondShiftCount,
  });

  final String roomId;
  final String roomName;
  final int firstShiftCount;
  final int secondShiftCount;
}

// ---------------------------------------------------------------------------
// Mock data — realistic classroom names with morning / afternoon availability.
// ---------------------------------------------------------------------------
const List<_AvailableCount> _mockData = [
  _AvailableCount(
      roomId: '1',
      roomName: 'Bluebell Room',
      firstShiftCount: 3,
      secondShiftCount: 2),
  _AvailableCount(
      roomId: '2',
      roomName: 'Daisy Room',
      firstShiftCount: 0,
      secondShiftCount: 1),
  _AvailableCount(
      roomId: '3',
      roomName: 'Maple Room',
      firstShiftCount: 5,
      secondShiftCount: 4),
  _AvailableCount(
      roomId: '4',
      roomName: 'Sunflower Room',
      firstShiftCount: 2,
      secondShiftCount: -1),
  _AvailableCount(
      roomId: '5',
      roomName: 'Oak Room',
      firstShiftCount: 1,
      secondShiftCount: 0),
  _AvailableCount(
      roomId: '6',
      roomName: 'Willow Room',
      firstShiftCount: 4,
      secondShiftCount: 3),
  _AvailableCount(
      roomId: '7',
      roomName: 'Rosebud Room',
      firstShiftCount: 0,
      secondShiftCount: 2),
  _AvailableCount(
      roomId: '8',
      roomName: 'Cedar Room',
      firstShiftCount: 3,
      secondShiftCount: -2),
  _AvailableCount(
      roomId: '9',
      roomName: 'Jasmine Room',
      firstShiftCount: 6,
      secondShiftCount: 5),
];

// ---------------------------------------------------------------------------
// Inline colour helper — deterministic colour from room name.
// Replaces ColorUtils.getColorFromName from the reference project.
// ---------------------------------------------------------------------------
Color _colorFromName(String name) {
  final palette = AppColors.profileAvatarColors;
  if (name.isEmpty) return palette.first;
  final index = name.codeUnitAt(0) % palette.length;
  return palette[index];
}

// ---------------------------------------------------------------------------
// Inline initials helper — replaces StringUtils.getInitials.
// ---------------------------------------------------------------------------
String _initialsFromName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first)
      .toUpperCase();
}

// ---------------------------------------------------------------------------
// AvailabilityCard
// ---------------------------------------------------------------------------

/// Dashboard card that shows morning / afternoon seat availability per
/// classroom, with date navigation and a collapse toggle.
///
/// UI-only (static mock data). No state management, no API calls.
class AvailabilityCard extends StatefulWidget {
  const AvailabilityCard({
    super.key,
    this.isDashboard = true,
  });

  /// When [true] the list is initially capped at [_initialDisplayCount] rows
  /// with a Show More / Show Less footer, matching the dashboard usage.
  final bool isDashboard;

  @override
  State<AvailabilityCard> createState() => _AvailabilityCardState();
}

class _AvailabilityCardState extends State<AvailabilityCard> {
  static const double cellHeightRow = 48;
  static const int _initialDisplayCount = 7;

  DateTime _selectedAvailabilityDate = DateTime.now();
  bool _showAllClassrooms = false;
  bool _minimized = false;

  // -------------------------------------------------------------------------
  // Date navigator
  // -------------------------------------------------------------------------

  void _changeDate(int days) {
    setState(() {
      _selectedAvailabilityDate =
          _selectedAvailabilityDate.add(Duration(days: days));
    });
  }

  Widget _buildAvailabilityDateNavigator() {
    final formattedDate =
        DateFormat('EEE, MMM d').format(_selectedAvailabilityDate);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Previous day
        Material(
          child: InkWell(
            onTap: () => _changeDate(-1),
            borderRadius: BorderRadius.circular(100),
            splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Text(
          formattedDate,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        // Calendar icon — opens nothing in UI-only port
        Material(
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(100),
            splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: SvgPicture.asset(MediaRes.calender_icon),
            ),
          ),
        ),
        // Next day
        Material(
          child: InkWell(
            onTap: () => _changeDate(1),
            borderRadius: BorderRadius.circular(100),
            splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorderColor),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.cardColor,
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 0, 8),
            child: DashboardCardHeader(
              title: 'Availability',
              showRedirect: true,
              onRedirect: () {},
              minimized: _minimized,
              onToggle: () {
                setState(() {
                  _minimized = !_minimized;
                });
              },
              trailing: _buildAvailabilityDateNavigator(),
            ),
          ),

          /// Collapsible body
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _minimized
                ? const SizedBox.shrink()
                : _buildTable(_mockData),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Table
  // -------------------------------------------------------------------------

  Widget _buildTable(List<_AvailableCount> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No classroom data available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final sortedData = _getSortedData(data);

    final displayedClassrooms = (_showAllClassrooms || !widget.isDashboard)
        ? sortedData
        : sortedData.take(_initialDisplayCount).toList();

    final hasMoreToShow = sortedData.length > _initialDisplayCount;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.6),
              1: FlexColumnWidth(0.8),
              2: FlexColumnWidth(0.8),
            },
            border: TableBorder.symmetric(
              inside: BorderSide(
                color: AppColors.primaryColor.withValues(alpha: 0.05),
              ),
            ),
            children: [
              _buildHeaderRow(),
              ...List.generate(
                displayedClassrooms.length,
                (index) => _buildDataRow(
                  displayedClassrooms[index],
                  isLast: index == displayedClassrooms.length - 1 &&
                      (!hasMoreToShow || !widget.isDashboard),
                ),
              ),
            ],
          ),
        ),
        // Show More / Show Less footer
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
    );
  }

  // -------------------------------------------------------------------------
  // Header row
  // -------------------------------------------------------------------------

  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      children: [
        _buildHeaderCell(
          mainText: 'Classroom',
          backgroundColor: const Color.fromRGBO(249, 245, 250, 1),
        ),
        _buildHeaderCell(
          mainText: 'Morning',
          backgroundColor: const Color.fromRGBO(249, 241, 255, 1),
        ),
        _buildHeaderCell(
          mainText: 'Afternoon',
          backgroundColor: const Color.fromRGBO(249, 241, 255, 1),
        ),
      ],
    );
  }

  Widget _buildHeaderCell({
    required String mainText,
    required Color backgroundColor,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(color: backgroundColor),
      child: Column(
        children: [
          Expanded(child: Container()),
          Text(
            mainText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color.fromRGBO(87, 51, 83, 1),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Data row
  // -------------------------------------------------------------------------

  TableRow _buildDataRow(_AvailableCount item, {bool isLast = false}) {
    return TableRow(
      children: [
        // Classroom name cell — navigation removed (empty onTap)
        GestureDetector(
          onTap: () {},
          child: Container(
            height: cellHeightRow,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  _buildClassroomAvatar(item.roomName),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Tooltip(
                      message: item.roomName,
                      preferBelow: false,
                      child: Text(
                        item.roomName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color.fromRGBO(87, 51, 83, 1),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Morning shift count cell
        Container(
          height: cellHeightRow,
          color: const Color.fromRGBO(249, 241, 255, 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.firstShiftCount.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getCountColor(item.firstShiftCount),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Afternoon shift count cell
        Container(
          height: cellHeightRow,
          decoration: BoxDecoration(
            color: const Color.fromRGBO(249, 241, 255, 1),
            borderRadius: isLast
                ? const BorderRadius.only(bottomRight: Radius.circular(8))
                : BorderRadius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.secondShiftCount.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getCountColor(item.secondShiftCount),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Classroom avatar — inline equivalent of DocumentImageWidget / ColorUtils
  // -------------------------------------------------------------------------

  Widget _buildClassroomAvatar(String roomName) {
    final String initials = _initialsFromName(roomName);
    final Color color = _colorFromName(roomName);

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.8),
      radius: 16,
      child: Text(
        initials,
        style: TextStyle(
          color: color == Colors.white ? AppColors.primaryColor : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Sorting helper — numeric room names first, then alphabetic
  // -------------------------------------------------------------------------

  List<_AvailableCount> _getSortedData(List<_AvailableCount> data) {
    final numericRooms = <_AvailableCount>[];
    final alphaRooms = <_AvailableCount>[];

    for (final item in data) {
      final firstChar =
          item.roomName.trim().isNotEmpty ? item.roomName.trim()[0] : '';
      if (RegExp(r'^\d').hasMatch(firstChar)) {
        numericRooms.add(item);
      } else {
        alphaRooms.add(item);
      }
    }

    numericRooms.sort(
        (a, b) => a.roomName.toLowerCase().compareTo(b.roomName.toLowerCase()));
    alphaRooms.sort(
        (a, b) => a.roomName.toLowerCase().compareTo(b.roomName.toLowerCase()));

    return [...numericRooms, ...alphaRooms];
  }

  // -------------------------------------------------------------------------
  // Count colour — red for negative, teal for non-negative
  // -------------------------------------------------------------------------

  Color _getCountColor(int count) {
    if (count < 0) return Colors.red;
    return Colors.teal;
  }
}
