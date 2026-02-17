import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class StaffAbsentCardData {
  final String id;
  final String name;
  final String? photoUuid;
  final String roomName;
  final String absentTime;
  final String absentBy;
  final String? note;
  final int staffId;
  final int roomId;
  final int schoolId;
  final String startDate;
  final String endDate;
  final bool hasSignIn;
  final bool expectedToday;
  final String? signInTime;
  final String? signOutTime;

  StaffAbsentCardData({
    required this.id,
    required this.name,
    this.photoUuid,
    required this.roomName,
    required this.absentTime,
    required this.absentBy,
    this.note,
    required this.staffId,
    required this.roomId,
    required this.schoolId,
    required this.startDate,
    required this.endDate,
    this.hasSignIn = false,
    this.expectedToday = true,
    this.signInTime,
    this.signOutTime,
  });
}

class StaffAbsentCard extends StatefulWidget {
  final StaffAbsentCardData staff;
  final int index;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onView;

  const StaffAbsentCard({
    super.key,
    required this.staff,
    required this.index,
    this.isExpanded = false,
    this.onTap,
    this.onView,
  });

  @override
  State<StaffAbsentCard> createState() => _StaffAbsentCardState();
}

class _StaffAbsentCardState extends State<StaffAbsentCard> {
  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final staff = widget.staff;

    final avatarSize = responsive.isTablet ? 52.0 : 44.0;
    final cardPadding = responsive.isTablet 
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
    final spacing = responsive.isTablet ? 16.0 : 14.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: responsive.verticalSpacing / 2),
        padding: cardPadding,
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(responsive.isTablet ? 18 : 16),
          border: Border.all(color: AppColors.cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    DocumentImageWidget(
                      fileUuid: staff.photoUuid ?? '',
                      name: staff.name,
                      size: avatarSize,
                      fontSize: responsive.isTablet ? 18 : 16,
                    ),
                    // Status dot for absent list
                    if (staff.hasSignIn &&
                        (staff.signOutTime == null ||
                            staff.signOutTime!.isEmpty))
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: responsive.isTablet ? 14 : 12,
                          height: responsive.isTablet ? 14 : 12,
                          decoration: BoxDecoration(
                            color: AppColors.successColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: responsive.isTablet ? 2.5 : 2,
                            ),
                          ),
                        ),
                      )
                    else if (staff.expectedToday &&
                        !staff.hasSignIn &&
                        (staff.signOutTime == null ||
                            staff.signOutTime!.isEmpty) &&
                        (staff.signInTime == null ||
                            staff.signInTime!.isEmpty))
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: responsive.isTablet ? 14 : 12,
                          height: responsive.isTablet ? 14 : 12,
                          decoration: BoxDecoration(
                            color: AppColors.errorColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: responsive.isTablet ? 2.5 : 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: AppText.body(
                    staff.name,
                    style: TextStyle(
                      fontSize: responsive.labelFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: spacing / 2),
                Flexible(
                  child: AppText.body(
                    staff.roomName,
                    style: TextStyle(
                      fontSize: responsive.isTablet ? 16 : 15,
                      color: AppColors.themeColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            if (widget.isExpanded) ...[
              SizedBox(height: responsive.verticalSpacing / 2),
              Divider(height: 1, color: AppColors.cardBorderColor),
              SizedBox(height: responsive.verticalSpacing / 2),
              _buildDetailRow(context, responsive, 'Room', staff.roomName),
              SizedBox(height: responsive.isTablet ? 8 : 6),
              _buildDetailRow(context, responsive, 'Absent Time', staff.absentTime),
              if (staff.absentBy.isNotEmpty && staff.absentBy != 'Unknown') ...[
                SizedBox(height: responsive.isTablet ? 8 : 6),
                _buildDetailRow(context, responsive, 'Marked by', staff.absentBy),
              ],
              if (staff.note != null && staff.note!.isNotEmpty) ...[
                SizedBox(height: responsive.isTablet ? 8 : 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: responsive.isTablet ? 2 : 1,
                      child: AppText.small(
                        'Note',
                        style: TextStyle(
                          fontSize: responsive.isTablet ? 14 : 12,
                          color: AppColors.secondaryColor.withOpacity(0.6),
                        ),
                      ),
                    ),
                    SizedBox(width: responsive.horizontalSpacing / 2),
                    Expanded(
                      flex: responsive.isTablet ? 3 : 2,
                      child: AppText.value(
                        staff.note!,
                        style: TextStyle(
                          fontSize: responsive.isTablet ? 16 : 14,
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: responsive.isTablet ? 8 : 6),
              _buildDetailRow(
                context,
                responsive,
                'Start Date',
                staff.startDate.isNotEmpty
                    ? staff.startDate.split('T')[0]
                    : 'N/A',
              ),
              SizedBox(height: responsive.isTablet ? 8 : 6),
              _buildDetailRow(
                context,
                responsive,
                'End Date',
                staff.endDate.isNotEmpty
                    ? staff.endDate.split('T')[0]
                    : 'N/A',
              ),
              SizedBox(height: responsive.verticalSpacing / 2),
              if (widget.onView != null)
                SizedBox(
                  width: double.infinity,
                  height: responsive.buttonHeight * 0.8,
                  child: OutlinedButton(
                    onPressed: widget.onView,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.themeColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: AppColors.cardColor,
                    ),
                    child: AppText.body(
                      "View",
                      style: TextStyle(
                        fontSize: responsive.isTablet ? 16 : 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.themeColor,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, ResponsiveHelper responsive, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: responsive.isTablet ? 2 : 1,
          child: AppText.small(
            label,
            style: TextStyle(
              fontSize: responsive.isTablet ? 14 : 12,
              color: AppColors.secondaryColor.withOpacity(0.6),
            ),
          ),
        ),
        SizedBox(width: responsive.horizontalSpacing / 2),
        Expanded(
          flex: responsive.isTablet ? 3 : 2,
          child: AppText.value(
            value,
            style: TextStyle(
              fontSize: responsive.isTablet ? 16 : 14,
            ),
            textAlign: TextAlign.end,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
