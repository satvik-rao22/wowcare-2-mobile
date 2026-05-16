import 'package:flutter/material.dart';

import '../../../../../shared/common/widgets/gredient-minimze-button.dart';

class RatioMonitoringCard extends StatefulWidget {
  const RatioMonitoringCard({super.key, this.isDashboard = true});

  final bool isDashboard;

  @override
  State<RatioMonitoringCard> createState() => _RatioMonitoringCardState();
}

class _RatioMonitoringCardState extends State<RatioMonitoringCard> {
  static const double cellHeightRow = 50;

  bool _showAllClassrooms = false;
  bool _minimized = false;

  static const int _initialDisplayCount = 7;

  final List<Map<String, dynamic>> classrooms = [
    {
      "code": "1B",
      "name": "1-Blue-D",
      "students": 18,
      "staff": 2,
      "ratio": true,
      "color": Colors.blue,
    },
    {
      "code": "2G",
      "name": "2-Green-D",
      "students": 22,
      "staff": 3,
      "ratio": true,
      "color": Colors.green,
    },
    {
      "code": "3P",
      "name": "3-Purple-D",
      "students": 19,
      "staff": 2,
      "ratio": false,
      "color": Colors.purple,
    },
    {
      "code": "4Y",
      "name": "4-Yellow-D",
      "students": 25,
      "staff": 1,
      "ratio": false,
      "color": Colors.orange,
    },
    {
      "code": "5G",
      "name": "5-Green-P",
      "students": 16,
      "staff": 2,
      "ratio": true,
      "color": Colors.green,
    },
    {
      "code": "6P",
      "name": "6-Pink-P",
      "students": 14,
      "staff": 2,
      "ratio": true,
      "color": Colors.pink,
    },
    {
      "code": "7Y",
      "name": "7-Yellow-P",
      "students": 21,
      "staff": 2,
      "ratio": true,
      "color": Colors.amber,
    },
    {
      "code": "8B",
      "name": "8-Blue-P",
      "students": 28,
      "staff": 1,
      "ratio": false,
      "color": Colors.blue,
    },
  ];

  Widget _buildRatioMonitoringDateNavigator() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Thu, May 14',
          style: TextStyle(
            color: Color(0xff6C5CE7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedClassrooms = (_showAllClassrooms || !widget.isDashboard)
        ? classrooms
        : classrooms.take(_initialDisplayCount).toList();

    final hasMoreToShow = classrooms.length > _initialDisplayCount;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffE5E7EB)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
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
                    color: Color(0xff6C5CE7),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    /// STATIC TOGGLE BUTTON
                    InkWell(
                      onTap: () {
                        setState(() {
                          _minimized = !_minimized;
                        });
                      },
                      borderRadius: BorderRadius.circular(100),
                      child: GradientToggleButton(
                        minimized: _minimized,
                        onTap: () {
                          setState(() {
                            _minimized = !_minimized;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!_minimized) ...[
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: _buildRatioMonitoringDateNavigator(),
              ),
            ),
            const SizedBox(width: 8),

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
                      color: const Color(0xff6C5CE7).withOpacity(0.05),
                    ),
                  ),
                  children: [
                    _buildHeaderRow(),

                    ...displayedClassrooms.map(
                      (room) => _buildDataRow(
                        room['code'],
                        room['name'],
                        room['students'],
                        room['staff'],
                        room['ratio'],
                        room['color'],
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
                        color: const Color(0xff6C5CE7).withOpacity(0.03),
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
                              color: Color(0xff6C5CE7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _showAllClassrooms
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: const Color(0xff6C5CE7),
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
          const Spacer(),
          if (subText.isNotEmpty) ...[
            Text(
              mainText,
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
    String code,
    String name,
    int students,
    int staff,
    bool isRatioGood,
    Color badgeColor,
  ) {
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
                    color: badgeColor.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      code,
                      style: const TextStyle(
                        color: Colors.white,
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
            child: Icon(
              isRatioGood
                  ? Icons.thumb_up_alt_rounded
                  : Icons.thumb_down_alt_rounded,
              size: 18,
              color: isRatioGood ? Colors.green : Colors.red,
            ),
          ),
        ),
      ],
    );
  }
}
