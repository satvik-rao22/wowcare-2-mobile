import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/domain/features/availability/entities/future_availability.dart';
import 'package:wowcare/presentation/features/availability/cubit/future_availability_cubit.dart';
import 'package:wowcare/presentation/features/availability/view/future_availability_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_error_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

// ---------------------------------------------------------------------------
// UI-layer model — one row in the classroom availability table.
// firstShiftCount  = morning available spots
// secondShiftCount = afternoon available spots
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
// Converts a FutureAvailabilityGrid + selected date into display rows.
//
// The API returns entries with shift=MORNING and shift=AFTERNOON when called
// with shift=ALL (isTwoShifts=true). Each classroom gets one row whose
// firstShiftCount/secondShiftCount map to morning/afternoon availableSpots.
//
// When only FULL_DAY entries exist, both columns show the same value so the
// table remains consistent without UI changes.
// ---------------------------------------------------------------------------
List<_AvailableCount> _buildRows(
  FutureAvailabilityGrid grid,
  DateTime selectedDate,
) {
  // Build a quick lookup: classroomCode -> { morning, afternoon }
  final morning = <String, int>{};
  final afternoon = <String, int>{};

  for (final entry in grid.availability) {
    if (!_isSameDay(entry.date, selectedDate)) continue;
    final code = entry.classroomCode;
    switch (entry.shift) {
      case FutureAvailabilityShift.morning:
        morning[code] = entry.availableSpots;
      case FutureAvailabilityShift.afternoon:
        afternoon[code] = entry.availableSpots;
      case FutureAvailabilityShift.fullDay:
        // FULL_DAY: mirror to both columns so the table always renders.
        morning[code] = entry.availableSpots;
        afternoon[code] = entry.availableSpots;
      case FutureAvailabilityShift.all:
        // "all" is a request-time sentinel, not an entry-level shift value.
        break;
    }
  }

  return grid.classrooms
      .map((c) {
        return _AvailableCount(
          roomId: c.code,
          roomName: c.name,
          firstShiftCount: morning[c.code] ?? 0,
          secondShiftCount: afternoon[c.code] ?? 0,
        );
      })
      .toList(growable: false);
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// ---------------------------------------------------------------------------
// AvailabilityCard
// ---------------------------------------------------------------------------

/// Dashboard card that shows morning / afternoon seat availability per
/// classroom for a selected date. Wired to [FutureAvailabilityCubit].
class AvailabilityCard extends StatefulWidget {
  const AvailabilityCard({super.key, this.isDashboard = true});

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
    final newDate = _selectedAvailabilityDate.add(Duration(days: days));
    setState(() {
      _selectedAvailabilityDate = newDate;
    });
    // ignore: discarded_futures
    context.read<FutureAvailabilityCubit>().load(
      date: newDate,
      isTwoShifts: true,
    );
  }

  Widget _buildAvailabilityDateNavigator() {
    final formattedDate = DateFormat(
      'EEE, MMM d',
    ).format(_selectedAvailabilityDate);

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
        // Calendar icon
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
    return BlocBuilder<FutureAvailabilityCubit, FutureAvailabilityState>(
      buildWhen: (prev, curr) => prev.errorMessage != curr.errorMessage,
      builder: (context, state) {
        return DashboardCardErrorOverlay(
          show: state.errorMessage != null,
          onRetry: () => context.read<FutureAvailabilityCubit>().load(
            date: _selectedAvailabilityDate,
            isTwoShifts: true,
          ),
          child: Container(
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
                    onRedirect: () =>
                        context.go(FutureAvailabilityScreen.routeName),
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
                  child: _minimized ? const SizedBox.shrink() : _buildBody(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Body — driven by cubit state
  // -------------------------------------------------------------------------

  Widget _buildBody() {
    return BlocBuilder<FutureAvailabilityCubit, FutureAvailabilityState>(
      builder: (context, state) {
        // Show shimmer when:
        // (a) first ever load with no data yet, or
        // (b) actively loading/refreshing for a different date than what is
        //     currently displayed — prevents showing stale data on date switch.
        final bool dateMatches =
            state.selectedDate != null &&
            _isSameDay(state.selectedDate!, _selectedAvailabilityDate);

        if (state.grid == null || (state.isRefreshing && !dateMatches)) {
          return AvailabilityCardShimmer();
        }

        // Build display rows from the grid for the selected date.
        // Computed here (inside BlocBuilder) so it only runs on state changes.
        final rows = _buildRows(state.grid!, _selectedAvailabilityDate);
        return _buildTable(rows);
      },
    );
  }

  // -------------------------------------------------------------------------
  // Table
  // -------------------------------------------------------------------------

  Widget _buildTable(List<_AvailableCount> data) {
    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'No classroom data available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
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
                  isLast:
                      index == displayedClassrooms.length - 1 &&
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
        // Classroom name cell
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
                    name: item.roomName,
                    classroomCode: item.roomId,
                    size: 32,
                    fontSize: 12,
                    disableProfileLookupFallback: true,
                    disableAttendanceStatusLookup: true,
                  ),
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
  // Sorting helper — numeric room names first, then alphabetic
  // -------------------------------------------------------------------------

  List<_AvailableCount> _getSortedData(List<_AvailableCount> data) {
    final numericRooms = <_AvailableCount>[];
    final alphaRooms = <_AvailableCount>[];

    for (final item in data) {
      final firstChar = item.roomName.trim().isNotEmpty
          ? item.roomName.trim()[0]
          : '';
      if (RegExp(r'^\d').hasMatch(firstChar)) {
        numericRooms.add(item);
      } else {
        alphaRooms.add(item);
      }
    }

    numericRooms.sort(
      (a, b) => a.roomName.toLowerCase().compareTo(b.roomName.toLowerCase()),
    );
    alphaRooms.sort(
      (a, b) => a.roomName.toLowerCase().compareTo(b.roomName.toLowerCase()),
    );

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
