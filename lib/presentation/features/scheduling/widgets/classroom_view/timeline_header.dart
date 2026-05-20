import 'package:flutter/material.dart';

class TimelineHeader extends StatelessWidget {
  final ScrollController controller;
  final List<String> timeLabels;
  final List<Color> topSummaryColors;
  final String title;
  final String subtitle;

  const TimelineHeader({
    super.key,
    required this.controller,
    required this.timeLabels,
    required this.topSummaryColors,
    required this.title,
    this.subtitle = 'Class Schedule',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF4B2E4C).withOpacity(0.12),
                  child: Text(
                    title.isNotEmpty ? title[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4B2E4C),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: controller,
            child: _buildHeaderRight(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRight() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(timeLabels.length, (i) {
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
                        color: topSummaryColors[i],
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
            children: timeLabels.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SizedBox(
                  width: 30,
                  child: Text(
                    e,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
