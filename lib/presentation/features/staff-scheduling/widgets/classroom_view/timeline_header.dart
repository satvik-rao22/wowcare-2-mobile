import 'package:flutter/material.dart';

class TimelineHeader extends StatelessWidget {
  final ScrollController controller;
  final List<String> timeLabels;
  final List<Color> topSummaryColors;

  const TimelineHeader({
    super.key,
    required this.controller,
    required this.timeLabels,
    required this.topSummaryColors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 160,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Class Schedule',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
