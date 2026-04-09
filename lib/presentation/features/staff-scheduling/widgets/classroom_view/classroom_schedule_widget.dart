import 'package:flutter/material.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../domain/features/staff_scheduling/entities/schedule_entry.dart';
import 'legend_widget.dart';
import 'staff_schedule_row.dart';
import 'timeline_header.dart';

class ClassroomScheduleWidget extends StatefulWidget {
  final List<ScheduleEntryEntity> entries;

  const ClassroomScheduleWidget({super.key, required this.entries});

  @override
  State<ClassroomScheduleWidget> createState() =>
      _ClassroomScheduleWidgetState();
}

class _ClassroomScheduleWidgetState extends State<ClassroomScheduleWidget> {
  late final ScrollController _timelineController;

  final List<String> _timeLabels = [
    '1:00 AM',
    '12:00 PM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
    '06:00 PM',
  ];

  final List<Color> _topSummaryColors = [
    AppColors.colorBox,
    AppColors.colorBox,
    AppColors.colorBox,
    AppColors.colorBox,
    AppColors.colorBox2,
    AppColors.colorBox2,
    AppColors.colorBox2,
    AppColors.colorBox3,
  ];

  @override
  void initState() {
    super.initState();
    _timelineController = ScrollController();
  }

  @override
  void dispose() {
    _timelineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const LegendWidget(),
          const Divider(height: 1),
          Column(
            children: [
              TimelineHeader(
                controller: _timelineController,
                timeLabels: _timeLabels,
                topSummaryColors: _topSummaryColors,
              ),
              const Divider(height: 1),
              ...widget.entries.map((entry) {
                return StaffScheduleRow(
                  entry: entry,
                  controller: _timelineController,
                  timeLabels: _timeLabels,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
