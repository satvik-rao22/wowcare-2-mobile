import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

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

  @override
  State<StaffAttendanceCard> createState() => _StaffAttendanceCardState();
}

class _StaffAttendanceCardState extends State<StaffAttendanceCard> {
  bool _isExpanded = false;

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
                          widget.classroom,
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
              _InfoRow(
                label: 'Expected Today?',
                value: widget.expectedToday ? 'Yes' : 'No',
              ),
              const SizedBox(height: 6),
              _InfoRow(
                label: 'Classroom',
                value: widget.classroom,
              ),
              const SizedBox(height: 6),
              _InfoRow(
                label: 'Sign In time & by',
                value: widget.signInText,
              ),
              const SizedBox(height: 6),
              _InfoRow(
                label: 'Sign Out time & by',
                value: widget.signOutText,
              ),
              const SizedBox(height: 6),
              _InfoRow(
                label: 'Attended Time',
                value: widget.attendedDuration,
              ),
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
      children: [
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xff573353),
              height: 16 / 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
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
      ],
    );
  }
}

