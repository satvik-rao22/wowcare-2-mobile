import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../shared/common/widgets/gredient-minimze-button.dart';

class ChildsProgressCard extends StatefulWidget {
  const ChildsProgressCard({Key? key}) : super(key: key);

  @override
  State<ChildsProgressCard> createState() => _ChildsProgressCardState();
}

class _ChildsProgressCardState extends State<ChildsProgressCard> {
  final List<String> categories = [
    'Decision making',
    'Math/Science',
    'Language',
    'Team Work',
    'Communication',
    'Creativity',
    'Self care',
    'Empathy',
  ];

  final List<double> lastMonthValues = [3, 4, 5, 2, 3, 4, 2, 3];
  final List<double> thisMonthValues = [4, 2, 5, 3, 5, 3, 4, 4];

  bool _minimized = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.1)),
      ),
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Child\'s Progress',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
            if (!_minimized) ...[
              SizedBox(
                height: 350,
                width: MediaQuery.of(context).size.width * 0.7,
                child: RadarChart(
                  RadarChartData(
                    radarShape: RadarShape.polygon,
                    tickCount: 5,
                    titlePositionPercentageOffset: 0.2,
                    getTitle: (index, angle) {
                      return RadarChartTitle(text: categories[index]);
                    },
                    titleTextStyle: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                    ),
                    tickBorderData: const BorderSide(
                      width: 1,
                      color: Colors.grey,
                    ),
                    // to hide the tick label
                    ticksTextStyle: const TextStyle(
                      color: Colors.transparent,
                      fontSize: 0,
                    ),
                    dataSets: [
                      RadarDataSet(
                        dataEntries: lastMonthValues
                            .map((e) => RadarEntry(value: e))
                            .toList(),
                        borderColor: Colors.blue,
                        fillColor: Colors.amber.withValues(alpha: 0.4),
                        entryRadius: 0,
                        borderWidth: 1.5,
                      ),
                      RadarDataSet(
                        dataEntries: thisMonthValues
                            .map((e) => RadarEntry(value: e))
                            .toList(),
                        borderColor: Colors.blue,
                        fillColor: Colors.blue.withValues(alpha: 0.4),
                        entryRadius: 0,
                        borderWidth: 1.5,
                      ),
                    ],
                    radarBackgroundColor: Colors.transparent,
                    gridBorderData: BorderSide(color: Colors.grey.shade300),
                    radarBorderData: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Legend(color: Colors.blue, label: "This Month"),
                  SizedBox(width: 16),
                  Legend(color: Colors.amber, label: "Last Month"),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class Legend extends StatelessWidget {
  final Color color;
  final String label;

  const Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
