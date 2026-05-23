import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_toggle.dart';

/// One classroom's ratio status for the selected day.
class _RoomRatio {
  const _RoomRatio(this.name, {required this.notInRatio});

  final String name;

  /// `true` → "Not in ratio" (alert icon); `false` → "In ratio" (check icon).
  final bool notInRatio;
}

/// Hardcoded mock data — mirrors the reference card's fallback rows.
const List<_RoomRatio> _mockRatios = [
  _RoomRatio('1-Blue-D', notInRatio: true),
  _RoomRatio('2-Green-D', notInRatio: false),
  _RoomRatio('3-Purple-D', notInRatio: false),
  _RoomRatio('4-Yellow-D', notInRatio: true),
  _RoomRatio('5-Green-P', notInRatio: true),
  _RoomRatio('6-Pink-P', notInRatio: false),
  _RoomRatio('7-Yellow-P', notInRatio: true),
  _RoomRatio('8-Blue-P', notInRatio: true),
];

/// Dashboard card listing each classroom's in-ratio / not-in-ratio status for
/// the selected day.
///
/// UI-only: data is hardcoded mock; collapse, date navigation and
/// "Show More / Show Less" are the only live state.
class ClassroomShiftsCard extends StatefulWidget {
  const ClassroomShiftsCard({super.key});

  @override
  State<ClassroomShiftsCard> createState() => _ClassroomShiftsCardState();
}

class _ClassroomShiftsCardState extends State<ClassroomShiftsCard> {
  static const int _initialDisplayCount = 7;

  DateTime _selectedShiftDate = DateTime.now();
  bool _showAllClassrooms = false;
  bool _minimized = false;

  /// Responsive body-text size matching the app's other modules
  /// (e.g. student_tile.dart): 16 on tablet, 14 on phone.
  double get _bodyFontSize =>
      MediaQuery.of(context).size.width > 600 ? 16 : 14;

  void _changeDate(int days) {
    setState(() {
      _selectedShiftDate = _selectedShiftDate.add(Duration(days: days));
    });
  }

  Widget _buildClassroomShiftsDateNavigator() {
    final formattedDate = DateFormat('EEE, MMM d').format(_selectedShiftDate);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
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
          style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: _bodyFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
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

  @override
  Widget build(BuildContext context) {
    final displayRatios = _showAllClassrooms
        ? _mockRatios
        : _mockRatios.take(_initialDisplayCount).toList();
    final hasMoreToShow = _mockRatios.length > _initialDisplayCount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorderColor),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Classroom Shifts',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              DashboardCardToggle(
                minimized: _minimized,
                onTap: () => setState(() => _minimized = !_minimized),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // ── Legend ──────────────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _minimized
                ? const SizedBox.shrink()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            MediaRes.alertTriangleIcon,
                            height: 16,
                            colorFilter: const ColorFilter.mode(
                              Colors.red,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            'Not In Ratio',
                            style: TextStyle(fontSize: _bodyFontSize),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16.0),
                      Row(
                        children: [
                          SvgPicture.asset(
                            MediaRes.greenCheckCircleIcon,
                            height: 16,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            'In Ratio',
                            style: TextStyle(fontSize: _bodyFontSize),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16.0),

          // ── Classroom table ─────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _minimized
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      Table(
                        border: TableBorder(
                          horizontalInside: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1.0,
                          ),
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(1),
                        },
                        children: [
                          TableRow(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'Classroom',
                                  style: TextStyle(
                                    fontSize: _bodyFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildClassroomShiftsDateNavigator(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          ...displayRatios.map(_buildTableRow),
                        ],
                      ),
                      if (hasMoreToShow)
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
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(_RoomRatio ratio) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ratio.name,
                style: const TextStyle(
                  fontSize: 18.0,
                  color: AppColors.primaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Center(
            child: SvgPicture.asset(
              ratio.notInRatio
                  ? MediaRes.alertIcon
                  : MediaRes.greenCheckCircleIcon,
              height: 20,
              colorFilter: ratio.notInRatio
                  ? const ColorFilter.mode(Colors.red, BlendMode.srcIn)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
