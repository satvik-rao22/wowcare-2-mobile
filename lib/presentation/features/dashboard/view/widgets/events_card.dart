import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import '../../../../../shared/common/widgets/gredient-minimze-button.dart';

class EventsCard extends StatefulWidget {
  const EventsCard({super.key});

  @override
  State<EventsCard> createState() => _EventsCardState();
}

class _EventsCardState extends State<EventsCard> {
  bool _minimized = false;
  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Events',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          colors: AppColors.primaryGradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: const Icon(
                        Icons.arrow_outward_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(254, 241, 195, 1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Coming Soon',
                      style: TextStyle(
                        color: Color.fromRGBO(137, 108, 2, 1),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // minimize the card
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
          const SizedBox(height: 16),

          // UI-only: simplified horizontal calendar header
          if (!_minimized) ...[
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
              imageUrl: 'https://picsum.photos/100',
            ),
            EventItem(
              date: '26',
              month: 'Nov',
              title: 'Thanksgiving Party',
              borderColor: Colors.yellow,
              imageUrl: 'https://picsum.photos/105',
            ),
            EventItem(
              date: '30',
              month: 'Nov',
              title: 'Parent Teacher Conference',
              borderColor: Colors.pink,
              imageUrl: 'https://picsum.photos/104',
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
  final String imageUrl;

  EventItem({
    required this.date,
    required this.month,
    required this.title,
    required this.borderColor,
    required this.imageUrl,
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
          CircleAvatar(radius: 20, backgroundImage: NetworkImage(imageUrl)),
        ],
      ),
    );
  }
}
