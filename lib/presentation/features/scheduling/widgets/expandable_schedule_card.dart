import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../shared/common/widgets/profile_show_widget.dart';
import '../view/edit-schedule.dart';
import '../model/classroom_schedule_vm.dart';

class ExpandableScheduleCard extends StatefulWidget {
  final String title; // e.g., "Thu Dec 30" or "Thu 30"
  final List<ClassroomScheduleVm>
  classrooms; // Changed to support multiple classrooms
  final Map<String, String> classroomNameMap;
  final bool isInitiallyExpanded;
  final bool isLoading; // ADD THIS

  const ExpandableScheduleCard({
    super.key,
    required this.title,
    required this.classrooms,
    required this.classroomNameMap,
    this.isInitiallyExpanded = false,
    this.isLoading = false, // ADD THIS
  });
  @override
  State<ExpandableScheduleCard> createState() => _ExpandableScheduleCardState();
}

class _ExpandableScheduleCardState extends State<ExpandableScheduleCard> {
  late bool isExpanded;
  int? activePopupIndex; // Which row's popup is open
  bool? activeIsWarning;
  late final Map<String, String> classroomNameMap;

  bool _areAllExpanded() {
    if (widget.classrooms.isEmpty) return false;
    return widget.classrooms.every((classroom) => classroom.isExpanded);
  }

  @override
  void initState() {
    super.initState();
    if (widget.isInitiallyExpanded) {
      for (var classroom in widget.classrooms) {
        classroom.isExpanded = true;
      }
    }
    isExpanded = _areAllExpanded();
  }

  // Returns mapped name, falls back to code if not found
  String _classroomName(String code) {
    return widget.classroomNameMap[code] ?? code;
  }

