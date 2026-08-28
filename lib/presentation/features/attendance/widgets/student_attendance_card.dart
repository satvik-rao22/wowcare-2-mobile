import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/app/theme/dimensions.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

class StudentAttendanceCard extends StatefulWidget {
  const StudentAttendanceCard({
    super.key,
    required this.date,
    required this.signIn,
    required this.signOut,
    required this.roomName,
    required this.signInBy,
    required this.signOutBy,
    this.onDelete,
    this.onEdit,
  });

  final DateTime date;
  final String signIn;
  final String signOut;
  final String roomName;
  final String signInBy;
  final String signOutBy;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  @override
  State<StudentAttendanceCard> createState() => _StudentAttendanceCardState();
}

class _StudentAttendanceCardState extends State<StudentAttendanceCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        return IntrinsicHeight(
          child: Container(
            width: constraints.maxWidth,
            height: isExpanded ? null : 64.0,
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: AppRadius.allMd,
              border: Border.all(
                color: AppColors.cardBorderColor,
                width: AppDimensions.hairline,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: AppColors.transparentColor,
              child: InkWell(
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                child: Column(
                  children: [
                    // Header with date and attended time (always visible)
                    Container(
                      height: 60,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? AppSpacing.xl : AppSpacing.md,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMM dd, yyyy').format(widget.date),
                            style: AppTextStyles.value,
                          ),
                          Text(
                            _calculateAttendedTime(widget.signIn, widget.signOut),
                            style: AppTextStyles.value,
                          ),
                        ],
                      ),
                    ),
                    
                    // Expandable details section
                    if (isExpanded) ...[
                      // Divider
                      const Divider(
                        height: 1,
                        thickness: AppDimensions.hairline,
                        indent: AppSpacing.md,
                        endIndent: AppSpacing.md,
                        color: AppColors.attendanceCardDividerColor,
                      ),

                      // Details section
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          children: [
                            _buildDetailRow('Classroom', widget.roomName),
                            const SizedBox(height: AppSpacing.sm),
                            _buildDetailRow('Sign In', _formatTime(widget.signIn)),
                            const SizedBox(height: AppSpacing.sm),
                            _buildDetailRow('Sign In By', _firstName(widget.signInBy)),
                            const SizedBox(height: AppSpacing.sm),
                            _buildDetailRow('Sign Out', _formatTime(widget.signOut)),
                            const SizedBox(height: AppSpacing.sm),
                            _buildDetailRow('Sign Out By', _firstName(widget.signOutBy)),
                            const SizedBox(height: AppSpacing.md),
                            
                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: OutlinedButton(
                                      onPressed: widget.onDelete,
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: AppColors
                                              .attendanceActionAccentColor,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: AppRadius.allSm,
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Text(
                                        'Delete',
                                        style: AppTextStyles.title.copyWith(
                                          color: AppColors
                                              .attendanceActionAccentColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: AppRadius.allSm,
                                      gradient: AppColors.buildPrimaryGradient(),
                                    ),
                                    child: TextButton(
                                      onPressed: widget.onEdit,
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Text(
                                        'Edit',
                                        style: AppTextStyles.title.copyWith(
                                          color: AppColors.cardColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTextStyles.label,
        ),
        Text(
          value,
          style: AppTextStyles.value,
        ),
      ],
    );
  }

  String _formatTime(String time) {
    if (time.isEmpty) return 'Not Yet Signed Out';
    return DateFormat('hh:mm a').format(DateFormat('hh:mm:ss a').parse(time));
  }

  String _calculateAttendedTime(String signInTime, String signOutTime) {
    if (signInTime.isEmpty || signOutTime.isEmpty) return 'Not Yet Signed Out';
    final format = DateFormat('hh:mm:ss a');
    final signIn = format.parse(signInTime);
    final signOut = format.parse(signOutTime);
    final duration = signOut.difference(signIn);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours < 1) return '$minutes minutes';
    return '$hours hours $minutes minutes';
  }

  String _firstName(String name) {
    if (name == 'System Auto Signout') return name;
    return name.split(' ').first;
  }
}