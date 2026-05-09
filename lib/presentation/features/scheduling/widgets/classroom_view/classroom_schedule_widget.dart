import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../domain/features/staff_scheduling/entities/staff_shift.dart';
import 'legend_widget.dart';
import 'staff_schedule_row.dart';
import 'timeline_header.dart';

class ClassroomScheduleWidget extends StatefulWidget {
  final List<StaffShiftEntity> shifts;
  final bool isLoading;

  const ClassroomScheduleWidget({
    super.key,
    required this.shifts,
    this.isLoading = false,
  });

  @override
  State<ClassroomScheduleWidget> createState() =>
      _ClassroomScheduleWidgetState();
}

class _ClassroomScheduleWidgetState extends State<ClassroomScheduleWidget> {
  late final ScrollController _timelineController;

  final List<String> _timeLabels = [
    '07:00 AM',
    '08:00 AM',
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
    '06:00 PM',
    '07:00 PM',
  ];

  final List<Color> _topSummaryColors = List.generate(
    13,
    (index) => AppColors.colorBox,
  );

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
          if (widget.isLoading)
            _buildShimmerLoader()
          else
            Column(
              children: [
                TimelineHeader(
                  controller: _timelineController,
                  timeLabels: _timeLabels,
                  topSummaryColors: _topSummaryColors,
                ),
                const Divider(height: 1),
                if (widget.shifts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No shifts scheduled for this day'),
                  )
                else
                  ...widget.shifts.map((shift) {
                    return StaffScheduleRow(
                      shift: shift,
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

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(children: List.generate(5, (index) => _buildShimmerRow())),
    );
  }

  Widget _buildShimmerRow() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(width: 140, height: 60, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(child: Container(height: 40, color: Colors.white)),
        ],
      ),
    );
  }
}
