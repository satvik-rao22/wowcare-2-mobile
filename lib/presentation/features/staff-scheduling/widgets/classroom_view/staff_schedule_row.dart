import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../app/theme/media_res.dart';
import '../../../../../domain/features/staff_scheduling/entities/schedule_entry.dart';

class StaffScheduleRow extends StatelessWidget {
  final ScheduleEntryEntity entry;
  final ScrollController controller;
  final List<String> timeLabels;

  const StaffScheduleRow({
    super.key,
    required this.entry,
    required this.controller,
    required this.timeLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 160, child: _buildStaffInfo(entry)),
            const VerticalDivider(width: 1),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: controller,
                child: _buildTimelineRow(entry),
              ),
            ),
          ],
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildStaffInfo(ScheduleEntryEntity entry) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(entry.avatarUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SvgPicture.asset(MediaRes.availableHoursIcon),
              const SizedBox(width: 3),
              Text('${entry.scheduledHours}h'),
              const SizedBox(width: 5),
              const VerticalDivider(width: 1, color: AppColors.billingGrey),
              const SizedBox(width: 5),
              SvgPicture.asset(MediaRes.scheduledHoursIcon),
              const SizedBox(width: 3),
              Text(
                '${entry.actualHours}h',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(ScheduleEntryEntity entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(timeLabels.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: entry.slotColors[index],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(timeLabels.length, (index) {
              final color = entry.slotColors[index];
              String text = '';

              if (color == Colors.red) {
                text = timeLabels[index];
              }

              if (index == timeLabels.length - 1) {
                text = timeLabels[index];
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SizedBox(
                  width: 30,
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
