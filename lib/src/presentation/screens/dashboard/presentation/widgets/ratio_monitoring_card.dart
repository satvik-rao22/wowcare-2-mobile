import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../../core/common/widgets/gradient_toggle_button.dart';
import '../../../../../core/res/colors.dart';
import '../../../../../core/res/media_res.dart';
import '../../../../../core/util/color_utils.dart';

class RatioMonitoringCard extends StatefulWidget {
  const RatioMonitoringCard({super.key, this.isDashboard = true});

  final bool isDashboard;

  @override
  State<RatioMonitoringCard> createState() => RatioMonitoringCardState();
}

class RatioMonitoringCardState extends State<RatioMonitoringCard> {
  static const double cellHeightRow = 50;
  DateTime _selectedRatioMonitoringDate = DateTime.now();
  bool _showAllClassrooms = false;
  static const int _initialDisplayCount = 7;
  bool _minimized = false;

  // Dummy data
  final List<Map<String, dynamic>> _dummyClassrooms = [
    {'name': 'Room A', 'students': 12, 'staff': 2, 'isRatioGood': true},
    {'name': 'Room B', 'students': 15, 'staff': 1, 'isRatioGood': false},
    {'name': 'Room C', 'students': 20, 'staff': 3, 'isRatioGood': true},
    {'name': 'Room D', 'students': 10, 'staff': 1, 'isRatioGood': false},
    {'name': 'Room E', 'students': 18, 'staff': 2, 'isRatioGood': true},
  ];

  _buildRatioMonitoringDateNavigator() {
    final formattedDate = DateFormat(
      'EEE, MMM d',
    ).format(_selectedRatioMonitoringDate);

    return Text(
      formattedDate,
      style: const TextStyle(
        color: AppColors.primaryColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedClassrooms = (_showAllClassrooms || !widget.isDashboard)
        ? _dummyClassrooms
        : _dummyClassrooms.take(_initialDisplayCount).toList();

    final hasMoreToShow = _dummyClassrooms.length > _initialDisplayCount;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorderColor),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.cardColor,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ratio Monitoring',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    _buildRatioMonitoringDateNavigator(),
                    const SizedBox(width: 8),
                    GradientToggleButton(
                      minimized: _minimized,
                      onTap: () {
                        setState(() {
                          _minimized = !_minimized;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!_minimized) ...[
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
                ...displayedClassrooms.map(
                  (room) => _buildDataRow(
                    room['name'],
                    room['students'],
                    room['staff'],
                    room['isRatioGood'],
                  ),
                ),
              ],
            ),
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
                        (_showAllClassrooms) ? 'Show Less' : 'Show More',
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
        ],
      ),
    );
  }

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

  TableRow _buildDataRow(
    String name,
    int students,
    int staff,
    bool isRatioGood,
  ) {
    Color badgeColor = ColorUtils.getColorFromName(name);
    String code = name.isNotEmpty ? name[0].toUpperCase() : "?";

    return TableRow(
      children: [
        Container(
          height: cellHeightRow,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      code,
                      style: const TextStyle(
                        color: AppColors.cardColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
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
        Container(
          height: cellHeightRow,
          color: const Color.fromRGBO(234, 240, 253, 1),
          child: Center(
            child: Text(
              students.toString(),
              style: const TextStyle(
                fontSize: 14.0,
                color: Color.fromRGBO(87, 51, 83, 1),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Container(
          height: cellHeightRow,
          color: const Color.fromRGBO(234, 251, 255, 1),
          child: Center(
            child: Text(
              staff.toString(),
              style: const TextStyle(
                fontSize: 14.0,
                color: Color.fromRGBO(87, 51, 83, 1),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Container(
          height: cellHeightRow,
          color: const Color.fromRGBO(255, 245, 234, 1),
          child: Center(
            child: isRatioGood
                ? SvgPicture.asset(MediaRes.thumbUp)
                : SvgPicture.asset(MediaRes.thumbDown),
          ),
        ),
      ],
    );
  }
}
