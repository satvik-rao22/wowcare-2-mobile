import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

/// "Classroom Progress" card — a radar chart comparing this month vs last
/// month across developmental categories for a selected classroom.
///
/// UI-only: classroom list and chart values are hardcoded mock data.
class ClassroomProgressCard extends StatefulWidget {
  const ClassroomProgressCard({super.key});

  @override
  State<ClassroomProgressCard> createState() => _ClassroomProgressCardState();
}

class _ClassroomProgressCardState extends State<ClassroomProgressCard> {
  bool _minimized = false;

  static const List<String> _classrooms = [
    '1-Blue-D',
    '2-Green-D',
    '3-Purple-D',
    '4-Yellow-D',
  ];
  String _selectedClassroom = _classrooms.first;

  static const List<String> _categories = [
    'Decision making',
    'Math/Science',
    'Language',
    'Team Work',
    'Communication',
    'Creativity',
    'Self care',
    'Empathy',
  ];

  static const List<double> _lastMonthValues = [3, 4, 5, 2, 3, 4, 2, 3];
  static const List<double> _thisMonthValues = [4, 2, 5, 3, 5, 3, 4, 4];

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
          DashboardCardHeader(
            title: 'Classroom Progress',
            minimized: _minimized,
            onToggle: () => setState(() => _minimized = !_minimized),
          ),
          if (!_minimized) ...[
            const SizedBox(height: 12),
            // Classroom selector — left-aligned, directly below the heading.
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 170,
                child: CustomDropdown(
                  hintText: 'Classroom',
                  items: _classrooms,
                  selectedItem: _selectedClassroom,
                  isField: false,
                  onSelect: (value) {
                    if (value != null) {
                      setState(() => _selectedClassroom = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(height: 300, child: _buildRadarChart()),
            const SizedBox(height: 12),
            // Legend.
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Legend(color: AppColors.accentColor, label: 'Last Month'),
                SizedBox(width: 24),
                _Legend(color: AppColors.themeColor, label: 'This Month'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRadarChart() {
    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        tickCount: 5,
        titlePositionPercentageOffset: 0.2,
        getTitle: (index, angle) => RadarChartTitle(text: _categories[index]),
        titleTextStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primaryColor,
        ),
        tickBorderData: const BorderSide(width: 1, color: Colors.grey),
        // Hide the numeric tick labels.
        ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
        radarBackgroundColor: Colors.transparent,
        gridBorderData: BorderSide(color: Colors.grey.shade300),
        radarBorderData: BorderSide(color: Colors.grey.shade400),
        dataSets: [
          RadarDataSet(
            dataEntries: _lastMonthValues
                .map((e) => RadarEntry(value: e))
                .toList(),
            borderColor: AppColors.accentColor,
            fillColor: AppColors.accentColor.withValues(alpha: 0.4),
            entryRadius: 0,
            borderWidth: 1.5,
          ),
          RadarDataSet(
            dataEntries: _thisMonthValues
                .map((e) => RadarEntry(value: e))
                .toList(),
            borderColor: AppColors.themeColor,
            fillColor: AppColors.themeColor.withValues(alpha: 0.4),
            entryRadius: 0,
            borderWidth: 1.5,
          ),
        ],
      ),
    );
  }
}

/// Small coloured-dot + label legend entry.
class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.label.copyWith(color: AppColors.primaryColor),
        ),
      ],
    );
  }
}
