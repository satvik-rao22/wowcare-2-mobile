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
  final String classroomName;

  const ClassroomScheduleWidget({
    super.key,
    required this.shifts,
    this.classroomName = 'Class Schedule',
    this.isLoading = false,
  });

  @override
  State<ClassroomScheduleWidget> createState() =>
      _ClassroomScheduleWidgetState();
}

class _ClassroomScheduleWidgetState extends State<ClassroomScheduleWidget> {
  late final ScrollController _timelineController;
  late final List<String> _timeLabels;

  @override
  void initState() {
    super.initState();
    _timelineController = ScrollController();
    _timeLabels = _buildHourlyLabels(startHour: 6, endHourInclusive: 18);
  }

  @override
  void dispose() {
    _timelineController.dispose();
    super.dispose();
  }

  List<String> _buildHourlyLabels({
    required int startHour,
    required int endHourInclusive,
  }) {
    final result = <String>[];
    for (var hour = startHour; hour <= endHourInclusive; hour++) {
      final h12 = ((hour + 11) % 12) + 1;
      final ampm = hour >= 12 ? 'PM' : 'AM';
      result.add('${h12.toString().padLeft(2, '0')}:00 $ampm');
    }
    return result;
  }

  List<Color> _buildTopSummaryColors() {
    if (widget.shifts.isEmpty) {
      return List<Color>.filled(
        _timeLabels.length,
        Colors.grey.withOpacity(0.18),
        growable: false,
      );
    }

    bool slotInAnyShift(String label) {
      final parts = label.split(' ');
      final time = parts.first;
      final ampm = parts.length > 1 ? parts[1] : 'AM';
      final hm = time.split(':');
      var hour = int.tryParse(hm[0]) ?? 0;
      final minute = int.tryParse(hm.length > 1 ? hm[1] : '0') ?? 0;
      if (ampm.toUpperCase() == 'PM' && hour != 12) hour += 12;
      if (ampm.toUpperCase() == 'AM' && hour == 12) hour = 0;
      final slotMinutes = hour * 60 + minute;

      for (final s in widget.shifts) {
        final st = s.startTime.split(':');
        final et = s.endTime.split(':');
        final sMinutes =
            (int.tryParse(st[0]) ?? 0) * 60 + (int.tryParse(st[1]) ?? 0);
        final eMinutes =
            (int.tryParse(et[0]) ?? 0) * 60 + (int.tryParse(et[1]) ?? 0);
        if (slotMinutes >= sMinutes && slotMinutes <= eMinutes) return true;
      }
      return false;
    }

    return List<Color>.generate(_timeLabels.length, (i) {
      final inAny = slotInAnyShift(_timeLabels[i]);
      return inAny
          ? AppColors.themeColor.withOpacity(0.75)
          : Colors.grey.withOpacity(0.18);
    }, growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final topSummaryColors = _buildTopSummaryColors();
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
                  topSummaryColors: topSummaryColors,
                  title: widget.classroomName,
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
