import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../cubit/staff_scheduling_cubit.dart';
import '../model/staff_model.dart';

class ExpandableScheduleCard extends StatefulWidget {
  final String title; // e.g., "Thu Dec 30" or "Thu 30"
  final List<ClassroomSchedule>
  classrooms; // Changed to support multiple classrooms
  final bool isInitiallyExpanded;

  const ExpandableScheduleCard({
    super.key,
    required this.title,
    required this.classrooms,
    this.isInitiallyExpanded = false,
  });

  @override
  State<ExpandableScheduleCard> createState() => _ExpandableScheduleCardState();
}

class _ExpandableScheduleCardState extends State<ExpandableScheduleCard> {
  late bool isExpanded;
  int? activePopupIndex; // Which row's popup is open
  bool? activeIsWarning;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.isInitiallyExpanded;
  }

  void toggleAll() {
    setState(() => isExpanded = !isExpanded);
  }

  void togglePopup(int index, bool isWarning) {
    setState(() {
      if (activePopupIndex == index) {
        activePopupIndex = null;
        activeIsWarning = null;
      } else {
        activePopupIndex = index;
        activeIsWarning = isWarning;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33162831)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Header
              _buildHeader(),

              // All Classroom Rows
              ...widget.classrooms.asMap().entries.map((entry) {
                final index = entry.key;
                final classroom = entry.value;

                return Column(
                  children: [
                    _buildClassroomRow(classroom: classroom, index: index),
                    if (isExpanded && classroom.isExpanded)
                      _buildStaffList(classroom.staffList),
                    const Divider(height: 1, color: Color(0xFFE5E5E5)),
                  ],
                );
              }).toList(),
            ],
          ),

          // Right vertical divider
          Positioned(
            top: 0,
            bottom: 0,
            right:
                140, // Adjust based on your design (distance from right edge)
            child: Container(width: 1, color: const Color(0xFFE5E5E5)),
          ),

          // Popup Overlay
          if (activePopupIndex != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => activePopupIndex = null),
                child: Container(
                  color: Colors.black.withOpacity(0.08),
                  child: Center(
                    child: _buildPopup(
                      widget.classrooms[activePopupIndex!],
                      activeIsWarning ?? false,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: toggleAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(
                    isExpanded ? "Collapse All" : "Expand All",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B2E4C),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B2E4C),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE5E5E5)),
      ],
    );
  }

  Widget _buildClassroomRow({
    required ClassroomSchedule classroom,
    required int index,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Classroom Name + Expand Icon
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  classroom.isExpanded = !classroom.isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Text(
                      classroom.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B2E4C),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      classroom.isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: const Color(0xFF4B2E4C),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Status Icon (Clickable)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: GestureDetector(
              onTap: () => togglePopup(index, classroom.showWarning),
              child: SvgPicture.asset(
                classroom.showWarning
                    ? MediaRes.alertTriangleIcon
                    : MediaRes.greenCheckCircleIcon,
                width: 24,
                height: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffList(List<StaffModel> staffList) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: staffList.map((staff) {
          return Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  children: [
                    // Staff Info
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(staff.image),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    staff.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4B2E4C),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        MediaRes.availableHoursIcon,
                                        height: 18,
                                        width: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "${staff.workedHours}h",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "|",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "${staff.totalHours}h",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Time Slot with Dotted Border
                    SizedBox(
                      width: 132,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        child: DottedBorder(
                          options: RoundedRectDottedBorderOptions(
                            dashPattern: [10, 20],
                            strokeWidth: 2,
                            color: AppColors.themeColor,
                            radius: Radius.circular(10),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              "07:00 AM -\n05:00 PM",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                color: Color(0xFF4B2E4C),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E5E5)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPopup(ClassroomSchedule classroom, bool isWarning) {
    if (!isWarning) {
      return _properRatioPopup(classroom.title);
    } else {
      return _underRatioPopup();
    }
  }

  Widget _properRatioPopup(String title) {
    return Container(
      width: 270,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title (Published)",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          const Text("W-7:00 AM - 5:30 PM", style: TextStyle(fontSize: 14)),
          const SizedBox(height: 6),
          const Text("B-12:30 PM - 1:00 PM", style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _underRatioPopup() {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _timeRow("07:30 AM - 08:00 AM", true),
          const SizedBox(height: 10),
          _timeRow("12:30 PM - 02:00 PM", true),
          const SizedBox(height: 10),
          _timeRow("03:30 PM - 04:30 PM", true),
        ],
      ),
    );
  }

  Widget _timeRow(String time, bool isUnderRatio) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(time, style: const TextStyle(fontSize: 13.5)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: isUnderRatio
                ? const Color(0xFFF38D8D)
                : const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isUnderRatio ? "Under ratio" : "Proper ratio",
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== MODEL ====================

class ClassroomSchedule {
  final String title;
  final bool showWarning;
  final List<StaffModel> staffList;
  bool isExpanded;

  ClassroomSchedule({
    required this.title,
    required this.showWarning,
    required this.staffList,
    this.isExpanded = false,
  });
}
