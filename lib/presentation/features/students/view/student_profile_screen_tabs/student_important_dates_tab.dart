import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';

class StudentImportantDatesTab extends StatefulWidget {
  const StudentImportantDatesTab({
    required this.scrollController,
    required this.name,
    required this.classroom,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;

  @override
  State<StudentImportantDatesTab> createState() =>
      _StudentImportantDatesTabState();
}

class _StudentImportantDatesTabState extends State<StudentImportantDatesTab> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> dates = {
      'Enroll Date': 'Oct 23, 2025',
      'School Start Date': 'Oct 27, 2025',
      'Current Classroom Start Date': 'Nov 03, 2025',
      'Upcoming Moving Date': 'Nov 17, 2025',
      'School Leaving Date': 'Dec 20, 2025',
    };

    final entries = dates.entries.toList();
    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      child: CustomRefreshIndicator(
        onRefresh: () async {
          // TODO: Add refresh logic to reload important dates
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          controller: widget.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
               // Match staff card styling: card border color and radius 12.
              border: Border.all(color: AppColors.cardBorderColor, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Important Dates',
                      style: AppTextStyles.title,
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: AppColors.buildPrimaryGradient(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.edit,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(entries.length * 2 - 1, (i) {
                  if (i.isOdd) return const SizedBox(height: 16);
                  final idx = i ~/ 2;
                  final e = entries[idx];
                  return _DateRow(
                    label: e.key,
                    text: e.value,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.text});
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final displayText = (text.trim().isEmpty || text.trim().toLowerCase() == 'no cda') ? '-' : text;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: AppTextStyles.value.copyWith(
              color: AppColors.primaryColor.withOpacity(0.5),
              fontSize: 14,
              letterSpacing: 14 * (-3 / 100),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  displayText,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.value.copyWith(
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


















