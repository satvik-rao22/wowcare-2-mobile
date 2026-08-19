import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

class EventsCard extends StatefulWidget {
  const EventsCard({super.key});

  @override
  State<EventsCard> createState() => _EventsCardState();
}

class _EventsCardState extends State<EventsCard> {
  bool _minimized = false;

  @override
  Widget build(BuildContext context) {
    return SkeuPanel(
      radius: SkeuRadius.xxl,
      padding: const EdgeInsets.all(12),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardCardHeader(
            title: 'Events',
            showRedirect: true,
            onRedirect: () {},
            minimized: _minimized,
            onToggle: () => setState(() => _minimized = !_minimized),
          ),
          if (!_minimized) ...[
            const SizedBox(height: 16),
            // UI-only: simplified horizontal calendar header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.chevron_left, color: Colors.grey[500]),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        return SizedBox(
                          width: 40,
                          child: Center(
                            child: Text(
                              ['S', 'M', 'T', 'W', 'T', 'F', 'S'][index],
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        );
                      }),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        final bool isSelected = index == 4;
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(125),
                            gradient: isSelected
                                ? AppColors.buildPrimaryGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              (13 + index).toString(),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                Icon(Icons.chevron_right, color: Colors.grey[500]),
              ],
            ),
            const SizedBox(height: 8),
            EventItem(
              date: '17',
              month: 'Nov',
              title: 'Erica’s Birthday',
              borderColor: Colors.orange,
            ),
            EventItem(
              date: '26',
              month: 'Nov',
              title: 'Thanksgiving Party',
              borderColor: Colors.yellow,
            ),
            EventItem(
              date: '30',
              month: 'Nov',
              title: 'Parent Teacher Conference',
              borderColor: Colors.pink,
            ),
          ],
        ],
      ),
    );
  }
}

class EventItem extends StatelessWidget {
  final String date;
  final String month;
  final String title;
  final Color borderColor;

  const EventItem({
    super.key,
    required this.date,
    required this.month,
    required this.title,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(month, style: TextStyle(color: Colors.grey[500])),
                Text(
                  date,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 3, height: 48, color: borderColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          DocumentImageWidget(
            fileUuid: '',
            name: title,
            size: 40,
            fontSize: 16,
            disableProfileLookupFallback: true,
            disableAttendanceStatusLookup: true,
          ),
        ],
      ),
    );
  }
}
