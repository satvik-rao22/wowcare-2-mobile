import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';

/// Collapsible staff attendance card used in the staff Daily tab.
///
/// This mirrors the visual layout of the legacy
/// `staff_attendance_daily_view` card, but is implemented as a
/// reusable widget in the new UI architecture.
class StaffAttendanceCard extends StatefulWidget {
  const StaffAttendanceCard({
    super.key,
    required this.name,
    required this.designation,
    required this.classroom,
    this.photoUuid,
    required this.expectedToday,
    required this.signInText,
    required this.signOutText,
    required this.attendedDuration,
    this.isPresentDot = false,
    this.isAbsentDot = false,
    this.isAbsentMode = false,
    this.isCustomMode = false,
    this.headerSubtitle,
    this.roomLabel,
    this.absentTime,
    this.startDate,
    this.endDate,
    this.markedBy,
    this.onViewPressed,
    this.onEdit,
    this.onDelete,
  });

  final String name;
  final String designation;
  final String classroom;
  final String? photoUuid;

  final bool expectedToday;
  final String signInText;
  final String signOutText;
  final String attendedDuration;

  /// When true, shows a small green dot on the avatar.
  final bool isPresentDot;

  /// When true, shows a small red dot on the avatar.
  final bool isAbsentDot;

  /// When true, the expanded section shows absent-specific
  /// fields (Room, Absent Time, Start/End Date, View button).
  final bool isAbsentMode;

  /// When true, the expanded section shows custom tab
  /// fields (Classroom, Attended Time, single View button).
  final bool isCustomMode;

  /// Optional header subtitle shown on the right side
  /// of the header row (e.g. "Attended Days: 1" or "Absent: 1 days").
  final String? headerSubtitle;

  /// Absent-mode fields (optional for normal mode).
  final String? roomLabel;
  final String? absentTime;
  final String? startDate;
  final String? endDate;
  final String? markedBy;
  final VoidCallback? onViewPressed;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<StaffAttendanceCard> createState() => _StaffAttendanceCardState();
}

class _StaffAttendanceCardState extends State<StaffAttendanceCard> {
  // Expanded by default so details and buttons are visible.
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final Color? statusColor = widget.isPresentDot
        ? const Color.fromRGBO(0, 177, 21, 1)
        : widget.isAbsentDot
            ? const Color.fromRGBO(200, 32, 32, 1)
            : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cardBorderColor,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Column(
          children: [
            Row(
              children: [
                DocumentImageWidget(
                  fileUuid: widget.photoUuid ?? '',
                  name: widget.name,
                  size: 50,
                  fontSize: 16,
                  statusColor: statusColor,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          widget.name,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff573353),
                            height: 19 / 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.headerSubtitle ?? widget.classroom,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff573353),
                            height: 19 / 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE5E9F2)),
              const SizedBox(height: 10),
              if (widget.isCustomMode) ...[
                _InfoRow(
                  label: 'Classroom',
                  value: widget.classroom,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  label: 'Attended Time',
                  value: widget.attendedDuration,
                ),
                const SizedBox(height: 16),
                CustomButtonLayout(
                  confirmButtonLabel: 'View',
                  onPressedConfirm: widget.onViewPressed,
                  showCancelButton: false,
                  isForm: false,
                ),
              ] else if (widget.isAbsentMode) ...[
                _InfoRow(
                  label: 'Classroom',
                  value: widget.roomLabel ?? widget.classroom,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  label: 'Absent Date',
                  value: widget.startDate ?? '-',
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  label: 'Absent Time',
                  value: widget.absentTime ?? '-',
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  label: 'Marked By',
                  value: widget.markedBy ?? '-',
                ),
                const SizedBox(height: 16),
                // Absent/custom modes: only View button using common layout
                CustomButtonLayout(
                  confirmButtonLabel: 'View',
                  onPressedConfirm: widget.onViewPressed,
                  showCancelButton: false,
                  isForm: false,
                ),
              ] else ...[
                _InfoRow(
                  label: 'Expected Today?',
                  value: widget.expectedToday ? 'Yes' : 'No',
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  label: 'Classroom',
                  value: widget.classroom,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  label: 'Sign In time & by',
                  value: widget.signInText,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  label: 'Sign Out time & by',
                  value: widget.signOutText,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  label: 'Attended Time',
                  value: widget.attendedDuration,
                ),
                const SizedBox(height: 16),
                // Normal mode actions: Delete, Edit, View on the same line.
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: widget.onDelete,
                          style: OutlinedButton.styleFrom(
                            side:
                                const BorderSide(color: Color(0xFF6C7FD8)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6C7FD8),
                              height: 16 / 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: AppColors.buildPrimaryGradient(),
                        ),
                        child: TextButton(
                          onPressed: widget.onEdit,
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 16 / 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: widget.onViewPressed,
                          style: OutlinedButton.styleFrom(
                            side:
                                const BorderSide(color: Color(0xFF6C7FD8)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'View',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6C7FD8),
                              height: 16 / 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xff573353),
            height: 16 / 13,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xff573353),
                height: 19 / 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

