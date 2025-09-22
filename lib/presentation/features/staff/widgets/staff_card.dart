import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';

class StaffCard extends StatefulWidget {
  const StaffCard({
    super.key,
    required this.name,
    required this.classroom,
    this.avatarUrl,
    required this.allowedClassrooms,
    required this.schedule,
    required this.designation,
    required this.phoneNumber,
    this.onDeactivate,
    this.onEdit,
    this.isSelected = false,
    this.onSelected,
  });

  final String name;
  final String classroom;
  final String? avatarUrl;
  final List<String> allowedClassrooms;
  final List<String> schedule;
  final String designation;
  final String phoneNumber;
  final VoidCallback? onDeactivate;
  final VoidCallback? onEdit;
  final bool isSelected;
  final ValueChanged<bool?>? onSelected;

  @override
  State<StaffCard> createState() => _StaffCardState();
}

class _StaffCardState extends State<StaffCard> {
  bool isExpanded = false;

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(' ');
    if (parts.length == 1) {
      final firstLetter = parts[0].isNotEmpty ? parts[0][0] : '';
      return (firstLetter + firstLetter).toUpperCase();
    } else {
      String first = parts[0].isNotEmpty ? parts[0][0] : '';
      String second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
      return (first + second).toUpperCase();
    }
  }

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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.cardBorderColor,
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (!isExpanded)
                            CustomCheckbox(
                              value: widget.isSelected,
                              onChanged: widget.onSelected ?? (_) {},
                              scale: 1.2,
                              borderColor: null,
                              label: null,
                            ),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF80A3DC),
                              image: (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(widget.avatarUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: (widget.avatarUrl == null || widget.avatarUrl!.isEmpty)
                                ? Text(
                                    _getInitials(widget.name),
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      height: 16 / 12,
                                    ),
                                  )
                                : null,
                          ),
                          SizedBox(width: isTablet ? 16 : 9),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.name,
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xff573353),
                                      height: 19 / 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    widget.classroom,
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xff573353),
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
                    ),
                    if (isExpanded) ...[
                      const Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFFE9ECEF),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Allowed\nClassroom',
                                  style: TextStyle(
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
                                    child: Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        if (widget.allowedClassrooms.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0x4DB1AFE9),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              widget.allowedClassrooms[0],
                                              style: const TextStyle(
                                                fontFamily: 'Manrope',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: Color(0xFF4B5B7A),
                                              ),
                                            ),
                                          ),
                                        if (widget.allowedClassrooms.length > 1)
                                          Tooltip(
                                            message: widget.allowedClassrooms.skip(1).join(', '),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0x66D9FFCB),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '+${widget.allowedClassrooms.length - 1}',
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                  color: Color(0xFF1B237E),
                                                  height: 15 / 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Schedule',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff573353),
                                    height: 16 / 13,
                                  ),
                                ),
                                Expanded(
                                  child: Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    alignment: WrapAlignment.end,
                                    children: [
                                      ...['Mon', 'Tue', 'Wed', 'Thu', 'Fri'].map((day) {
                                        final isActive = widget.schedule.contains(day);
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? const Color(0xFF6C7FD8).withOpacity(0.12)
                                                : const Color(0xFFF3F4FB),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            day,
                                            style: TextStyle(
                                              fontFamily: 'Manrope',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: isActive
                                                  ? const Color(0xFF6C7FD8)
                                                  : const Color(0xFFB1AFC9),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Designation',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff573353),
                                    height: 16 / 13,
                                  ),
                                ),
                                Text(
                                  widget.designation,
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff573353),
                                    height: 19 / 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Phone Number',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff573353),
                                    height: 16 / 13,
                                  ),
                                ),
                                Text(
                                  _formatUsPhone(widget.phoneNumber),
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff573353),
                                    height: 19 / 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: OutlinedButton(
                                      onPressed: widget.onDeactivate,
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFF6C7FD8)),
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
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      gradient: AppColors.buildPrimaryGradient(),
                                    ),
                                    child: TextButton(
                                      onPressed: widget.onEdit,
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                      ),
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

  String _formatUsPhone(String input) {
    // Keep digits only
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return input;
    final area = digits.substring(0, 3);
    final mid = digits.substring(3, 6);
    final last = digits.substring(6, 10);
    return '($area) $mid-$last';
  }
}


