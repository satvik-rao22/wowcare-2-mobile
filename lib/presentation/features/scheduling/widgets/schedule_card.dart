import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../shared/common/widgets/app_text_styles.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../cubit/classroom-day-view/classroom_staff_scheduling_cubit.dart';
import '../cubit/classroom-day-view/classroom_staff_scheduling_state.dart';

class ScheduleCard extends StatefulWidget {
  const ScheduleCard({super.key});

  @override
  State<ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<ScheduleCard> {
  String? _selectedClassroomCode;

  List<Map<String, dynamic>> get classroomList {
    final classrooms = context.read<StaffSchedulingCubit>().state;
    if (classrooms is StaffSchedulingLoaded) {
      return classrooms.allClassrooms.map((c) {
        final code = c['classroomCode'] ?? c['code'] ?? '';
        final name = c['classroomName'] ?? c['name'] ?? 'Classroom';
        return {'code': code, 'name': name};
      }).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StaffSchedulingCubit, StaffSchedulingState>(
      builder: (context, state) {
        final loaded = state is StaffSchedulingLoaded ? state : null;
        final selectedClassroomCode = loaded?.selectedClassroom;
        final selectedPublishStatus = loaded?.selectedPublish;

        final selectedClassroomName = selectedClassroomCode == null
            ? null
            : classroomList
                  .firstWhere(
                    (e) => e['code'] == selectedClassroomCode,
                    orElse: () => {},
                  )['name']
                  ?.toString();

        return Column(
          children: [
            _staffScheduleCard(
              selectedClassroomName: selectedClassroomName,
              selectedPublishStatus: selectedPublishStatus,
            ),
          ],
        );
      },
    );
  }

  /// 🔹 Schedule Card
  Widget _staffScheduleCard({
    required String? selectedClassroomName,
    required String? selectedPublishStatus,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 390;
    final horizontalGap = isNarrowScreen ? 8.0 : 12.0;
    final cardPadding = isNarrowScreen ? 12.0 : 16.0;
    final gridSpacing = isNarrowScreen ? 8.0 : 12.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
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
                  hintText: 'Select Classroom',
                  items: classroomList.map((e) => e['name'] as String).toList(),
                  selectedItem: selectedClassroomName,
                  onSelect: (val) {
                    final found = classroomList.firstWhere(
                      (e) => e['name'] == val,
                      orElse: () => {},
                    );
                    setState(() {
                      _selectedClassroomCode = found['code'];
                    });
                    final code = found['code']?.toString();
                    if (code != null && code.isNotEmpty) {
                      context.read<StaffSchedulingCubit>().updateClassroom(
                        code,
                      );
                    }
                  },
                ),
              ),
              SizedBox(width: horizontalGap),
              Expanded(
                child: CustomDropdown(
                  // label: "Publish",
                  hintText: "Publish",
                  items: const ["Published", "Not Published"],
                  selectedItem: selectedPublishStatus,
                  onSelect: (value) {
                    if (value == null) return;
                    context.read<StaffSchedulingCubit>().updatePublish(value);
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: isNarrowScreen ? 14 : 20),

          /// 🔹 Status Section (Responsive)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: gridSpacing,
              crossAxisSpacing: gridSpacing,
              // childAspectRatio: isNarrowScreen ? 3.4 : 3.4,
              childAspectRatio: isNarrowScreen ? 2.6 : 3.0,
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
                isNarrowScreen: isNarrowScreen,
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
  final bool isNarrowScreen;

  const StatusItem({
    super.key,
    required this.iconPath,
    required this.label,
    required this.isNarrowScreen,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconSize = isNarrowScreen ? 18.0 : 20.0;
        final gap = isNarrowScreen ? 6.0 : 8.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: SvgPicture.asset(iconPath, fit: BoxFit.contain),
            ),
            SizedBox(width: gap),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w500,
                      fontSize: isNarrowScreen ? 11 : 13,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
