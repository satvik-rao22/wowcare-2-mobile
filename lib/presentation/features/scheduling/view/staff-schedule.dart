import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/common/widgets/custom_scaffold.dart';

class StaffSchedulingScreen extends StatelessWidget {
  const StaffSchedulingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      hasBackButton: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mon Nov 18 - Fri Nov 22',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            /// Filters Row
            Row(
              children: [
                Expanded(
                  child: CustomDropdown(
                    items: const ['Staff 1', 'Staff 2', 'Staff 3'],
                    hintText: 'Select Staff',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomDropdown(
                    items: const ['Publish', 'Unpublish'],
                    hintText: 'Publish',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// Staff Info Card
            _staffCard(),

            const SizedBox(height: 20),

            /// Schedule Table
            _scheduleCard(),
          ],
        ),
      ),
    );
  }

  Widget _staffCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(
                      'https://media.istockphoto.com/id/1337230962/photo/a-young-smiling-doctor-in-blue-uniform-standing-in-front-of-blurred-office-background.jpg?s=612x612&w=0&k=20&c=b4yY82H1y1uYg91bQ6Vd4b83bH9l33eR2kK3M08Y19g=',
                    ), // optional
                  ),

                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      height: 14,
                      width: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Jessica Rhodes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text('Lead Teacher'),
                ],
              ),
              const Spacer(),
              const Text('1-Blue-D'),
            ],
          ),
          const SizedBox(height: 16),
          _infoTile(
            MediaRes.availableHoursIcon,
            'Available Hours',
            '45',
            AppColors.availableHours,
          ),
          const SizedBox(height: 10),
          _infoTile(
            MediaRes.scheduledHoursIcon,
            'Scheduled Hours',
            '35',
            AppColors.scheduledHours,
          ),
          const SizedBox(height: 10),
          _infoTile(
            MediaRes.unScheduledHoursIcon,
            'Unscheduled Hours',
            '10',
            AppColors.unscheduledHours,
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String image, String title, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          /// Left side (icon + title)
          Row(children: [SvgPicture.asset(image, height: 20, width: 20)]),
          const SizedBox(width: 10),
          Text(title),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _scheduleCard() {
    final times = [
      '06:00 AM',
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
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Time Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: times
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(t, style: const TextStyle(fontSize: 12)),
                  ),
                )
                .toList(),
          ),

          const SizedBox(width: 12),

          /// Schedule Block
          Expanded(
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: const [
                  SizedBox(height: 20),
                  Text(
                    '1-Blue-D',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text('07:00 AM - 12:00 PM'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