  @override
  void didUpdateWidget(ExpandableScheduleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isInitiallyExpanded != widget.isInitiallyExpanded) {
      setState(() {
        for (var classroom in widget.classrooms) {
          classroom.isExpanded = widget.isInitiallyExpanded;
        }
        isExpanded = _areAllExpanded();
      });
    }
  }

  void toggleAll() {
    final nextExpanded = !_areAllExpanded();
    setState(() {
      for (var classroom in widget.classrooms) {
        classroom.isExpanded = nextExpanded;
      }
      isExpanded = nextExpanded;
    });
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
      child: widget.isLoading
          ? _buildShimmer()
          : Stack(
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
                          _buildClassroomRow(
                            classroom: classroom,
                            index: index,
                          ),
                          if (classroom.isExpanded) _buildStaffList(classroom),
                          const Divider(height: 1, color: Color(0xFFE5E5E5)),
                        ],
                      );
                    }).toList(),
                  ],
                ),

                // Right vertical divider
                Positioned(
                  top: 10,
                  bottom: 0,
                  right: 140,
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
    return Container(
      color: const Color(0xFFFBF8FC),
      child: Column(
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
                      _areAllExpanded() ? "Collapse All" : "Expand All",
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
      ),
    );
  }

  Widget _buildClassroomRow({
    required ClassroomScheduleVm classroom,
    required int index,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Classroom Name + Expand Icon
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  classroom.isExpanded = !classroom.isExpanded;
                  isExpanded = _areAllExpanded();
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
                      // FIX 1: Always show mapped name, never the raw code
                      _classroomName(classroom.title),
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
          Container(
            width: 56,
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () => togglePopup(index, classroom.showWarning),
              child: SvgPicture.asset(
                classroom.showWarning
                    ? MediaRes.alertTriangleIcon
                    : MediaRes.greenCheckCircleIcon,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffList(ClassroomScheduleVm classroom) {
    final staffList = classroom.staffList;
    // FIX 2: Resolve the name once and reuse throughout this widget
    final resolvedName = _classroomName(classroom.title);

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
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  DocumentImageWidget(
                                    fileUuid: '',
                                    name: staff.name,
                                    size: 32,
                                    fontSize: 14,
                                  ),
                                  if (staff.statusColor != null)
                                    Positioned(
                                      top: -1,
                                      right: -1,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: staff.statusColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        staff.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4B2E4C),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    // FIX 2: Show resolved name, not the raw code
                                    resolvedName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF7A627A),
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
                                        "${_formatHours(staff.availableHours)}h",
                                        style: const TextStyle(
                                          fontFamily: 'Manrope',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                          height: 1.0,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "|",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      const SizedBox(width: 6),
                                      SvgPicture.asset(
                                        MediaRes.scheduledHoursIcon,
                                        height: 13,
                                        width: 13,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "${_formatHours(staff.scheduledHours)}h",
                                        style: const TextStyle(
                                          fontFamily: 'Manrope',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                          height: 1.0,
                                        ),
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
                        child: Builder(
                          builder: (_) {
                            final status = staff.shiftStatus
                                ?.toLowerCase()
                                .trim();

                            final isPublished =
                                status == 'publish' || status == 'published';

                            final child = Container(
                              decoration: BoxDecoration(
                                border: isPublished
                                    ? Border.all(
                                        color: AppColors.themeColor,
                                        width: 2,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              alignment: Alignment.center,
                              child: TextButton(
                                onPressed: () {
                                  final args = <String, dynamic>{
                                    'shiftCode': staff.shiftCode,
                                    'staffName': staff.name,
                                    'classroomName': resolvedName,
                                    'classroom': classroom.classroomCode,
                                    'shift': staff.shift,
                                  };
                                  Navigator.pushNamed(
                                    context,
                                    EditShiftScreen.routeName,
                                    arguments: args,
                                  );
                                },
                                child: Text(
                                  staff.shift,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.4,
                                    color: Color(0xFF4B2E4C),
                                  ),
                                ),
                              ),
                            );

                            if (isPublished) {
                              return child;
                            }

                            return DottedBorder(
                              options: RoundedRectDottedBorderOptions(
                                dashPattern: [10, 20],
                                strokeWidth: 2,
                                color: AppColors.themeColor,
                                radius: Radius.circular(10),
                              ),
                              child: child,
                            );
                          },
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

  Widget _buildPopup(ClassroomScheduleVm classroom, bool isWarning) {
    if (!isWarning) {
      // FIX 3: Pass resolved name to popup, not the raw code
      return _properRatioPopup(
        title: _classroomName(classroom.title),
        classroom: classroom,
      );
    } else {
      return _underRatioPopup(classroom: classroom);
    }
  }

  String _formatHours(double value) {
    // API sends decimals like 3.97; keep up to 2 decimals but hide trailing .0/.00
    final fixed = value.toStringAsFixed(2);
    return fixed.replaceAll(RegExp(r'\.?0+$'), '');
  }

  Widget _properRatioPopup({
    required String title,
    required ClassroomScheduleVm classroom,
  }) {
    final staff = classroom.staffList;
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
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          if (staff.isEmpty)
            const Text("No shifts for this day", style: TextStyle(fontSize: 14))
          else
            ...staff.map((s) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _timeRow('${s.name}: ${s.shift}', false),
              );
            }),
        ],
      ),
    );
  }

  Widget _underRatioPopup({required ClassroomScheduleVm classroom}) {
    final staff = classroom.staffList;
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
          if (staff.isEmpty)
            const Text("No shifts for this day", style: TextStyle(fontSize: 14))
          else
            ...staff.map((s) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _timeRow('${s.name}: ${s.shift}', true),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          /// Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(height: 18, width: 120, color: Colors.white),
                const Spacer(),
                Container(height: 18, width: 80, color: Colors.white),
              ],
            ),
          ),

          const Divider(height: 1),

          ...List.generate(3, (index) {
            return Column(
              children: [
                /// Classroom Row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              height: 16,
                              width: 140,
                              color: Colors.white,
                            ),

                            const SizedBox(width: 10),

                            Container(
                              height: 20,
                              width: 20,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        height: 24,
                        width: 24,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),

                /// Staff List
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: List.generate(2, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 16,
                                    width: double.infinity,
                                    color: Colors.white,
                                  ),

                                  const SizedBox(height: 8),

                                  Container(
                                    height: 12,
                                    width: 100,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            Container(
                              height: 50,
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _timeRow(String time, bool isUnderRatio) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            time,
            style: const TextStyle(fontSize: 13.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
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
