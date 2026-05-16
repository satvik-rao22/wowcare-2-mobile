import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../../shared/common/widgets/gredient-minimze-button.dart';

class ClassroomShiftsCard extends StatefulWidget {
  const ClassroomShiftsCard({super.key});

  @override
  State<ClassroomShiftsCard> createState() => _ClassroomShiftsCardState();
}

class _ClassroomShiftsCardState extends State<ClassroomShiftsCard> {
  DateTime _selectedShiftDate = DateTime.now();

  bool _showAllClassrooms = false;
  bool _minimized = false;

  static const int _initialDisplayCount = 7;

  final List<Map<String, dynamic>> classrooms = [
    {"name": "1-Blue-D", "status": "Not in ratio"},
    {"name": "2-Green-D", "status": "In ratio"},
    {"name": "3-Purple-D", "status": "In ratio"},
    {"name": "4-Yellow-D", "status": "Not in ratio"},
    {"name": "5-Green-P", "status": "In ratio"},
    {"name": "6-Pink-P", "status": "In ratio"},
    {"name": "7-Yellow-P", "status": "In ratio"},
    {"name": "8-Blue-P", "status": "Not in ratio"},
  ];

  Widget _buildClassroomShiftsDateNavigator() {
    final formattedDate = DateFormat('EEE, MMM d').format(_selectedShiftDate);

    void changeDate(int days) {
      setState(() {
        _selectedShiftDate = _selectedShiftDate.add(Duration(days: days));
      });
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => changeDate(-1),
            borderRadius: BorderRadius.circular(100),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Color(0xff6C5CE7),
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Text(
          formattedDate,
          style: const TextStyle(
            color: Color(0xff6C5CE7),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => changeDate(1),
            borderRadius: BorderRadius.circular(100),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Color(0xff6C5CE7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayRatios = (_showAllClassrooms)
        ? classrooms
        : classrooms.take(_initialDisplayCount).toList();

    final hasMoreToShow = classrooms.length > _initialDisplayCount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffE5E7EB)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Classroom Shifts',
                style: TextStyle(
                  color: Color(0xff6C5CE7),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),

              InkWell(
                onTap: () {
                  setState(() {
                    _minimized = !_minimized;
                  });
                },

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

          const SizedBox(height: 16),

          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _minimized
                ? const SizedBox.shrink()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text('Not In Ratio', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      SizedBox(width: 16),
                      Row(
                        children: const [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text('In Ratio', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 16),

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
                            color: Colors.grey.shade300,
                            width: 1.0,
                          ),
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(1),
                        },
                        children: [
                          /// TABLE HEADER
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  'Classroom',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildClassroomShiftsDateNavigator(),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          /// DATA ROWS
                          ...displayRatios.map(
                            (ratio) => _buildTableRow(
                              ratio['name'],
                              ratio['status'] == 'Not in ratio'
                                  ? Colors.red
                                  : Colors.green,
                              ratio['status'] == 'Not in ratio',
                            ),
                          ),
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
                                  (_showAllClassrooms)
                                      ? 'Show Less'
                                      : 'Show More',
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
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String classroom, Color iconColor, bool isWarning) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Text(
            classroom,
            style: TextStyle(fontSize: 18.0, color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Center(
            child: Icon(
              isWarning ? Icons.warning_amber_rounded : Icons.check_circle,
              color: iconColor,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
