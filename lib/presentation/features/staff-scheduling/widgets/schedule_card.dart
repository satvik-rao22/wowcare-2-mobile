import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../shared/common/widgets/app_text_styles.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';

class ScheduleCard extends StatefulWidget {
  const ScheduleCard({super.key});

  @override
  State<ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<ScheduleCard> {
  String? selectedClassroom;
  String? selectedPublishStatus;
  @override
  Widget build(BuildContext context) {
    return Column(children: [_staffScheduleCard()]);
  }

  /// 🔹 Schedule Card
  Widget _staffScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Dropdown Row
          Row(
            children: [
              Expanded(
                child: CustomDropdown(
                  // label: "Select Classroom",
                  hintText: "Select Classroom",
                  items: const ["Class A", "Class B", "Class C"],
                  selectedItem: selectedClassroom,
                  onSelect: (value) {
                    setState(() {
                      selectedClassroom = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomDropdown(
                  // label: "Publish",
                  hintText: "Publish",
                  items: const ["Published", "Not Published"],
                  selectedItem: selectedPublishStatus,
                  onSelect: (value) {
                    setState(() {
                      selectedPublishStatus = value;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// 🔹 Status Section (Responsive)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // ✅ 3 items per row
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3, // controls width/height ratio
            ),
            itemBuilder: (context, index) {
              const items = [
                {"icon": MediaRes.availableHoursIcon, "label": "Available"},
                {"icon": MediaRes.scheduledHoursIcon, "label": "Scheduled"},
                {"icon": MediaRes.notPublishedIcon, "label": "Not Published"},
                {"icon": MediaRes.publishedIcon, "label": "Published"},
                {"icon": MediaRes.alertTriangleIcon, "label": "Under Ratio"},
                {"icon": MediaRes.greenCheckCircleIcon, "label": "In Ratio"},
              ];

              return StatusItem(
                iconPath: items[index]["icon"] as String,
                label: items[index]["label"] as String,
              );
            },
          ),
        ],
      ),
    );
  }
}

class StatusItem extends StatelessWidget {
  final String iconPath;
  final String label;

  const StatusItem({super.key, required this.iconPath, required this.label});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            /// Icon (fixed size)
            SizedBox(
              width: 30,
              height: 30,
              child: SvgPicture.asset(iconPath, fit: BoxFit.contain),
            ),

            const SizedBox(width: 6),

            /// Text (takes remaining space safely)
            Expanded(
              child: AppText.body(
                label,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
